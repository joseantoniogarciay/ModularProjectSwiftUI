import Foundation
import XCTest
@testable import Core

// MARK: - Test model

private struct Item: Decodable {
    let id: Int
}

// MARK: - FailableDecodable tests

final class FailableDecodableTests: XCTestCase {

    func testValidJSON_decodesBase() throws {
        let data = Data(#"{"id": 42}"#.utf8)
        let result = try JSONDecoder().decode(FailableDecodable<Item>.self, from: data)
        XCTAssertEqual(result.base?.id, 42)
    }

    func testInvalidJSON_baseIsNilAndDoesNotThrow() throws {
        // "id" is required (Int). "not_id" → keyNotFound → FailableDecodable silently yields nil.
        let data = Data(#"{"not_id": "x"}"#.utf8)
        let result = try JSONDecoder().decode(FailableDecodable<Item>.self, from: data)
        XCTAssertNil(result.base, "A missing required key must produce nil base, not a throw")
    }
}

// MARK: - FailableDecodableArray tests

final class FailableDecodableArrayTests: XCTestCase {

    func testAllValid_decodesAllElements() throws {
        let json = #"[{"id": 1}, {"id": 2}, {"id": 3}]"#
        let result = try JSONDecoder().decode(
            FailableDecodableArray<Item>.self, from: Data(json.utf8)
        )
        XCTAssertEqual(result.elements.map(\.id), [1, 2, 3])
    }

    func testMixedElements_skipsInvalidAndKeepsValid() throws {
        let json = #"[{"id": 1}, {"wrong": "x"}, {"id": 3}]"#
        let result = try JSONDecoder().decode(
            FailableDecodableArray<Item>.self, from: Data(json.utf8)
        )
        XCTAssertEqual(
            result.elements.map(\.id), [1, 3],
            "Invalid element must be silently skipped"
        )
    }

    func testAllInvalid_returnsEmptyArray() throws {
        let json = #"[{"wrong": "a"}, {"wrong": "b"}]"#
        let result = try JSONDecoder().decode(
            FailableDecodableArray<Item>.self, from: Data(json.utf8)
        )
        XCTAssertTrue(result.elements.isEmpty)
    }

    func testEmptyArray_returnsEmptyElements() throws {
        let result = try JSONDecoder().decode(
            FailableDecodableArray<Item>.self, from: Data("[]".utf8)
        )
        XCTAssertTrue(result.elements.isEmpty)
    }

    func testSingleValidElement_decodesCorrectly() throws {
        let json = #"[{"id": 99}]"#
        let result = try JSONDecoder().decode(
            FailableDecodableArray<Item>.self, from: Data(json.utf8)
        )
        XCTAssertEqual(result.elements.count, 1)
        XCTAssertEqual(result.elements.first?.id, 99)
    }
}
