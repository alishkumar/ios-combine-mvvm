//
//  APIEndpoint.swift
//  Demo
//
//  Created by Alish Kumar on 13/02/26.
//


import Foundation

protocol ApiEndPointDelegate {
    var baseURL: URL { get }
    var headers: [String: String]? { get }
    var path: String { get }
    var method: HTTPMethod { get }
}
enum AppEndPoint: ApiEndPointDelegate {
    var baseURL: URL {
        return URL(string: "https://propertyindubai.io/")!
    }
    var headers: [String: String]? {
        return [
            "Content-Type": "application/json",
            "platform": "iOS",
            "appVersion": Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String,
            "language": "en"
        ]
    }
    // Reservation
    case getProperty, createReservation, getSlots
    var path: String {
        switch self {
        case .getProperty:
            return "/api/v1/vehicle/get/all/types"
        case .createReservation:
            return "/api/v1/reservation/create/booking"
        case .getSlots:
            return "/api/v1/reservation/get/availability"
        }
    }
    var method: HTTPMethod {
        switch self {
        case .getProperty:
            return .get
        case .createReservation:
            return .post
        case .getSlots:
            return .post
        }
    }
}

public enum APIError: Error {
    case invalidURL
    case invalidResponse
    case invalidData
    case requestFailed(Error)
    case decodingFailed(Error)
    case unauthorized
    case rateLimitExceeded
    case serverError
    case noConnection
    
    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .invalidData:
            return "Invalid data received"
        case .requestFailed(let error):
            return "Request failed: \(error.localizedDescription)"
        case .decodingFailed(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .unauthorized:
            return "Unauthorized access"
        case .rateLimitExceeded:
            return "Rate limit exceeded. Please try again later."
        case .serverError:
            return "Server error. Please try again later."
        case .noConnection:
            return "No internet connection"
        }
    }
}

public enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}
