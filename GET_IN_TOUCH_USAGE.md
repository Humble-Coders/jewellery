# Get in Touch - Quick Usage Guide

## 🚀 Quick Start

The "Get In Touch" feature is **already integrated** and ready to use! Just complete one setup step:

### ⚠️ REQUIRED: Add WhatsApp URL Scheme

1. Open Xcode
2. Select **jewellery** target
3. Go to **Info** tab
4. Find **Custom iOS Target Properties**
5. Add key: `LSApplicationQueriesSchemes` (type: Array)
6. Add array item: `whatsapp` (type: String)

**That's it!** The feature will now work automatically.

---

## 📱 How Users Use It

1. Open app sidebar menu
2. Scroll to **"More"** section
3. Tap **"Get In Touch"**
4. WhatsApp opens with pre-filled message
5. User can edit message or send directly

---

## 🎯 For Developers

### Updating Phone Number

**In Firebase Console:**
```
Collection: store_info
Document: main_store
Field: whatsappNumber = "919876543211"
```

### Updating Default Message

**In Firebase Console:**
```
Collection: store_info
Document: main_store
Field: whatsappMessage = "Your custom message here"
```

### Using in Other Views

```swift
import SwiftUI

struct MyView: View {
    @StateObject private var getInTouch = GetInTouchViewModel()
    
    var body: some View {
        Button("Contact Us") {
            getInTouch.openWhatsApp()
        }
    }
}
```

### Direct WhatsApp Opening (Without Firestore)

```swift
import SwiftUI

struct MyView: View {
    var body: some View {
        Button("WhatsApp") {
            WhatsAppService.shared.openWhatsApp(
                phoneNumber: "919876543211",
                message: "Hello from app!"
            )
        }
    }
}
```

---

## 🔍 Architecture Overview

```
User taps button
    ↓
GetInTouchViewModel.openWhatsApp()
    ↓
StoreInfoService.fetchStoreInfo()
    ↓
WhatsAppService.openWhatsApp(phone, message)
    ↓
Opens WhatsApp (or browser)
```

---

## 🎨 Customization

### Change Fallback Phone Number

**In:** `Models/StoreInfo.swift`
```swift
var preferredWhatsAppNumber: String {
    // ... existing logic ...
    return "8194963318" // ← Change this
}
```

### Change Default Message

**In:** `Models/StoreInfo.swift`
```swift
var whatsAppMessageText: String {
    // ... existing logic ...
    return "Your new default message here" // ← Change this
}
```

### Change Cache Duration

**In:** `Services/StoreInfoService.swift`
```swift
private let cacheValidityDuration: TimeInterval = 3600 // 1 hour
// Change to 1800 for 30 minutes, 7200 for 2 hours, etc.
```

### Change Button Icon

**In:** `Views/Common/NativeSidebarView.swift`
```swift
Label("Get In Touch", systemImage: "message.fill")
// Change icon: "phone.fill", "bubble.left.fill", etc.
```

---

## 🧪 Testing

### Test on Simulator (WhatsApp not installed)
1. Run app in simulator
2. Tap "Get In Touch"
3. Safari should open with WhatsApp Web

### Test on Device (WhatsApp installed)
1. Run app on physical device with WhatsApp
2. Tap "Get In Touch"
3. WhatsApp app should open directly

### Test Error Handling
1. Turn off internet
2. Tap "Get In Touch"
3. Should show error alert
4. Turn on internet, try again - should work

---

## 🔧 Debugging

### Enable Debug Logs

Check Xcode console for these messages:

**Success:**
```
✅ Opened WhatsApp app
📱 Opening WhatsApp to 919876543211
```

**Fallback:**
```
✅ Opened WhatsApp Web in browser
```

**Error:**
```
❌ Error opening WhatsApp: [error details]
⚠️ Failed to open WhatsApp app
```

### Common Issues

**Issue**: Nothing happens when tapping button
- Check Xcode console for error messages
- Verify Firestore data exists
- Check network connection

