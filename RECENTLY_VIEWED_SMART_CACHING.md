# Recently Viewed - Smart Caching Implementation

## Overview

The recently viewed feature now uses **smart caching with timestamp-based invalidation** to significantly reduce Firestore reads while keeping data fresh.

## How It Works

### Cache Strategy

- **Cache Duration**: 30 seconds (configurable via `recentlyViewedCacheInterval`)
- **Automatic Invalidation**: Cache expires after 30 seconds
- **Force Refresh**: Pull-to-refresh bypasses cache

### Flow Diagram

```
User returns to Home Screen
           ↓
Check cache timestamp
           ↓
    ┌──────┴──────┐
    │             │
Fresh?          Stale?
(< 30s)         (> 30s)
    │             │
    ↓             ↓
Use cached    Fetch from
  data        Firestore
    │             │
    └──────┬──────┘
           ↓
    Display UI
```

## Implementation Details

### 1. Cache Tracking

**File**: `jewellery/ViewModels/HomeViewModel.swift`

```swift
// Cache timestamp to track last fetch
private var lastRecentlyViewedFetch: Date?

// Cache validity period (30 seconds)
private let recentlyViewedCacheInterval: TimeInterval = 30
```

### 2. Smart Refresh Logic

```swift
func refreshRecentlyViewed() {
    if let lastFetch = lastRecentlyViewedFetch {
        let timeSinceLastFetch = Date().timeIntervalSince(lastFetch)
        
        if timeSinceLastFetch < recentlyViewedCacheInterval {
            // Cache is fresh, skip fetch
            return
        }
    }
    
    // Cache is stale or doesn't exist, fetch from Firestore
    Task {
        await loadRecentlyViewedProducts(forceRefresh: false)
    }
}
```

### 3. Cache Timestamp Updates

Cache timestamp is updated in two scenarios:

**Scenario 1: Successful fetch with products**
```swift
recentlyViewedProducts = fetchedProducts
lastRecentlyViewedFetch = Date()
```

**Scenario 2: Empty result**
```swift
guard !productIds.isEmpty else {
    lastRecentlyViewedFetch = Date() // Still update timestamp
    return
}
```

## Usage Examples

### Example 1: Normal Navigation
```
Time: 0s  - Open Home → Fetch from Firestore
Time: 5s  - View Product
Time: 10s - Back to Home → Use cached data (fresh)
Time: 15s - View Product
Time: 20s - Back to Home → Use cached data (fresh)
Time: 35s - Back to Home → Fetch from Firestore (stale)
```

**Result**: 2 Firestore queries instead of 4 = **50% reduction**

### Example 2: Quick Tab Switching
```
Time: 0s  - Open Home → Fetch from Firestore
Time: 2s  - Switch to Profile
Time: 4s  - Switch to Home → Use cached data
Time: 6s  - Switch to Categories
Time: 8s  - Switch to Home → Use cached data
Time: 10s - Switch to Profile
Time: 12s - Switch to Home → Use cached data
```

**Result**: 1 Firestore query instead of 4 = **75% reduction**

### Example 3: Pull-to-Refresh
```
Time: 0s  - Open Home → Fetch from Firestore
Time: 10s - Pull to refresh → Force fetch (bypasses cache)
Time: 15s - Back to Home → Use cached data (fresh from refresh)
```

**Result**: Force refresh always fetches fresh data

## Configuration

### Adjusting Cache Duration

To change how long the cache remains valid:

```swift
// In HomeViewModel.swift, line ~20
private let recentlyViewedCacheInterval: TimeInterval = 30 // Change this value

// Examples:
// 60 seconds (1 minute) - Less frequent updates, fewer reads
private let recentlyViewedCacheInterval: TimeInterval = 60

// 15 seconds - More frequent updates, more reads
private let recentlyViewedCacheInterval: TimeInterval = 15

// 120 seconds (2 minutes) - Very infrequent updates
private let recentlyViewedCacheInterval: TimeInterval = 120
```

### Recommended Settings

| Use Case | Cache Duration | Reasoning |
|----------|---------------|-----------|
| **High Traffic App** | 60-120 seconds | Minimize Firestore costs |
| **Frequent Updates** | 15-30 seconds | Balance freshness & cost |
| **Real-time Critical** | 5-10 seconds | Maximum freshness |
| **Development/Testing** | 5 seconds | See changes quickly |

