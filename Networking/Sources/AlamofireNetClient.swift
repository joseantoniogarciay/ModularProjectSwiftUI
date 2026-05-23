import Alamofire
import Core
import Foundation

public struct AlamofireNetClient: NetClient {
    private let session: Session

    public init(userAgent: String, requestTimeout: TimeInterval = 20) {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = requestTimeout
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.httpAdditionalHeaders = [
            "User-Agent": userAgent,
            HTTPHeader.defaultAcceptEncoding.name: HTTPHeader.defaultAcceptEncoding.value,
            HTTPHeader.defaultAcceptLanguage.name: HTTPHeader.defaultAcceptLanguage.value,
            "Accept": "application/json",
        ]
        self.session = Session(
            configuration: configuration,
            delegate: SessionDelegate(),
            rootQueue: DispatchQueue(label: "net.alamofire.rootQueue"),
            requestQueue: DispatchQueue(label: "net.alamofire.requestQueue"),
            serializationQueue: DispatchQueue(label: "net.alamofire.serializationQueue")
        )
    }

    public func request(_ request: NetRequest) async throws -> NetResponse {
        let dataRequest = try makeDataRequest(request)
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (cont: CheckedContinuation<NetResponse, any Error>) in
                dataRequest.validate().response(queue: .global()) { response in
                    switch response.result {
                    case .success(let data):
                        cont.resume(returning: NetResponse(
                            statusCode: response.response?.statusCode ?? -1,
                            data: data,
                            headers: response.request?.allHTTPHeaderFields
                        ))
                    case .failure(let error):
                        cont.resume(throwing: Self.map(error, response: response))
                    }
                }
                dataRequest.resume()
            }
        } onCancel: { dataRequest.cancel() }
    }

    public func request<T: Decodable & Sendable>(_ request: NetRequest) async throws -> T {
        let dataRequest = try makeDataRequest(request)
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (cont: CheckedContinuation<T, any Error>) in
                dataRequest
                    .validate()
                    .response(queue: .global(), responseSerializer: DecodableSerializer<T>()) { response in
                        switch response.result {
                        case .success(let value): cont.resume(returning: value)
                        case .failure(let error): cont.resume(throwing: Self.map(error, response: response))
                        }
                    }
                dataRequest.resume()
            }
        } onCancel: { dataRequest.cancel() }
    }

    public func upload(
        _ request: NetRequest,
        archives: [FormData],
        jsonKey: String,
        progress: (@Sendable (Double) -> Void)?
    ) async throws -> NetResponse {
        guard let url = URL(string: request.url) else { throw NetError.invalidURL }
        let urlRequest: URLRequest
        do {
            urlRequest = try URLRequest(url: url, method: Self.transform(request.method), headers: HTTPHeaders(request.headers))
        } catch { throw NetError.encoding(error) }

        let jsonPart: Data?
        do {
            jsonPart = try request.body.flatMap { try Self.bodyAsData($0) }
        } catch { throw NetError.encoding(error) }

        let uploadRequest = session.upload(multipartFormData: { form in
            for archive in archives {
                form.append(archive.data, withName: archive.apiName, fileName: archive.fileName, mimeType: archive.mimeType)
            }
            if let jsonPart { form.append(jsonPart, withName: jsonKey, mimeType: "application/json") }
        }, with: urlRequest)

        if let progress { uploadRequest.uploadProgress { p in progress(p.fractionCompleted) } }

        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (cont: CheckedContinuation<NetResponse, any Error>) in
                uploadRequest.validate().response(queue: .global()) { response in
                    switch response.result {
                    case .success(let data):
                        cont.resume(returning: NetResponse(statusCode: response.response?.statusCode ?? -1, data: data, headers: response.request?.allHTTPHeaderFields))
                    case .failure(let error):
                        cont.resume(throwing: Self.map(error, response: response))
                    }
                }
                uploadRequest.resume()
            }
        } onCancel: { uploadRequest.cancel() }
    }

    public func cancelAllTasks() {
        session.cancelAllRequests()
    }

    // MARK: - Private

    private func makeDataRequest(_ request: NetRequest) throws -> DataRequest {
        guard let baseURL = URL(string: request.url) else { throw NetError.invalidURL }
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
        if !request.queryItems.isEmpty {
            let existing = components?.queryItems ?? []
            components?.queryItems = existing + request.queryItems
        }
        guard let url = components?.url else { throw NetError.invalidURL }

        var urlRequest: URLRequest
        do {
            urlRequest = try URLRequest(url: url, method: Self.transform(request.method), headers: HTTPHeaders(request.headers))
        } catch { throw NetError.encoding(error) }

        if let body = request.body {
            do { try Self.apply(body, to: &urlRequest) } catch { throw NetError.encoding(error) }
        }
        return session.request(urlRequest)
    }

    private static func apply(_ body: Body, to urlRequest: inout URLRequest) throws {
        switch body {
        case .json(let encodable):
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.httpBody = try JSONEncoder().encode(encodable)
        case .form(let params):
            urlRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            urlRequest.httpBody = urlEncoded(params).data(using: .utf8)
        case .raw(let data, let mimeType):
            urlRequest.setValue(mimeType, forHTTPHeaderField: "Content-Type")
            urlRequest.httpBody = data
        }
    }

    private static func bodyAsData(_ body: Body) throws -> Data {
        switch body {
        case .json(let encodable): return try JSONEncoder().encode(encodable)
        case .form(let params): return urlEncoded(params).data(using: .utf8) ?? Data()
        case .raw(let data, _): return data
        }
    }

    private static func urlEncoded(_ params: [String: String]) -> String {
        params.sorted { $0.key < $1.key }.map { k, v in
            let allowed = CharacterSet.urlQueryAllowed
            return "\(k.addingPercentEncoding(withAllowedCharacters: allowed) ?? k)=\(v.addingPercentEncoding(withAllowedCharacters: allowed) ?? v)"
        }.joined(separator: "&")
    }

    private static func transform(_ method: Core.HTTPMethod) -> Alamofire.HTTPMethod {
        Alamofire.HTTPMethod(rawValue: method.rawValue.uppercased())
    }

    private static func map<S: Sendable>(_ error: AFError, response: AFDataResponse<S>) -> any Error {
        if let urlError = error.underlyingError as? URLError {
            if urlError.code == .cancelled { return NetError.cancelled }
            if urlError.code == .notConnectedToInternet { return NetError.noConnection }
        }
        return NetError.http(statusCode: response.response?.statusCode ?? -1, data: response.data, headers: response.request?.allHTTPHeaderFields)
    }
}
