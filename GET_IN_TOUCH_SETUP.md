# Get in Touch - Setup Guide

## ✅ Implementation Complete

A production-ready "Get in Touch" feature has been implemented that:
- Fetches store data from Firestore dynamically
- Opens WhatsApp with pre-filled phone number and message
- Falls back to browser if WhatsApp is not installed
- Handles errors gracefully without crashing

---

## 📁 Files Created

### 1. **Models/StoreInfo.swift**
- Model representing store information from Firestore
- Includes smart phone number selection logic
- Provides message fallback handling

### 2. **Services/StoreInfoService.swift**
- Fetches store info from `store_info/main_store` in Firestore
- Implements caching (1 hour validity)
- Handles missing data gracefully

### 3. **Services/WhatsAppService.swift**
- Opens WhatsApp with deep link
- Falls back to browser (WhatsApp Web) if app not installed
- URL-encodes messages properly
- Crash-free implementation

### 4. **ViewModels/GetInTouchViewModel.swift**
- Handles business logic
- Manages loading states
- Provides error feedback

### 5. **Updated: Views/Common/NativeSidebarView.swift**
- Integrated "Get In Touch" button
- Shows loading indicator
- Displays errors via alert

---

## 🔧 Required Xcode Configuration

### Add WhatsApp URL Scheme to Info.plist

You need to add WhatsApp to the list of URL schemes your app can query:

**Option 1: Using Xcode UI**
1. Open your Xcode project
2. Select the **jewellery** target
3. Go to the **Info** tab
4. Find **Custom iOS Target Properties**
5. Add a new entry:
   - **Key**: `LSApplicationQueriesSchemes`
   - **Type**: Array
6. Add an item to the array:
   - **Type**: String
   - **Value**: `whatsapp`

**Option 2: Using Info.plist file (if you have one)**
```xml
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>whatsapp</string>
</array>
```

**Without this step**, the app cannot detect if WhatsApp is installed and will always open the browser.

---

## 🎯 How It Works

### User Flow
1. User taps **"Get In Touch"** from sidebar menu
2. App shows loading indicator
3. App fetches store info from Firestore
4. App extracts phone number using priority:
   - `whatsappNumber` (if present)
   - else `phone_primary` (if present)
   - else default: `"8194963318"`
5. App extracts message:
   - `whatsappMessage` (if present)
   - else default: "Hi! I'm interested in your jewelry collection. Please help me with more details."
6. App opens WhatsApp (or browser if not installed)
7. Sidebar closes automatically

### Phone Number Selection Logic
```swift
// Priority order
1. whatsappNumber from Firestore
2. phone_primary from Firestore
3. Fallback: "8194963318"
```

### Message Selection Logic
```swift
// Priority order
1. whatsappMessage from Firestore
2. Default: "Hi! I'm interested in your jewelry collection..."
```

---

## 📊 Firestore Structure Expected

### Collection: `store_info`
### Document: `main_store`

```json
{
  "whatsappNumber": "919876543211",
  "phone_primary": "+91-1234567770",
  "whatsappMessage": "Hi! I'm interested in your jewelry collection. Please help me with more details.",
  "name": "Gagan Jewellers Pvt Ltd",
  "address": "123 Mall Road, Near City Center, Patiala, Punjab 147001",
  "email": "contact@gaganjewellers.com"
}
```

**All fields are optional**. The app will use smart defaults.

---

## 🎨 UI Changes

### Sidebar Menu - "More" Section
- **Button**: "Get In Touch" with message icon
- **Loading State**: Shows small spinner next to text while fetching
- **Error State**: Shows alert if connection fails
- **Success**: Opens WhatsApp and closes sidebar

---

## 🔒 Error Handling

### Graceful Degradation
1. **Firestore fetch fails** → Shows error alert
2. **WhatsApp not installed** → Opens WhatsApp Web in browser
3. **Invalid phone number** → Uses fallback number
4. **Missing message** → Uses default message
5. **Network error** → Shows user-friendly error message

### No Crashes
- All operations wrapped in try-catch
- Main thread protected with @MainActor
- Background tasks use Task.detached when appropriate
- URL encoding validated before opening

---

## 🧪 Testing Scenarios

### Test 1: Normal Flow (WhatsApp Installed)
1. Tap "Get In Touch"
2. Should show brief loading
3. Should open WhatsApp app
4. Message should be pre-filled
5. Phone number should be correct

