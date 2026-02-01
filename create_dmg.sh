#!/bin/bash

# Configuration
APP_NAME="ScreenOCR"
APP_BUNDLE="${APP_NAME}.app"
DMG_NAME="${APP_NAME}_Installer.dmg"
VOL_NAME="${APP_NAME}"
STAGING_DIR="./dmg_staging"

# Clean up previous builds
rm -rf "$STAGING_DIR"
rm -f "$DMG_NAME"

# Create staging directory
mkdir -p "$STAGING_DIR"

# Copy App to staging
if [ -d "$APP_BUNDLE" ]; then
    echo "Copying $APP_BUNDLE to staging area..."
    cp -r "$APP_BUNDLE" "$STAGING_DIR/"
else
    echo "Error: $APP_BUNDLE not found. Please run bundle_app.sh first."
    exit 1
fi

# Create Applications symlink
echo "Creating Applications link..."
ln -s /Applications "$STAGING_DIR/Applications"

# Add Volume Icon (if exists)
ICON_PATH="$APP_BUNDLE/Contents/Resources/AppIcon.icns"
if [ -f "$ICON_PATH" ]; then
    echo "Adding Volume Icon..."
    cp "$ICON_PATH" "$STAGING_DIR/.VolumeIcon.icns"
    # Set the custom icon attribute on the folder (requires Xcode command line tools or similar)
    if command -v SetFile &> /dev/null; then
        SetFile -c icnC "$STAGING_DIR/.VolumeIcon.icns"
        SetFile -a C "$STAGING_DIR"
    else
        echo "Warning: SetFile not found. Icon might not appear."
    fi
fi

# Create DMG using hdiutil
echo "Creating DMG..."
hdiutil create -volname "$VOL_NAME" -srcfolder "$STAGING_DIR" -ov -format UDZO "$DMG_NAME"

# Clean up staging
rm -rf "$STAGING_DIR"

# Optional: Set the icon for the .dmg file itself using the same icns
# This uses a python script or similar if SetFile isn't enough, but SetFile -a C works if resources are present.
# Ideally, we just assume the volume icon is enough.
# However, to be thorough, let's try to set the file icon if we have the tools.
if [ -f "$ICON_PATH" ] && command -v SetFile &> /dev/null; then
   # Replacing the icon of a file programmatically without 'fileicon' tool is complex in bash 
   # without modifying resource forks directly. 
   # We will accept Volume Icon as the primary request.
   echo "Volume icon set."
fi

# Apply icon to the DMG file itself using Swift
echo "Applying icon to DMG file..."
if [ -f "app_icon.png" ]; then
    swift set_icon.swift "app_icon.png" "$DMG_NAME"
fi

echo "Success! Created $DMG_NAME"
