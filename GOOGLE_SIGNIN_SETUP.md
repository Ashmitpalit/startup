# Google Sign-In Setup Checklist

## ✅ What's Already Done:

1. ✅ Firebase dependencies added (`firebase_core`, `firebase_auth`, `google_sign_in`)
2. ✅ Google Services plugin configured in `build.gradle.kts`
3. ✅ `google-services.json` added to `android/app/`
4. ✅ Internet permission added to AndroidManifest
5. ✅ Auth provider created with Google Sign-In logic
6. ✅ Auth screen UI created
7. ✅ Sign-out button added to landing page

## 🔧 What You Need To Do:

### 1. Firebase Console Setup:
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Select your project
   - Enable **Authentication** → **Sign-in method** → Enable **Google**
   - Make sure your `google-services.json` matches your Firebase project

### 2. SHA-1 Certificate Fingerprint:
   Your debug SHA-1 is: **`F9:B0:8E:85:22:6F:E2:9B:1C:4C:73:AB:79:35:92:D0:30:75:0C:77`**
   
   - Go to Firebase Console → Project Settings → Your Android App
   - Add this SHA-1 fingerprint to your app configuration
   - This is required for Google Sign-In to work

### 3. For Release Build:
   When you build for release, you'll need to:
   - Generate a release keystore
   - Get the SHA-1 from your release keystore:
     ```bash
     keytool -list -v -keystore your-release-key.jks -alias your-key-alias
     ```
   - Add that SHA-1 to Firebase Console as well

### 4. Test Google Sign-In:
   - Run the app
   - You should see the Auth Screen with "Continue with Google" button
   - Tap it and select your Google account
   - You should be redirected to the landing page
   - Use the logout icon in the header to sign out

## 📱 Current Package Name:
**`com.example.startup`**

Make sure this matches the package name in your `google-services.json` file!

## 🚨 Troubleshooting:

If Google Sign-In doesn't work:
1. Check that SHA-1 is added in Firebase Console
2. Verify `google-services.json` is in `android/app/` directory
3. Make sure Google Sign-In is enabled in Firebase Console
4. Check app logs for any error messages
5. Ensure your package name matches exactly