**Current Setting**: 30 seconds (balanced approach)

## Benefits

### 1. Cost Reduction
- **Before**: Every home screen visit = 1 query + N product fetches
- **After**: Only if cache is stale (> 30s old)
- **Savings**: 50-80% reduction in Firestore reads depending on usage

### 2. Performance Improvement
- Instant display of cached data (no network wait)
- Smoother navigation experience
- Reduced loading indicators

### 3. Network Efficiency
- Less data transfer
- Better experience on slow connections
- Reduced cellular data usage

## Monitoring & Debugging

### Log Messages

**Cache Hit (Fresh)**
```
[HomeViewModel] Recently viewed cache is fresh (12s old), skipping fetch
```

**Cache Miss (Stale)**
```
[HomeViewModel] Recently viewed cache is stale (45s old), refreshing...
```

**First Load**
```
[HomeViewModel] No recently viewed cache, fetching for first time...
```

**Successful Fetch**
```
[HomeViewModel] ✅ Recently viewed section updated with 5 products (cached at: 2026-02-07 10:30:45)
```

### Testing Cache Behavior

**Test 1: Verify Cache Works**
1. Open home screen (should fetch from Firestore)
2. Navigate away and back within 30s (should use cache)
3. Look for "cache is fresh" log

**Test 2: Verify Cache Expires**
1. Open home screen (should fetch)
2. Wait 35+ seconds
3. Return to home screen (should fetch again)
4. Look for "cache is stale" log

**Test 3: Verify Force Refresh**
1. Open home screen
2. Pull to refresh (should always fetch)
3. Look for fetch logs even if cache is fresh

## Edge Cases Handled

### 1. Empty Recently Viewed
- Cache timestamp is still updated
- Prevents repeated queries when list is empty
- User must view a product to trigger new fetch

### 2. Error During Fetch
- Cache timestamp is NOT updated on error
- Next attempt will retry
- Existing data is preserved (not cleared)

### 3. User Logs Out
- Cache is automatically cleared when `refreshData()` is called
- `lastRecentlyViewedFetch` is set to nil

### 4. App Restart
- Cache is in-memory only (doesn't persist)
- First load after restart will fetch from Firestore
- This is intentional for data freshness

## Future Enhancements

### Potential Improvements

1. **Persistent Cache**
   - Save to disk with timestamp
   - Survive app restarts
   - Faster cold starts

2. **Real-time Updates**
   - Use Firestore snapshot listener
   - Automatic updates when data changes
   - No manual refresh needed

3. **Optimistic Updates**
   - Add product to UI immediately when viewed
   - Background sync with Firestore
   - Even faster perceived performance

4. **Smart Invalidation**
   - Only invalidate if coming from product detail
   - Keep cache when switching tabs
   - Context-aware refreshing

## Comparison with Other Approaches

| Approach | Firestore Reads | Freshness | Complexity |
|----------|----------------|-----------|------------|
| **Always Fetch** | High (100%) | Real-time | Low |
| **Smart Cache (Current)** | Low (20-50%) | 30s delay | Medium |
| **Real-time Listener** | Medium (50-70%) | Real-time | High |
| **Optimistic UI** | Low (20-30%) | Instant | High |

## Troubleshooting

### Problem: Data Not Updating
**Symptoms**: Recently viewed shows old data even after viewing products

**Solutions**:
1. Check cache duration - might be too long
2. Verify timestamp is being set after fetch
3. Pull-to-refresh to force update
4. Check logs for "cache is fresh" messages

### Problem: Too Many Fetches
**Symptoms**: Seeing fetch logs on every home screen visit

**Solutions**:
1. Verify cache timestamp is being set
2. Check if `lastRecentlyViewedFetch` is nil
3. Increase cache duration if needed
4. Look for errors during fetch

### Problem: Stale Data on Return
**Symptoms**: Cache shows old data when it should be fresh

**Solutions**:
1. Check system time is correct
2. Verify timestamp comparison logic
3. Reduce cache duration temporarily
4. Check for timezone issues

## Technical Notes

- Cache is **in-memory only** (does not persist across app launches)
- Uses `Date()` for timestamp tracking
- Thread-safe with `@Published` properties
- Works with SwiftUI's reactive updates
- Compatible with pull-to-refresh
- Respects user authentication state
