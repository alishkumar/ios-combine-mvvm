# News App - Architecture & Implementation Guide

## Overview
This document describes the architecture, implementation, and features of the News and Bookmarks sections in the Demo app.

## Architecture

### MVVM Pattern
The app follows the **Model-View-ViewModel (MVVM)** architecture pattern:

- **Models**: Data structures (`Article`, `NewsResponse`, `NewsArticleModel`)
- **Views**: UIKit ViewControllers (`NewsListViewController`, `BookmarksViewController`)
- **ViewModels**: Business logic (`NewsViewModel`)
- **Services**: Network layer (`NewsService`, `URLSessionAPIClient`)

### Layer Structure

```
┌─────────────────────────────────────┐
│         View Layer (UIKit)          │
│  NewsListViewController             │
│  BookmarksViewController            │
│  NewsDetailViewController           │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│      ViewModel Layer (Combine)       │
│  NewsViewModel                       │
│  - newsArticles: [Article]          │
│  - bookmarkedArticles: [Article]     │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│      Service Layer (Protocols)        │
│  NewsServiceProtocol                 │
│  NewsService                         │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│      Network Layer                   │
│  URLSessionAPIClient                 │
│  NewsEndPoint                        │
└──────────────────────────────────────┘
```

## Key Features

### 1. News Section
- **API Integration**: Fetches news from NewsAPI.org
- **Pagination**: Infinite scroll with automatic loading
- **Search**: Real-time news search functionality
- **Offline Support**: Caches articles for offline reading
- **Image Caching**: NSCache for efficient image loading
- **Empty States**: User-friendly empty state views

### 2. Bookmarks Section
- **Local Storage**: SwiftData for persistent bookmarks
- **Swipe to Delete**: Easy bookmark removal
- **Separate Data**: Isolated from News section data

### 3. Error Handling
- **Network Retry**: Automatic retry with exponential backoff (3 attempts)
- **Offline Detection**: NetworkMonitor for connection status
- **Graceful Degradation**: Falls back to cached data when offline
- **Error Recovery**: Handles API failures without crashing

### 4. Notifications
- **Trending News**: Local notifications for top headlines
- **Scheduled**: Hourly notifications for trending articles
- **User-Friendly**: Non-intrusive notification content

## Data Flow

### News Loading Flow
```
User Action → ViewController → ViewModel.loadTopHeadlines()
    ↓
NewsService.fetchTopHeadlines()
    ↓
URLSessionAPIClient.request()
    ↓
Network Request (with retry logic)
    ↓
Response → ViewModel.syncArticlesWithAPI()
    ↓
@Published newsArticles → ViewController updates UI
    ↓
OfflineCache.saveArticlesForOffline()
```

### Bookmark Flow
```
User Taps Bookmark → ViewModel.toggleBookmark()
    ↓
SwiftData ModelContext
    ↓
Save/Delete NewsArticleModel
    ↓
@Published bookmarkedArticles → BookmarksViewController updates
```

## Code Quality

### SOLID Principles
- **Single Responsibility**: Each class has one clear purpose
- **Open/Closed**: Protocol-based services allow extension
- **Liskov Substitution**: Protocol conformance ensures compatibility
- **Interface Segregation**: Focused protocols (NewsServiceProtocol)
- **Dependency Inversion**: ViewModels depend on protocols, not concrete classes

### Best Practices
- **Dependency Injection**: Services injected via initializers
- **Reactive Programming**: Combine for state management
- **Memory Management**: `[weak self]` to prevent retain cycles
- **Error Handling**: Comprehensive error types and recovery
- **Testing**: Unit tests with mocks, UI tests for critical flows

## Testing Strategy

### Unit Tests
- **NewsViewModelTests**: Tests ViewModel logic, pagination, search
- **NewsServiceTests**: Tests service layer and API integration
- **Mock Services**: MockNewsService for isolated testing

### UI Tests
- **NewsUITests**: Tests user interactions, navigation, search
- **Accessibility**: Ensures UI elements are accessible
- **Edge Cases**: Tests empty states, error scenarios

## Offline Mode

### Implementation
- **Caching**: UserDefaults for article storage
- **Cache Validation**: Time-based cache expiration (1 hour)
- **Automatic Fallback**: Loads cached data when offline
- **Sync on Reconnect**: Automatically syncs when connection restored

### Cache Strategy
```swift
// Save on successful API response
OfflineCache.shared.saveArticlesForOffline(newArticles)

// Load when offline
if !NetworkMonitor.shared.isConnected {
    loadOfflineArticles()
}
```

## Notifications

### Trending News Notifications
- **Schedule**: Hourly notifications
- **Content**: Top article title and URL
- **User Control**: Can be disabled in system settings
- **Non-Intrusive**: Simple text notifications

## Network Layer

### Retry Logic
- **Max Attempts**: 3 retries
- **Exponential Backoff**: 1s, 2s, 4s delays
- **Error Types**: Handles different HTTP status codes
- **Connection Check**: Verifies network before retry

### Error Types
```swift
enum APIError {
    case invalidURL
    case invalidResponse
    case unauthorized
    case rateLimitExceeded
    case serverError
    case noConnection
}
```

## File Structure

```
Demo/
├── Models/
│   ├── NewsResponse.swift
│   └── NewsArticleModel.swift
├── ViewModels/
│   └── NewsViewModel.swift
├── Services/
│   ├── NewsService.swift
│   ├── NewsEndPoint.swift
│   └── URLSessionAPIClient.swift
├── ViewsUIKit/
│   ├── NewsListViewController.swift
│   ├── BookmarksViewController.swift
│   ├── NewsDetailViewController.swift
│   ├── NewsTableViewCell.swift
│   ├── NewsView.swift
│   └── BookmarksView.swift
├── Helpers/
│   ├── ImageCache.swift
│   ├── NetworkMonitor.swift
│   ├── OfflineCache.swift
│   ├── NotificationManager.swift
│   └── PublisherExtensions.swift
└── Tests/
    ├── NewsViewModelTests.swift
    ├── NewsServiceTests.swift
    └── NewsUITests.swift
```

## Usage Examples

### Loading News
```swift
viewModel.loadTopHeadlines(refresh: true)
```

### Searching News
```swift
viewModel.searchNews(query: "technology", refresh: true)
```

### Bookmarking Article
```swift
viewModel.toggleBookmark(for: article)
```

### Checking Bookmark Status
```swift
let isBookmarked = viewModel.isBookmarked(articleId: article.id)
```

## Dependencies
- **Combine**: Reactive programming
- **SwiftData**: Local persistence
- **UserNotifications**: Local notifications
- **Network**: Network monitoring

## API Configuration
- **Base URL**: `https://newsapi.org`
- **Endpoints**: `/v2/top-headlines`, `/v2/everything`
- **API Key**: Configure in `NewsEndPoint.swift` or `Info.plist`

## Performance Optimizations
- **Image Caching**: NSCache with 100 item limit
- **Pagination**: Loads 20 articles per page
- **Lazy Loading**: Images load asynchronously
- **Memory Management**: Proper cleanup of Combine subscriptions

## Future Enhancements
- [ ] Category filtering UI
- [ ] Article sharing improvements
- [ ] Dark mode support
- [ ] Widget support
- [ ] Background refresh
- [ ] Advanced search filters

## Testing Coverage
- ✅ ViewModel unit tests
- ✅ Service layer tests
- ✅ UI tests for critical flows
- ✅ Mock API responses
- ✅ Error handling tests

## License
Internal project - Demo app
