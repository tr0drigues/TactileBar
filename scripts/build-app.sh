#!/usr/bin/env bash
set -euo pipefail

APP_NAME="TactileBar"
BUNDLE_ID="studio.tactile.TactileBar"
VERSION="1.0.0"
BUILD_DIR=".build/release"
APP_BUNDLE="${APP_NAME}.app"

echo "==> Building ${APP_NAME} (Release)..."
mkdir -p "${BUILD_DIR}"
CACHE_DIR="${TMPDIR:-/tmp}/tactilebar-swift-cache"
mkdir -p "${CACHE_DIR}"

if ! swift build -c release 2>/dev/null; then
    echo "==> Using direct swiftc Release pipeline (CommandLineTools mode)..."
    swiftc -module-cache-path "${CACHE_DIR}" -O -swift-version 6 \
        -emit-module -emit-library -static \
        -module-name TactileCore \
        -o "${BUILD_DIR}/libTactileCore.a" \
        -emit-module-path "${BUILD_DIR}/TactileCore.swiftmodule" \
        Sources/TactileCore/Configuration/*.swift \
        Sources/TactileCore/Contracts/*.swift \
        Sources/TactileCore/Registry/*.swift \
        Sources/TactileCore/Services/*.swift

    swiftc -module-cache-path "${CACHE_DIR}" -O -swift-version 6 \
        -I "${BUILD_DIR}" \
        -emit-module -emit-library -static \
        -module-name SystemAdapters \
        -o "${BUILD_DIR}/libSystemAdapters.a" \
        -emit-module-path "${BUILD_DIR}/SystemAdapters.swiftmodule" \
        Sources/SystemAdapters/*.swift

    swiftc -module-cache-path "${CACHE_DIR}" -O -swift-version 6 \
        -I "${BUILD_DIR}" \
        -emit-module -emit-library -static \
        -module-name SwitchCatalog \
        -o "${BUILD_DIR}/libSwitchCatalog.a" \
        -emit-module-path "${BUILD_DIR}/SwitchCatalog.swiftmodule" \
        Sources/SwitchCatalog/*.swift

    swiftc -module-cache-path "${CACHE_DIR}" -O -swift-version 6 \
        -I "${BUILD_DIR}" \
        -emit-module -emit-library -static \
        -module-name TactileUI \
        -o "${BUILD_DIR}/libTactileUI.a" \
        -emit-module-path "${BUILD_DIR}/TactileUI.swiftmodule" \
        Sources/TactileUI/Theme/*.swift \
        Sources/TactileUI/Components/*.swift \
        Sources/TactileUI/Windows/*.swift

    swiftc -module-cache-path "${CACHE_DIR}" -O -swift-version 6 \
        -parse-as-library \
        -I "${BUILD_DIR}" \
        "${BUILD_DIR}/libTactileCore.a" \
        "${BUILD_DIR}/libSystemAdapters.a" \
        "${BUILD_DIR}/libSwitchCatalog.a" \
        "${BUILD_DIR}/libTactileUI.a" \
        -o "${BUILD_DIR}/${APP_NAME}" \
        Sources/TactileBarApp/*.swift
fi

echo "==> Assembling ${APP_BUNDLE} bundle..."
rm -rf "${APP_BUNDLE}"
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

cp "${BUILD_DIR}/${APP_NAME}" "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"

cat > "${APP_BUNDLE}/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_ID}</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSAppleEventsUsageDescription</key>
    <string>TactileBar precisa de permissão de automação para alternar o Modo Escuro, Finder, Lixeira e reprodutores de mídia.</string>
</dict>
</plist>
EOF

echo "==> Applying Ad-Hoc signature..."
codesign --force --deep --sign - "${APP_BUNDLE}"

echo "==> Done: ${APP_BUNDLE} created successfully."
