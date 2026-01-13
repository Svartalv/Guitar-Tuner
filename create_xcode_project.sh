#!/bin/bash

# Helper script to guide Xcode project creation
# Note: This script provides instructions - you'll need to create the project in Xcode

echo "========================================="
echo "Guitar Tuner - Xcode Project Setup"
echo "========================================="
echo ""
echo "Please follow these steps in Xcode:"
echo ""
echo "1. Open Xcode"
echo "2. File → New → Project"
echo "3. Choose 'App' template → Next"
echo "4. Fill in:"
echo "   - Product Name: Guitar Tuner"
echo "   - Interface: SwiftUI"
echo "   - Language: Swift"
echo "5. Save the project in: $(pwd)"
echo "6. After creation, add all .swift files from this directory"
echo ""
echo "Or use the automated setup below..."
echo ""

# Check if we can find Xcode
if [ -d "/Applications/Xcode.app" ]; then
    echo "Xcode found! Opening..."
    open -a Xcode
    echo ""
    echo "Once Xcode opens:"
    echo "1. Create a new App project (SwiftUI)"
    echo "2. Save it in this directory"
    echo "3. Add all the .swift files from this folder"
else
    echo "Xcode not found in /Applications/"
    echo "Please install Xcode from the App Store first"
fi


