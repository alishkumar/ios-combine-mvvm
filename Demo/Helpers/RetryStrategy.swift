import Foundation

enum RetryStrategy {
    case immediate(maxAttempts: Int)
    case exponentialBackoff(maxAttempts: Int, initialDelay: TimeInterval, multiplier: Double)
    case custom(maxAttempts: Int, delays: [TimeInterval])
    
    func shouldRetry(attempt: Int) -> Bool {
        let maxAttempts: Int
        switch self {
        case .immediate(let max):
            maxAttempts = max
        case .exponentialBackoff(let max, _, _):
            maxAttempts = max
        case .custom(let max, _):
            maxAttempts = max
        }
        return attempt < maxAttempts
    }
    
    func delay(for attempt: Int) -> TimeInterval {
        switch self {
        case .immediate:
            return 0
        case .exponentialBackoff(_, let initialDelay, let multiplier):
            return initialDelay * pow(multiplier, Double(attempt))
        case .custom(_, let delays):
            return attempt < delays.count ? delays[attempt] : delays.last ?? 1.0
        }
    }
}

struct ErrorRecoveryStrategy {
    static func retryStrategy(for error: APIError) -> RetryStrategy {
        switch error {
        case .rateLimitExceeded:
            return .exponentialBackoff(maxAttempts: 3, initialDelay: 5.0, multiplier: 2.0)
        case .serverError:
            return .exponentialBackoff(maxAttempts: 3, initialDelay: 2.0, multiplier: 2.0)
        case .noConnection:
            return .exponentialBackoff(maxAttempts: 5, initialDelay: 3.0, multiplier: 1.5)
        case .unauthorized:
            return .immediate(maxAttempts: 0)
        case .invalidURL, .invalidResponse, .invalidData, .decodingFailed, .requestFailed:
            return .exponentialBackoff(maxAttempts: 2, initialDelay: 1.0, multiplier: 2.0)
        }
    }
    
    static func isRetryable(_ error: APIError) -> Bool {
        switch error {
        case .unauthorized:
            return false
        case .invalidURL:
            return false
        default:
            return true
        }
    }
}
