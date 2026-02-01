#!/bin/bash
echo "Closing ScreenOCR..."
pkill ScreenOCR

echo "Copying new version..."
rm -rf /Applications/ScreenOCR.app
cp -r ScreenOCR.app /Applications/

echo "Clearing quarantine..."
xattr -cr /Applications/ScreenOCR.app

echo "Launching..."
open /Applications/ScreenOCR.app

echo "Done! Please try to capture text again."
