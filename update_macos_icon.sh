#!/bin/bash

# Convert the homoku.png to all required macOS icon sizes
ICON_FILE="assets/icon/homoku.png"
MACOS_DIR="macos/Runner/Assets.xcassets/AppIcon.appiconset"

if [ ! -f "$ICON_FILE" ]; then
    echo "Error: $ICON_FILE not found"
    exit 1
fi

# Create temporary directory for icon processing
TEMP_DIR="/tmp/homoku_icon"
mkdir -p "$TEMP_DIR"

# Convert to all required sizes
sizes=(16 32 64 128 256 512 1024)
for size in "${sizes[@]}"; do
    output_file="$TEMP_DIR/app_icon_${size}.png"
    
    # Use sips (macOS built-in image processor) to resize
    if command -v sips &> /dev/null; then
        sips -z $size $size "$ICON_FILE" --out "$output_file"
        echo "Created $output_file"
    else
        echo "Warning: sips not found, skipping icon generation"
        exit 1
    fi
    
    # Copy to macOS app icon directory
    if [ $size -eq 1024 ]; then
        cp "$output_file" "$MACOS_DIR/app_icon_1024.png"
    elif [ $size -eq 512 ]; then
        cp "$output_file" "$MACOS_DIR/app_icon_512.png"
    elif [ $size -eq 256 ]; then
        cp "$output_file" "$MACOS_DIR/app_icon_256.png"
    elif [ $size -eq 128 ]; then
        cp "$output_file" "$MACOS_DIR/app_icon_128.png"
    elif [ $size -eq 64 ]; then
        cp "$output_file" "$MACOS_DIR/app_icon_64.png"
    elif [ $size -eq 32 ]; then
        cp "$output_file" "$MACOS_DIR/app_icon_32.png"
    elif [ $size -eq 16 ]; then
        cp "$output_file" "$MACOS_DIR/app_icon_16.png"
    fi
done

echo "macOS icons updated successfully"
echo "Please clean and rebuild the macOS app:"