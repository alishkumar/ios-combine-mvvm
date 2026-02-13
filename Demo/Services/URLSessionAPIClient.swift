//
//  URLSessionAPIClient.swift
//  Demo
//
//  Created by Alish Kumar on 13/02/26.
//


import Foundation
import Combine

typealias JSONDictionary = [String: Any]

protocol APIClient {
    associatedtype EndpointType: ApiEndPointDelegate
    func request<T: Decodable>(_ endpoint: EndpointType, params: JSONDictionary?, strParam: String?) -> AnyPublisher<T, Error>
    func requestAsync<T: Decodable>(_ endpoint: EndpointType, params: JSONDictionary?, strParam: String?) async throws -> T
}
class URLSessionAPIClient<EndpointType: ApiEndPointDelegate>: APIClient {
    func request<T: Decodable>(_ endpoint: EndpointType, params: JSONDictionary? = nil, strParam: String? = nil) -> AnyPublisher<T, Error> {
        var endPath = endpoint.path
        if let strParam = strParam {
            endPath = endpoint.path + "/\(strParam)"
        }
        var urlComponents = URLComponents(url: endpoint.baseURL.appendingPathComponent(endPath), resolvingAgainstBaseURL: false)!
        
        if let newsEndpoint = endpoint as? NewsEndPoint {
            var queryItems: [URLQueryItem] = []
            for (key, value) in newsEndpoint.queryParameters {
                queryItems.append(URLQueryItem(name: key, value: value))
            }
            urlComponents.queryItems = queryItems
        }
        
        guard let url = urlComponents.url else {
            return Fail(error: APIError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        
        endpoint.headers?.forEach { request.addValue($0.value, forHTTPHeaderField: $0.key) }
        
        if let params = params {
            let jsonData = try? JSONSerialization.data(withJSONObject: params)
            request.httpBody = jsonData
        }
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .subscribe(on: DispatchQueue.global(qos: .background))
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.invalidResponse
                }
                
                switch httpResponse.statusCode {
                case 200...299:
                    return data
                case 401:
                    throw APIError.unauthorized
                case 429:
                    throw APIError.rateLimitExceeded
                case 500...599:
                    throw APIError.serverError
                default:
                    throw APIError.invalidResponse
                }
            }
            .retry(3)
            .catch { error -> AnyPublisher<Data, Error> in
                if !NetworkMonitor.shared.isConnected {
                    return Fail(error: APIError.noConnection)
                        .eraseToAnyPublisher()
                }
                return Fail(error: error)
                    .eraseToAnyPublisher()
            }
            .decode(type: T.self, decoder: JSONDecoder())
            .catch { error -> AnyPublisher<T, Error> in
                if let decodingError = error as? DecodingError {
                    return Fail(error: APIError.decodingFailed(decodingError))
                        .eraseToAnyPublisher()
                }
                return Fail(error: error)
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    func requestAsync<T: Decodable>(_ endpoint: EndpointType, params: JSONDictionary? = nil, strParam: String? = nil) async throws -> T {
        var endPath = endpoint.path
        if let strParam = strParam {
            endPath = endpoint.path + "/\(strParam)"
        }
        var urlComponents = URLComponents(url: endpoint.baseURL.appendingPathComponent(endPath), resolvingAgainstBaseURL: false)!
        
        if let newsEndpoint = endpoint as? NewsEndPoint {
            var queryItems: [URLQueryItem] = []
            for (key, value) in newsEndpoint.queryParameters {
                queryItems.append(URLQueryItem(name: key, value: value))
            }
            urlComponents.queryItems = queryItems
        }
        
        guard let url = urlComponents.url else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        
        endpoint.headers?.forEach { request.addValue($0.value, forHTTPHeaderField: $0.key) }
        
        if let params = params {
            let jsonData = try? JSONSerialization.data(withJSONObject: params)
            request.httpBody = jsonData
        }
        
        var attempt = 0
        var lastError: Error?
        
        while attempt < 3 {
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.invalidResponse
                }
                
                switch httpResponse.statusCode {
                case 200...299:
                    let decoder = JSONDecoder()
                    return try decoder.decode(T.self, from: data)
                case 401:
                    throw APIError.unauthorized
                case 429:
                    let strategy = ErrorRecoveryStrategy.retryStrategy(for: .rateLimitExceeded)
                    if strategy.shouldRetry(attempt: attempt) {
                        let delay = strategy.delay(for: attempt)
                        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                        attempt += 1
                        continue
                    }
                    throw APIError.rateLimitExceeded
                case 500...599:
                    let strategy = ErrorRecoveryStrategy.retryStrategy(for: .serverError)
                    if strategy.shouldRetry(attempt: attempt) {
                        let delay = strategy.delay(for: attempt)
                        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                        attempt += 1
                        continue
                    }
                    throw APIError.serverError
                default:
                    throw APIError.invalidResponse
                }
            } catch let error as APIError {
                if !NetworkMonitor.shared.isConnected {
                    throw APIError.noConnection
                }
                
                let strategy = ErrorRecoveryStrategy.retryStrategy(for: error)
                if strategy.shouldRetry(attempt: attempt) && ErrorRecoveryStrategy.isRetryable(error) {
                    let delay = strategy.delay(for: attempt)
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    attempt += 1
                    lastError = error
                    continue
                }
                throw error
            } catch let decodingError as DecodingError {
                throw APIError.decodingFailed(decodingError)
            } catch {
                if !NetworkMonitor.shared.isConnected {
                    throw APIError.noConnection
                }
                
                let strategy = ErrorRecoveryStrategy.retryStrategy(for: .invalidResponse)
                if strategy.shouldRetry(attempt: attempt) {
                    let delay = strategy.delay(for: attempt)
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    attempt += 1
                    lastError = error
                    continue
                }
                throw APIError.requestFailed(error)
            }
        }
        
        throw lastError ?? APIError.invalidResponse
    }
}
extension Encodable {
    subscript(key: String) -> Any? {
        return dictionary[key]
    }
    var dictionary: [String: Any] {
        return (try? JSONSerialization.jsonObject(with: JSONEncoder().encode(self))) as? [String: Any] ?? [:]
    }
}
