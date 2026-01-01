#!/bin/bash
set -e
cd "$(dirname "$0")"

# 1. Download linuxdeploy if valid
if [ ! -f "linuxdeploy-x86_64.AppImage" ]; then
    echo "Downloading linuxdeploy..."
    wget https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage
    chmod +x linuxdeploy-x86_64.AppImage
fi

# 2. Prepare AppDir
echo "Preparing AppDir..."
rm -rf AppDir
mkdir -p AppDir/usr/bin
mkdir -p AppDir/usr/share/icons/hicolor/256x256/apps
mkdir -p AppDir/usr/share/applications
mkdir -p ../../output

# 3. Copy Build Files
PROJECT_ROOT="../../.."
BUILD_DIR="$PROJECT_ROOT/build/linux/x64/release/bundle"

if [ ! -d "$BUILD_DIR" ]; then
    echo "Error: Build directory not found. Please run ../build_all.sh first."
    exit 1
fi

echo "Copying binary and assets..."
cp -r "$BUILD_DIR/"* AppDir/usr/bin/

# 4. Create .desktop file
cat > AppDir/usr/share/applications/mbm_app.desktop <<EOF
[Desktop Entry]
Type=Application
Name=MBM Solutions
Exec=mbm_app
Icon=mbm_app
Categories=Office;Finance;
Terminal=false
EOF

# 5. Create Dummy Icon (User should replace)
# Try to find an icon in the project, else create dummy
if [ -f "$PROJECT_ROOT/assets/icon.png" ]; then
    cp "$PROJECT_ROOT/assets/icon.png" AppDir/usr/share/icons/hicolor/256x256/apps/mbm_app.png
else
    touch AppDir/usr/share/icons/hicolor/256x256/apps/mbm_app.png
fi

# 6. Run LinuxDeploy
echo "Generating AppImage..."
./linuxdeploy-x86_64.AppImage --appdir AppDir --output appimage

# 7. Move Output (Handle variable output name)
find . -name "MBM_Solutions*.AppImage" -exec mv {} ../../output/MBM_Linux.AppImage \;

echo "Success! AppImage created at distribution/output/MBM_Linux.AppImage"
