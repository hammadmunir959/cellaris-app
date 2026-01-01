# Android Distribution Guide

To release a production APK, you must sign it with a keystore.

## 1. Generate Keystore
Run this command in your terminal (keep the file safe!):
```bash
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

## 2. Configure `key.properties`
Create a file named `android/key.properties` in your project root:
```properties
storePassword=<password from step 1>
keyPassword=<password from step 1>
keyAlias=upload
storeFile=../upload-keystore.jks
```

## 3. Configure `android/app/build.gradle`
Ensure your `build.gradle` uses the keystore configuration for release builds. (Flutter standard template usually needs modification to read `key.properties`).

## 4. Build
After configuration, run:
```bash
flutter build apk --release
```
The output will be at: `build/app/outputs/flutter-apk/app-release.apk`
