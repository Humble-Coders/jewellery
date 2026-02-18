# Recently Viewed - Debug Guide

## Current Situation

Your Firebase shows:
- ✅ User authenticated with email `sharnya@gmail.com`
- ✅ `isGoogleSignIn: false` (using email/password auth)
- ✅ 2 products in the `recently_viewed` subcollection
- ❌ Home screen not showing recently viewed products

## Root Cause

There's a mismatch between two storage patterns:

### 1. User Model (Unused Field)
```swift
// jewellery/Models/User.swift - Lines 18, 33
var recentlyViewed: [String]? // Array field in user document
```

This is looking for a field called `recently_viewed` **in** the user document, but it doesn't exist there.

### 2. RecentlyViewedService (Correct Implementation)
```swift
// Uses subcollection: users/{userId}/recently_viewed/{productId}
```

Your Firebase correctly uses this subcollection pattern.

## What's Happening

1. **User Model logs**: "RecentlyViewed count: 0" 
   - This is from the User decoder trying to read a field that doesn't exist
   - This is harmless and doesn't affect functionality

2. **RecentlyViewedService**: Should fetch from the subcollection
   - If user is logged in → fetches product IDs from subcollection
   - If user is NOT logged in → returns empty array

## Debug Steps

### Step 1: Check Authentication Status

Run the app and look for these logs in Xcode console:

```
📱 [RecentlyViewedService] User not logged in - returning empty recently viewed list
```
OR
```
📱 [RecentlyViewedService] Fetching recently viewed for userId: {some-id}
```

**If you see "User not logged in":**
- The issue is that you're not actually logged in when viewing the home screen
- Solution: Log in with email/password first

**If you see "Fetching recently viewed for userId":**
- Authentication is working
- Continue to Step 2

### Step 2: Check What's Being Fetched

Look for these logs:

```
📱 [RecentlyViewedService] Fetched {N} recently viewed product IDs: [id1, id2]
```

**If N = 0:**
- The subcollection is empty OR
- The query isn't finding documents

**If N > 0:**
- Product IDs are being fetched correctly
- Continue to Step 3

### Step 3: Check Product Detail Loading

Look for these logs:

```
[HomeViewModel] Fetching full product details for {N} products...
[HomeViewModel] Fetching product 1/N: {productId}
[HomeViewModel] ✅ Product {productId} data found: {name}
```

**If you see "⚠️ Product {id} has no data":**
- The product document doesn't exist
- The document IDs in recently_viewed don't match actual products

**If you see "❌ Failed to fetch product":**
- There's an error loading the product data
- Check the error message

### Step 4: Check Final UI Update

Look for:

```
[HomeViewModel] ✅ Recently viewed section updated with {N} products
```

**If N = 0:**
- No products were successfully loaded
- The section will be hidden (by design)

**If N > 0:**
- Products should appear on the home screen
- If they don't, there's a UI rendering issue

## Current Fixes Applied

1. ✅ **RecentlyViewedService** - Returns empty array instead of throwing error when user not logged in
2. ✅ **Added comprehensive debug logging** - Will help identify exactly where the issue is
3. ✅ **HomeViewModel** - Handles unauthenticated state gracefully

## How to Test

### Test 1: Verify Authentication
1. Open the app
2. Log in with email: `sharnya@gmail.com` and password
3. Check if you stay logged in after restart

### Test 2: Track a Product View
1. After logging in, navigate to any product detail page
2. Wait 2 seconds (tracking happens in background)
3. Go back to home screen
4. Pull to refresh

### Test 3: Check Firebase Console
1. Go to Firebase Console → Firestore
2. Navigate to: `users/{your-user-id}/recently_viewed`
3. Verify the product IDs match actual products in the `products` collection

## Common Issues

### Issue 1: User Not Staying Logged In
**Symptom**: Logs show "User not logged in" every time you open the app

**Cause**: Firebase Auth session not persisting

**Solution**: Check if Firebase is properly configured in `GoogleService-Info.plist`

### Issue 2: Product IDs Don't Match
**Symptom**: Products found in recently_viewed but not in products collection

**Cause**: Document IDs in `recently_viewed` subcollection don't match actual product IDs

**Example Firebase structure should look like**:
```
users/
  {userId}/
    recently_viewed/
      X5aZZ2HTx1bq1hwUWqEV/    ← This must match a document ID in products/
        viewedAt: {timestamp}
      ZnpXwj721M5E8DeErdRp/    ← This must match a document ID in products/
        viewedAt: {timestamp}

products/
  X5aZZ2HTx1bq1hwUWqEV/       ← Same ID as above
    name: "Gold Ring"
    ...
  ZnpXwj721M5E8DeErdRp/       ← Same ID as above
    name: "Diamond Necklace"
    ...
```

### Issue 3: Subcollection vs Array Field Confusion
**Symptom**: Logs say "RecentlyViewed count: 0"

**Status**: This is expected and harmless. The User model has an unused field.

**Optional cleanup** (not required):
You can remove the `recentlyViewed` field from the User model since it's not being used.

## Next Steps

1. **Run the app** and check the Xcode console logs
2. **Look for the specific log messages** mentioned in the debug steps above
3. **Share the logs** with the exact output you see
4. Based on the logs, we can identify the exact issue

## Quick Verification Script

If you want to test if the service works, add this to your HomeView's onAppear:

```swift
.onAppear {
    // ... existing code ...
    
    // Debug: Test recently viewed service
    Task {
        do {
            let ids = try await RecentlyViewedService.shared.fetchRecentlyViewedIds()
            print("🧪 DEBUG TEST: Found \(ids.count) recently viewed: \(ids)")
        } catch {
            print("🧪 DEBUG TEST ERROR: \(error)")
        }
    }
}
```

This will immediately show if the service can fetch the IDs when the home screen loads.