**Issue**: Always opens browser
- Add `whatsapp` to Info.plist LSApplicationQueriesSchemes
- Rebuild app after adding

**Issue**: Wrong number displayed
- Check Firestore `whatsappNumber` field
- Ensure it's type String, not Number
- Use format: "919876543211" (digits only, with country code)

---

## 📊 Firestore Structure

### Minimum Required
```json
{
  "phone_primary": "9876543211"
}
```

### Full Structure
```json
{
  "whatsappNumber": "919876543211",
  "phone_primary": "+91-1234567770",
  "phone_secondary": "+91-9876543211",
  "whatsappMessage": "Hi! I'm interested in your jewelry collection.",
  "name": "Gagan Jewellers Pvt Ltd",
  "address": "123 Mall Road, Patiala, Punjab",
  "email": "contact@gaganjewellers.com",
  "store_hours": {
    "monday": "10:00 AM - 8:00 PM",
    "sunday": "10:00 AM - 05:00 PM"
  }
}
```

---

## 💡 Pro Tips

### 1. Update Message Based on Context
```swift
// Create custom message dynamically
let customMessage = "I'm interested in \(productName). Can you help?"
WhatsAppService.shared.openWhatsApp(
    phoneNumber: "919876543211",
    message: customMessage
)
```

### 2. Check WhatsApp Availability
```swift
if WhatsAppService.shared.isWhatsAppInstalled {
    print("User has WhatsApp")
} else {
    print("User doesn't have WhatsApp - will open browser")
}
```

### 3. Force Refresh Store Info
```swift
// After updating Firestore
StoreInfoService.shared.clearCache()

// Next fetch will get fresh data
getInTouchViewModel.openWhatsApp()
```

---

## 🎯 Best Practices

### ✅ Do's
- Keep messages concise and professional
- Include country code in phone numbers
- Test on both simulator and device
- Update Firestore values through Firebase Console
- Check console logs during development

### ❌ Don'ts
- Don't include "+" in phone numbers (use digits only)
- Don't hardcode phone numbers in views
- Don't forget to add URL scheme to Info.plist
- Don't block the main thread (already handled)
- Don't show technical errors to users (already handled)

---

## 📞 Quick Reference

### Services Available

```swift
// Fetch store info
let info = try await StoreInfoService.shared.fetchStoreInfo()

// Open WhatsApp
WhatsAppService.shared.openWhatsApp(
    phoneNumber: "919876543211",
    message: "Hello!"
)

// Check WhatsApp installed
let hasWhatsApp = WhatsAppService.shared.isWhatsAppInstalled

// Clear cache
StoreInfoService.shared.clearCache()
```

### ViewModels Available

```swift
// For "Get In Touch" functionality
@StateObject private var getInTouch = GetInTouchViewModel()
getInTouch.openWhatsApp()

// Check loading state
if getInTouch.isLoading { 
    ProgressView() 
}

// Check for errors
if let error = getInTouch.errorMessage {
    Text(error)
}
```

---

## ✅ Checklist

**Before Testing:**
- [ ] Added `whatsapp` to LSApplicationQueriesSchemes in Info.plist
- [ ] Verified Firestore `store_info/main_store` document exists
- [ ] Verified `whatsappNumber` or `phone_primary` field exists
- [ ] Rebuilt app after Info.plist changes

**During Testing:**
- [ ] Tested on simulator (browser fallback)
- [ ] Tested on device with WhatsApp (app opens)
- [ ] Tested with no network (error handling)
- [ ] Verified correct phone number opens
- [ ] Verified correct message appears

**After Testing:**
- [ ] Confirmed no crashes
- [ ] Confirmed error messages are user-friendly
- [ ] Confirmed sidebar closes after tap
- [ ] Confirmed loading indicator appears briefly

---

## 🎉 You're All Set!

The "Get In Touch" feature is ready to use. Just add the URL scheme to Info.plist and test!

**Need help?** Check `GET_IN_TOUCH_SETUP.md` for detailed documentation.
