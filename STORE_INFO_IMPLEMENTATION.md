# Store Information Feature - Complete Implementation Guide

## Overview

The Store Information screen displays comprehensive store details including location, contact information, and operating hours. It follows the exact design from the provided screenshots with full Firebase integration.

## Architecture

### MVVM Pattern
- **Model**: `StoreInfo`, `StoreHours`
- **ViewModel**: `StoreInfoViewModel` (ObservableObject, single source of truth)
- **View**: `StoreInfoView`
- **Service**: `StoreInfoService` (Repository pattern)

## Files Created

### 1. Models (`jewellery/Models/StoreInfo.swift`)
```swift
- StoreInfo: Store details (name, address, phone, email, location, logo)
- StoreHours: Operating hours by day of week
```

### 2. Service (`jewellery/Services/StoreInfoService.swift`)
```swift
- fetchStoreInfo(): Async fetch from Firestore
- fetchStoreHours(): Async fetch store hours
```

### 3. ViewModel (`jewellery/ViewModels/StoreInfoViewModel.swift`)
```swift
- Observable properties: storeInfo, storeHours, todayStatus
- Auto-loads data on init
- Business logic: calculate today's status, sanitize phone numbers
- External actions: maps, phone calls, email, WhatsApp
```

### 4. View (`jewellery/Views/Store/StoreInfoView.swift`)
```swift
- Complete UI matching the design
- Cards: Logo, Store Details, Contact Info, Store Hours
- Error handling and loading states
```

## Firebase Structure

### Collection: `store_info`

#### Document: `main_store`
```json
{
  "name": "Gagan Jewellers Pvt Ltd",
  "address": "123 Mall Road, Near City Center, Patiala, Punjab 147001",
  "phone_primary": "+91-1234567770",
  "phone_secondary": "+91-9876543211",
  "email": "contact@gaganjewellers.com",
  "latitude": 23.5,
  "longitude": 40.6,
  "logo_images": [
    "https://firebasestorage.googleapis.com/..."
  ],
  "establishedYear": "1990",
  "gstin": "12345678"
}
```

#### Document: `store_hours_closed`
```json
{
  "monday": true,    // true = closed, false = open
  "tuesday": true,
  "wednesday": true,
  "thursday": true,
  "friday": false,
  "saturday": false,
  "sunday": true
}
```

**Note**: The field names indicate "closed" days. If `monday: true`, the store is CLOSED on Monday.

## Features Implemented

### ✅ 1. Reactive State Management
```swift
@Published var storeInfo: StoreInfo?
@Published var storeHours: StoreHours?
@Published var todayStatus: String = ""
@Published var statusColor: String = "#FF0000"
```

### ✅ 2. Async Data Loading
- Parallel fetching of store info and hours
- Automatic loading on ViewModel creation
- Error handling without blocking UI
- Preserves existing data on failure

### ✅ 3. Today's Store Hours
```swift
// Automatically calculates based on current day
- Gets current weekday from Calendar
- Checks if store is open/closed
- Updates status badge color (red/green)
- Shows "Monday - CLOSED" or "Monday - OPEN"
```

### ✅ 4. External Actions

#### Get Directions
```swift
func openDirections() {
    // 1. Try Apple Maps (native)
    // 2. Fallback to Google Maps (browser)
}
```

#### Phone Calls
```swift
func callPrimaryPhone() {
    // Sanitizes phone number: +91-123-456-7770 → +911234567770
    // Opens tel:// URL
}
```

#### Email
```swift
func sendEmail() {
    // Opens mailto:// URL
}
```

#### WhatsApp
```swift
func openWhatsApp() {
    // 1. Try WhatsApp app: whatsapp://send?phone=...
    // 2. Fallback to WhatsApp Web: https://wa.me/...
    // Pre-fills message: "Hello, I would like to inquire..."
}
```

### ✅ 5. Helper Methods
```swift
- sanitizePhoneNumber(): Removes spaces, dashes, parentheses
- urlEncode(): URL-encodes strings for deep links
- canOpen(): Checks if URL scheme is available
- open(): Opens URL (fire-and-forget, no loading state)
```

