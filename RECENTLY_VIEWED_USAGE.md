# Recently Viewed - Quick Usage Guide

## 🎯 How It Works

### Automatic Tracking
Products are automatically added to "Recently Viewed" when a user opens the product detail screen. No manual action required!

```swift
// Happens automatically in ProductDetailViewModel
Task.detached(priority: .background) {
    try? await RecentlyViewedService.shared.addToRecentlyViewed(productId: productId)
}
```

### Displaying on Home Screen
The section appears automatically on the home screen when there are viewed products:

```swift
// In HomeView.swift - loads automatically on appear
.onAppear {
    viewModel.loadRecentlyViewedIfNeeded()
}
```

---

## 📋 API Reference

### RecentlyViewedService

#### Fetch Product IDs
```swift
let productIds = try await RecentlyViewedService.shared.fetchRecentlyViewedIds()
// Returns: [String] - Array of product IDs, newest first
```

#### Add Product to Recently Viewed
```swift
try await RecentlyViewedService.shared.addToRecentlyViewed(productId: "product123")
// Adds product with current timestamp
// Auto-cleans up old entries beyond limit (10)
```

#### Clear All Recently Viewed
```swift
try await RecentlyViewedService.shared.clearRecentlyViewed()
// Removes all recently viewed products for current user
```

---

## 🎨 Customization

### Change Maximum Products Shown
In `RecentlyViewedService.swift`:
```swift
private let maxRecentlyViewed = 10  // Change this number
```

### Change UI Layout
In `HomeView.swift`, modify `RecentlyViewedProductCard`:
```swift
struct RecentlyViewedProductCard: View {
    // Customize frame, colors, fonts, etc.
    .frame(width: 160)  // Card width
    .frame(width: 160, height: 160)  // Image size
}
```

### Change Section Position
In `HomeView.swift`, move `recentlyViewedSection` in the LazyVStack:
```swift
LazyVStack(spacing: 0) {
    promotionalBanner
    nativeSearchBar
    categoriesSection
    recentlyViewedSection  // ← Move this up/down
    preciousMomentsSection
    // ...
}
```

---

## 🔧 Troubleshooting

### Section Not Showing
**Problem**: Recently viewed section doesn't appear

**Solutions**:
1. Check user is authenticated:
   ```swift
   Auth.auth().currentUser?.uid  // Must not be nil
   ```

2. Verify Firestore structure exists:
   ```
   users/{userId}/recently_viewed/{productId}
   ```

3. Check console for errors:
   ```swift
   #if DEBUG
   print("[HomeViewModel] Loaded X recently viewed products")
   #endif
   ```

### Products Not Being Tracked
**Problem**: Viewing products doesn't add them to recently viewed

**Solutions**:
1. Ensure ProductDetailViewModel is fetching successfully
2. Check network connectivity
3. Verify Firestore permissions allow writes to `users/{userId}/recently_viewed`

### Loading Forever
**Problem**: Section shows loading spinner indefinitely

**Solutions**:
1. Check network connection
2. Verify Firestore rules allow read access
3. Check console for error messages
4. Retry by pulling to refresh on home screen

---

## 🎭 Testing Guide

### Test Scenario 1: First Time User
1. Fresh install / new user
2. Home screen should NOT show recently viewed section
3. View a product
4. Return to home screen
5. Section should appear with that product

### Test Scenario 2: Multiple Products
1. View 5 different products
2. Return to home screen
3. Should see all 5 products in recently viewed
4. Products should be ordered newest to oldest

### Test Scenario 3: Network Failure
1. View some products (builds recently viewed)
2. Turn off network
3. Open home screen
4. Recently viewed section should show existing products
5. Turn network back on
6. Section should update if needed

### Test Scenario 4: Wishlist Integration
1. View some products
2. Home screen shows recently viewed
3. Tap heart icon on a product
4. Heart should fill/unfill correctly
5. Check wishlist screen - product should be there

### Test Scenario 5: Limit (10 Products)
1. View 15 different products
2. Return to home screen
3. Should only see 10 most recent products

---

## 📊 Firestore Structure

### Document Path
```
users/{userId}/recently_viewed/{productId}
```

### Document Data
```json
{
  "viewedAt": Timestamp
}
```

### Example
```
users/
  abc123/
    recently_viewed/
      prod_001/
        viewedAt: 2026-02-05 10:30:00
      prod_002/
        viewedAt: 2026-02-05 10:25:00
```

### Query Used
```swift
db.collection("users")
  .document(userId)
  .collection("recently_viewed")
  .order(by: "viewedAt", descending: true)
  .limit(to: 10)
```

---

## 🔐 Required Firestore Rules

Add these rules to allow recently viewed functionality:

```javascript
// Allow users to read/write their own recently viewed
match /users/{userId}/recently_viewed/{productId} {
  allow read, write: if request.auth != null && request.auth.uid == userId;
}
```

---

## 💡 Best Practices

### Do's ✅
- Let the system track views automatically
- Trust the caching mechanism
- Use pull-to-refresh if data seems stale
- Check console logs during development

### Don'ts ❌
- Don't manually call `addToRecentlyViewed()` unless needed
- Don't clear the cache unnecessarily
- Don't modify Firestore structure without updating queries
- Don't remove error handling code

---

## 📞 Support

### Debug Mode Logging
All Recently Viewed operations log to console in DEBUG builds:
```
[HomeViewModel] Loaded 5 recently viewed products
[HomeViewModel] Failed to load recently viewed: Error...
```

### Common Error Messages
- `"User not authenticated"` - User needs to sign in
- `"No recently viewed products"` - Normal for new users
- `"Failed to fetch product X"` - Network or permissions issue

---

## 🎉 Quick Start

**That's it!** Recently Viewed works automatically. Just:
1. ✅ User views products
2. ✅ System tracks them
3. ✅ Home screen shows them

No configuration needed! 🚀
