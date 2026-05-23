import Foundation

public enum HTTPMethod: String, Sendable {
    case get, post, put, delete, head, options, trace, patch, connect
}

public enum Body: Sendable {
    case json(any Encodable & Sendable)
    case form([String: String])
    case raw(Data, mimeType: String)
}

public struct NetRequest: Sendable {
    public let url: String
    public let method: HTTPMethod
    public let headers: [String: String]
    public let queryItems: [URLQueryItem]
    public let body: Body?
    public let shouldCache: Bool

    private init(builder: Builder) {
        self.url = builder.url
        self.method = builder.method
        self.headers = builder.headers
        self.queryItems = builder.queryItems
        self.body = builder.body
        self.shouldCache = builder.shouldCache
    }

    public final class Builder {
        public var url: String = ""
        public var method: HTTPMethod = .get
        public var headers: [String: String] = [:]
        public var queryItems: [URLQueryItem] = []
        public var body: Body?
        public var shouldCache: Bool = true

        public init() {}

        @discardableResult public func url(_ url: String) -> Self { self.url = url; return self }
        @discardableResult public func method(_ method: HTTPMethod) -> Self { self.method = method; return self }
        @discardableResult public func header(name: String, value: String) -> Self { headers[name] = value; return self }
        @discardableResult public func queryItem(name: String, value: String?) -> Self {
            queryItems.append(URLQueryItem(name: name, value: value)); return self
        }
        @discardableResult public func body(_ body: Body?) -> Self { self.body = body; return self }

        public func build() -> NetRequest { NetRequest(builder: self) }
    }
}
