import Foundation
import XCTest
@testable import Core

final class JWTExpiryTests: XCTestCase {

    // MARK: - Helper

    /// Builds a syntactically valid JWT with the given JSON payload string.
    /// Uses a hardcoded header and a fake signature — only the payload is decoded by JWTExpiry.
    private func makeJWT(payload: String) -> String {
        // Fixed header: {"alg":"HS256","typ":"JWT"} base64url-encoded (no padding)
        let header = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9"
        let payloadEncoded = Data(payload.utf8)
            .base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        return "\(header).\(payloadEncoded).fake_signature"
    }

    // MARK: - Valid tokens

    func testValidToken_withFutureExpiry_returnsExpectedDate() {
        let exp = 9_999_999_999.0
        let token = makeJWT(payload: "{\"exp\": \(exp)}")

        let result = JWTExpiry.expirationDate(of: token)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.timeIntervalSince1970 ?? 0, exp, accuracy: 1.0)
    }

    func testValidToken_withPastExpiry_returnsExpectedDate() {
        let exp = 1_000_000.0
        let token = makeJWT(payload: "{\"exp\": \(exp)}")

        let result = JWTExpiry.expirationDate(of: token)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.timeIntervalSince1970 ?? 0, exp, accuracy: 1.0)
    }

    func testValidToken_withExtraClaims_returnsExpiry() {
        // Extra claims must not prevent exp from being parsed.
        let token = makeJWT(payload: "{\"sub\":\"u1\",\"exp\":2000000000.0,\"iss\":\"test\"}")
        let result = JWTExpiry.expirationDate(of: token)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.timeIntervalSince1970 ?? 0, 2_000_000_000.0, accuracy: 1.0)
    }

    // MARK: - Malformed structure

    func testMalformedToken_twoSegments_returnsNil() {
        // JWTExpiry.expirationDate guards segments.count >= 2, so "header.payload"
        // passes that guard. It returns nil because the second segment ("payload")
        // is not valid base64url — decodeBase64URL returns nil downstream.
        XCTAssertNil(
            JWTExpiry.expirationDate(of: "header.payload"),
            "A 2-segment token whose payload is not valid base64url must return nil"
        )
    }

    func testMalformedToken_singleSegment_returnsNil() {
        XCTAssertNil(JWTExpiry.expirationDate(of: "onlyone"))
    }

    func testMalformedToken_emptyString_returnsNil() {
        XCTAssertNil(JWTExpiry.expirationDate(of: ""))
    }

    // MARK: - Invalid payload

    func testInvalidPayload_notJSON_returnsNil() {
        let raw = Data("not json at all".utf8)
            .base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        let token = "header.\(raw).sig"
        XCTAssertNil(JWTExpiry.expirationDate(of: token))
    }

    func testInvalidPayload_missingExpClaim_returnsNil() {
        let token = makeJWT(payload: "{\"sub\": \"user123\"}")
        XCTAssertNil(
            JWTExpiry.expirationDate(of: token),
            "A payload without 'exp' must return nil"
        )
    }

    func testInvalidPayload_expIsString_returnsNil() {
        let token = makeJWT(payload: "{\"exp\": \"not-a-number\"}")
        XCTAssertNil(
            JWTExpiry.expirationDate(of: token),
            "'exp' must be a numeric type — a String must return nil"
        )
    }

    // MARK: - Base64URL padding variants
    //
    // JWTExpiry.decodeBase64URL adds '=' padding based on (length % 4).
    // We craft payloads whose UTF-8 byte count produces each non-trivial remainder
    // after base64url stripping, so every padding branch is exercised.
    //
    // Remainder → bytes needed:
    //   0 (no padding):  N % 3 == 0  → use {"exp":9999}   = 12 bytes ✓
    //   2 (two =):       N % 3 == 1  → use {"exp":11}     = 10 bytes ✓
    //   3 (one =):       N % 3 == 2  → use {"exp":0.1}    = 11 bytes ✓
    //   1 (impossible with valid data — base64 alphabet property)

    func testBase64Padding_noRemainder_decodesCorrectly() {
        // {"exp":9999} = 12 bytes → 16 base64url chars → 16 % 4 == 0 (no padding needed)
        let token = makeJWT(payload: "{\"exp\":9999}")
        let result = JWTExpiry.expirationDate(of: token)
        XCTAssertNotNil(result, "12-byte payload (no padding needed) must decode correctly")
        XCTAssertEqual(result?.timeIntervalSince1970 ?? 0, 9999, accuracy: 1.0)
    }

    func testBase64Padding_remainderTwo_decodesCorrectly() {
        // {"exp":11} = 10 bytes → 14 base64url chars (stripped) → 14 % 4 == 2 (needs "==")
        let token = makeJWT(payload: "{\"exp\":11}")
        let result = JWTExpiry.expirationDate(of: token)
        XCTAssertNotNil(result, "10-byte payload (remainder 2, needs == padding) must decode correctly")
        XCTAssertEqual(result?.timeIntervalSince1970 ?? 0, 11, accuracy: 1.0)
    }

    func testBase64Padding_remainderThree_decodesCorrectly() {
        // {"exp":0.1} = 11 bytes → 15 base64url chars (stripped) → 15 % 4 == 3 (needs "=")
        let token = makeJWT(payload: "{\"exp\":0.1}")
        let result = JWTExpiry.expirationDate(of: token)
        XCTAssertNotNil(result, "11-byte payload (remainder 3, needs = padding) must decode correctly")
        XCTAssertEqual(result?.timeIntervalSince1970 ?? 0, 0.1, accuracy: 0.001)
    }
}