## UI Components

### Logo Section
- Displays store logo from Firebase Storage
- 280x200pt size
- White background with shadow
- Rounded corners
- Fallback: Building icon placeholder

### Store Details Card
- Store name (20pt, semibold, mauve color)
- Address with map pin icon
- "Get Directions" button (brown background)
- Tappable → Opens maps

### Contact Information Card
- Section title: "Contact Information"
- Primary phone (tappable → calls)
- Secondary phone (tappable → calls)
- Email (tappable → opens email)
- "Chat on WhatsApp" button (green #25D366)

### Store Hours Card
- Section title with clock icon
- Today's status badge (red "CLOSED" or green "OPEN")
- List of all days with open/closed status
- Monday through Sunday

## Navigation

### Access Points
1. **Sidebar**: Tap "Store Info" menu item
2. **Direct Navigation**: `router.navigate(to: .storeInfo)`

### Navigation Flow
```
Profile Tab → Sidebar → Store Info
    ↓
StoreInfoView loads
    ↓
Fetches data from Firebase
    ↓
Displays store information
```

### Back Navigation
- Back button in navigation bar
- Calls `router.pop()`
- Returns to previous screen

## Error Handling

### Network Errors
- Shows ErrorView with retry button
- Preserves existing data if available
- Logs error to console

### Missing Data
- Graceful fallbacks:
  - No logo → Shows placeholder icon
  - No secondary phone → Hides secondary phone row
  - No store hours → Hides hours card

### Failed Actions
- External actions (maps, calls, etc.) fail silently
- No error dialogs for external app launches
- Logs errors to console for debugging

## Testing

### Test Cases

**Test 1: Load Store Info**
```
1. Navigate to Store Info
2. Verify logo displays
3. Verify store name and address show
4. Verify contact info displays
5. Verify store hours display
```

**Test 2: Today's Status**
```
1. Check current day of week
2. Verify status badge shows correct state
3. Verify color is red (closed) or green (open)
4. Verify day name is correct
```

**Test 3: Get Directions**
```
1. Tap "Get Directions"
2. On iOS: Apple Maps should open
3. On simulator: Browser may open with Google Maps
4. Verify location is correct
```

**Test 4: Phone Call**
```
1. Tap primary phone number
2. Verify phone dialer opens (on device)
3. Verify number is correctly formatted
4. Repeat for secondary phone
```

**Test 5: Email**
```
1. Tap email address
2. Verify email app opens
3. Verify email is pre-filled
```

**Test 6: WhatsApp**
```
1. Tap "Chat on WhatsApp"
2. If WhatsApp installed: Opens app with pre-filled message
3. If not installed: Opens WhatsApp Web in browser
4. Verify phone number and message are correct
```

**Test 7: Error State**
```
1. Disconnect network
2. Navigate to Store Info
3. Verify error message displays
4. Tap retry button
5. Verify data loads when network restored
```

## Customization

### Colors
```swift
// Main Colors (already using Theme)
- Background: #F5F5F5 (light gray)
- Cards: White
- Primary Text: Black
- Secondary Text: #9A9A9A (gray)
- Accent: #C49A7C (mauve/brown)
- Button: #926F6F (brown)
- WhatsApp: #25D366 (green)
- Closed: #FF0000 (red)
- Open: #4CAF50 (green)
```

### Modify Store Hours Logic
To change what "closed" means:

**Current**: `store_hours_closed` document where `true` = closed

**To invert** (make `true` = open):
```swift
// In StoreHours model
func isOpen(onWeekday weekday: Int) -> Bool {
    switch weekday {
    case 1: return !sunday  // Invert the boolean
    case 2: return !monday
    // ... etc
    }
}
```

### Add More Contact Methods
```swift
// In StoreInfoViewModel
func openInstagram() {
    let instagramUrl = "instagram://user?username=gaganjewellers"
    // ... similar pattern
}

func openFacebook() {
    let facebookUrl = "fb://profile/123456789"
    // ... similar pattern
}
```

### Customize WhatsApp Message
```swift
// In openWhatsApp() method
let message = "Hello! I saw your jewellery collection and I'm interested in..."
```

## Performance

### Optimization
- ✅ Parallel data fetching (store info + hours)
- ✅ Lazy image loading with SDWebImage
- ✅ Fire-and-forget external actions (no UI blocking)
- ✅ Minimal re-renders (reactive state)

### Network Efficiency
- Single fetch on load
- No polling or real-time listeners
- Cached data preserved on error
- Manual refresh via pull-to-refresh (if added)

## Firestore Reads
- **Initial Load**: 2 reads (main_store + store_hours_closed)
- **Retry**: 2 reads
- **Navigation Back and Forth**: Uses cached data (0 reads)

## Troubleshooting

### Issue: Store Hours Show Wrong Status
**Problem**: Status shows opposite of expected

**Solution**: Check Firebase field naming
- If document is `store_hours_closed`: `true` = closed
- If document is `store_hours_open`: `true` = open
- Update `isOpen()` logic accordingly

### Issue: Get Directions Not Working
**Problem**: Nothing happens when tapping button

**Solution**: 
1. Check console for URL being generated
2. Verify latitude/longitude in Firebase
3. Test on physical device (simulator may not have Maps)

### Issue: WhatsApp Not Opening
**Problem**: Button does nothing

**Solution**:
1. Install WhatsApp on device
2. Check phone number format (should include country code)
3. Check console for URL being generated
4. Verify URL encoding is correct

### Issue: Logo Not Displaying
**Problem**: Shows placeholder instead of logo

**Solution**:
1. Check `logo_images` array in Firebase
2. Verify image URL is accessible
3. Check Firebase Storage permissions
4. Verify image format is supported

### Issue: Secondary Phone Not Showing
**Problem**: Only primary phone displays

**Solution**:
1. Check `phone_secondary` field exists in Firebase
2. Verify it's not empty string
3. Optional field - intentionally hidden if not provided

## Future Enhancements

### Potential Improvements

1. **Real-time Updates**
```swift
// Use snapshot listener
db.collection("store_info")
    .document("main_store")
    .addSnapshotListener { snapshot, error in
        // Auto-update when admin changes info
    }
```

2. **Operating Hours Time Ranges**
```swift
// Instead of just open/closed, show actual hours
"Monday: 10:00 AM - 6:00 PM"
"Tuesday: Closed"
```

3. **Multiple Locations**
```swift
// Support multiple store branches
struct StoreBranch {
    let name: String
    let address: String
    // ...
}
```

4. **Social Media Links**
```swift
// Add Instagram, Facebook, Twitter
Section("Follow Us") {
    socialMediaRow(icon: "instagram", handle: "@gaganjewellers")
    socialMediaRow(icon: "facebook", handle: "GaganJewellers")
}
```

5. **Save to Contacts**
```swift
import Contacts
import ContactsUI

func saveToContacts() {
    let store = CNMutableContact()
    store.givenName = storeInfo.name
    store.phoneNumbers = [CNLabeledValue(
        label: CNLabelPhoneNumberMain,
        value: CNPhoneNumber(stringValue: storeInfo.primaryPhone)
    )]
    // ... show contact view controller
}
```

6. **Share Store Info**
```swift
func shareStoreInfo() {
    let text = """
    \(storeInfo.name)
    \(storeInfo.address)
    Phone: \(storeInfo.primaryPhone)
    """
    let activity = UIActivityViewController(
        activityItems: [text],
        applicationActivities: nil
    )
    // ... present
}
```

## Summary

✅ **Complete Implementation**: All features working as designed
✅ **Production Ready**: Error handling, loading states, fallbacks
✅ **Best Practices**: MVVM, async/await, reactive state, repository pattern
✅ **Maintainable**: Clean code, good structure, comprehensive documentation
✅ **Extensible**: Easy to add new features and customize

The Store Information feature is fully implemented and ready for production use! 🎉
