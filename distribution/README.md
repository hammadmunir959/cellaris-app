# MBM Distribution System

This folder contains a complete toolchain to build, package, and distribute the MBM Application.

## 📂 Structure
- `build_all.sh`: AUTOMATION SCRIPT. Runs Release builds for Windows, Linux, and Android.
- `installers/`:
  - `windows/`: Contains `mbm_setup.iss` (Inno Setup Script).
  - `linux/`: Contains `package_linux.sh` (AppImage generator).
  - `android/`: Signing guide.
- `web/`: Contains `index.html` (Download page).
- `output/`: Where final artifacts (Exe, AppImage) will be placed.

---

## 🚀 Step 1: Build Binaries
Run the master build script to generate raw release binaries for all platforms.
```bash
bash build_all.sh
```
*Note: This script will automatically create the Android platform project if it's missing.*

---

## 📦 Step 2: Package Installers

### Windows (.exe)
**Prerequisite:** Install [Inno Setup](https://jrsoftware.org/isdl.php).
1. Open `installers/windows/mbm_setup.iss`.
2. Compile the script.
3. The output `MBM_Setup_Windows.exe` will appear in `distribution/output/`.

### Linux (AppImage)
**Prerequisite:** None (Script handles it).
1. Run the packaging script:
```bash
bash installers/linux/package_linux.sh
```
2. The output `MBM_Linux.AppImage` will appear in `distribution/output/`.

### Android (.apk)
1. Follow the signing guide in `installers/android/README.md`.
2. The signed APK will be at `../build/app/outputs/flutter-apk/app-release.apk`.

---

## 🌐 Step 3: Publish
1. Create a **New Release** on your GitHub Repository.
2. Upload the 3 files:
   - `MBM_Setup_Windows.exe`
   - `MBM_Linux.AppImage`
   - `app-release.apk`
3. Edit `web/index.html` and replace `YOUR_USERNAME` with your GitHub username.
4. Deploy `web/index.html` to any static host (GitHub Pages, Netlify, Firebase).

✅ **Done!** Users can now visit your site and download the app.
