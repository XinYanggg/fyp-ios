//
//  APIClient.swift
//  durian.health
//
//  Talks to the fyp-website Next.js backend. Authenticated requests send
//  "Authorization: Bearer <token>", the same scheme the Android app uses.
//

import Foundation

nonisolated enum APIError: LocalizedError {
    /// 401 from the server: the token is missing, expired or invalid.
    case unauthorized
    /// Any other non-2xx response. `message` comes from the server's `error`/`message` field.
    case server(status: Int, message: String)
    case network
    case decoding

    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "Your session has expired. Please sign in again."
        case .server(_, let message):
            return message
        case .network:
            return "Cannot connect to the server. Please check your internet connection and try again."
        case .decoding:
            return "Unexpected response from the server."
        }
    }
}

final class APIClient {
    static let shared = APIClient()

    var baseURL: URL
    /// Set by the auth layer after login / session restore.
    var token: String?

    private let session: URLSession
    private let decoder = JSONDecoder()

    init(baseURL: URL = AppConfig.apiBaseURL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    // MARK: - Public request helpers

    /// JSON request. Pass an `Encodable` body for POST requests.
    func send<Response: Decodable>(
        _ path: String,
        method: String = "GET",
        body: (any Encodable)? = nil,
        as type: Response.Type = Response.self
    ) async throws -> Response {
        var request = makeRequest(path, method: method)
        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(body)
        }
        return try await perform(request)
    }

    /// Multipart upload with a single file part.
    func upload<Response: Decodable>(
        _ path: String,
        fieldName: String,
        fileName: String,
        mimeType: String,
        data: Data,
        as type: Response.Type = Response.self
    ) async throws -> Response {
        let boundary = "Boundary-\(UUID().uuidString)"
        var request = makeRequest(path, method: "POST")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(fileName)\"\r\n")
        body.append("Content-Type: \(mimeType)\r\n\r\n")
        body.append(data)
        body.append("\r\n--\(boundary)--\r\n")
        request.httpBody = body

        return try await perform(request)
    }

    // MARK: - Internals

    private func makeRequest(_ path: String, method: String) -> URLRequest {
        let normalized = path.hasPrefix("/") ? String(path.dropFirst()) : path
        var request = URLRequest(url: baseURL.appending(path: normalized))
        request.httpMethod = method
        request.timeoutInterval = 60
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return request
    }

    private func perform<Response: Decodable>(_ request: URLRequest) async throws -> Response {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError where error.code != .cancelled {
            throw APIError.network
        }

        guard let http = response as? HTTPURLResponse else { throw APIError.network }

        guard (200..<300).contains(http.statusCode) else {
            if http.statusCode == 401 && token != nil { throw APIError.unauthorized }
            throw APIError.server(status: http.statusCode, message: Self.errorMessage(from: data, status: http.statusCode))
        }

        do {
            return try decoder.decode(Response.self, from: data)
        } catch {
            throw APIError.decoding
        }
    }

    /// The backend replies with `{ "error": "..." }` or `{ "message": "..." }`.
    private static func errorMessage(from data: Data, status: Int) -> String {
        if let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let message = (object["error"] as? String) ?? (object["message"] as? String) {
            return message
        }
        return "Request failed with status \(status)."
    }
}

private extension Data {
    mutating func append(_ string: String) {
        append(Data(string.utf8))
    }
}
