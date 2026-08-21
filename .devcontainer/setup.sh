#!/bin/bash

set -e

echo "======================================"
echo " GroupFlow Flutter Environment Setup"
echo "======================================"

FLUTTER_DIR="/opt/flutter"

if [ ! -d "$FLUTTER_DIR" ]; then
    echo "Cloning Flutter stable..."

    sudo git clone \
        https://github.com/flutter/flutter.git \
        -b stable \
        "$FLUTTER_DIR"
fi

sudo chown -R codespace:codespace "$FLUTTER_DIR"

echo 'export PATH="/opt/flutter/bin:$PATH"' >> "$HOME/.bashrc"

export PATH="/opt/flutter/bin:$PATH"

echo "Flutter version:"
flutter --version

echo "Disabling Flutter analytics..."
flutter config --no-analytics

echo "Getting project dependencies..."
flutter pub get

echo "Running Flutter doctor..."
flutter doctor

echo "======================================"
echo " GroupFlow environment ready!"
echo "======================================"