### Test 2: WhatsApp Not Installed
1. Tap "Get In Touch" (on device/simulator without WhatsApp)
2. Should open default browser
3. Should show WhatsApp Web
4. Message and number should be pre-filled

### Test 3: Network Error
1. Turn off network
2. Tap "Get In Touch"
3. Should show error alert
4. Should not crash

### Test 4: Missing Firestore Data
1. Remove `whatsappNumber` and `phone_primary` from Firestore
2. Tap "Get In Touch"
3. Should use fallback number: "8194963318"
4. Should still work

### Test 5: Custom Message
1. Set `whatsappMessage` in Firestore to custom text
2. Tap "Get In Touch"
3. WhatsApp should open with custom message

---

## 📱 WhatsApp URL Formats

### App Deep Link
```
whatsapp://send?phone=919876543211&text=Hello%20World
```

### Web Link (Fallback)
```
https://wa.me/919876543211?text=Hello%20World
```

**Phone Format**: 
- Must be digits only
- Include country code without "+"
- Example: "919876543211" for India

**Message Encoding**:
- Spaces become `%20`
- Special characters are URL-encoded
- Handled automatically by the service

---

## 🚀 Deployment Checklist

- [x] Code implemented and compiles
- [x] No hardcoded values in views
- [x] Firestore logic separated into service
- [x] Error handling comprehensive
- [x] Main thread safety ensured
- [ ] **LSApplicationQueriesSchemes added to Info.plist** (YOU MUST DO THIS)
- [ ] Firestore data verified in Firebase Console
- [ ] Tested on physical device with WhatsApp
- [ ] Tested on simulator without WhatsApp

---

## 🎓 Code Quality

### ✅ Best Practices Followed
- Clean Architecture (Model-Service-ViewModel-View)
- Dependency Injection via @StateObject
- Async/await for network operations
- @MainActor for UI updates
- Proper error propagation
- URL encoding for safety
- Caching to reduce Firestore reads
- Graceful degradation

### ✅ Apple Guidelines
- Native SwiftUI
- No blocking operations
- Safe URL handling
- Proper state management
- User-friendly error messages

---

## 🔄 Future Enhancements (Optional)

1. **Analytics**: Track WhatsApp open rate
2. **Multiple Numbers**: Support different numbers for different services
3. **Business Hours**: Show if store is open/closed
4. **Quick Messages**: Predefined message templates
5. **Call Option**: Also add phone call functionality
6. **Localization**: Support multiple languages

---

## 📞 Troubleshooting

### Issue: "Get In Touch" button does nothing
**Solution**: Check Xcode console for errors. Likely Firestore permissions issue.

### Issue: Always opens browser, never WhatsApp app
**Solution**: Add `whatsapp` to `LSApplicationQueriesSchemes` in Info.plist

### Issue: Shows error alert every time
**Solution**: 
1. Check network connection
2. Verify Firestore collection exists: `store_info/main_store`
3. Check Firestore rules allow read access

### Issue: Wrong phone number being used
**Solution**: 
1. Check Firestore document has `whatsappNumber` field
2. Check field is type String, not Number
3. Verify format: digits only, with country code

### Issue: Message appears garbled in WhatsApp
**Solution**: This shouldn't happen as we use proper URL encoding. Check Firestore message for special characters.

---

## 💡 Quick Reference

### Update Phone Number
```javascript
// In Firebase Console
store_info/main_store
{
  "whatsappNumber": "919876543211"
}
```

### Update Default Message
```javascript
// In Firebase Console
store_info/main_store
{
  "whatsappMessage": "Your custom message here"
}
```

### Clear Cache (Force Refresh)
```swift
// Call this if you update Firestore and want immediate effect
StoreInfoService.shared.clearCache()
```

---

## ✅ Status

**Implementation: COMPLETE**

**Ready for Production: YES** (after adding URL scheme to Info.plist)

**Tested: Ready for testing**

---

## 📝 Notes

- Phone numbers are automatically cleaned (non-digits removed)
- Messages are automatically URL-encoded
- WhatsApp detection is instant (no delay)
- Cache prevents excessive Firestore reads
- All operations are async and non-blocking
- Error messages are user-friendly, not technical

**Status: ✅ IMPLEMENTATION COMPLETE - REQUIRES INFO.PLIST UPDATE**
