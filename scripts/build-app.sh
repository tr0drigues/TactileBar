#!/usr/bin/env bash
set -euo pipefail

APP_NAME="TactileBar"
BUNDLE_ID="studio.tactile.TactileBar"
VERSION="1.1.0"
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

# Generate custom AppIcon.icns via Python/Pillow + iconutil if available
ICONSET_DIR="${CACHE_DIR}/AppIcon.iconset"
rm -rf "${ICONSET_DIR}"
mkdir -p "${ICONSET_DIR}"

python3 - "${ICONSET_DIR}" <<'PYEOF' 2>/dev/null || true
import math, os, sys
from PIL import Image, ImageDraw

out_dir = sys.argv[1]
size = 1024
img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
draw = ImageDraw.Draw(img)

pad = int(size * 0.08)
draw.rounded_rectangle([pad, pad, size - pad, size - pad], radius=int(size * 0.19), fill=(11, 13, 16, 255), outline=(64, 76, 98, 255), width=14)

cx, cy = size // 2, size // 2
r_outer = int(size * 0.35)
draw.ellipse([cx - r_outer, cy - r_outer, cx + r_outer, cy + r_outer], fill=(20, 25, 35, 255), outline=(64, 76, 98, 255), width=10)

palette = [(245, 158, 11, 255), (56, 189, 248, 255), (236, 232, 223, 255), (16, 185, 129, 255), (255, 87, 34, 255)]
r_sec = int(size * 0.27)
bbox = [cx - r_sec, cy - r_sec, cx + r_sec, cy + r_sec]
step = 360.0 / 26.0
for i in range(26):
    a1 = i * step - 90.0
    a2 = a1 + step * 0.72
    draw.arc(bbox, start=a1, end=a2, fill=palette[i % len(palette)], width=38)

r_core = int(size * 0.14)
draw.ellipse([cx - r_core, cy - r_core, cx + r_core, cy + r_core], fill=(11, 13, 16, 255), outline=(245, 158, 11, 255), width=12)
draw.line([cx, cy, cx + int(r_outer * 0.62), cy - int(r_outer * 0.52)], fill=(245, 158, 11, 255), width=22)
r_pin = int(size * 0.028)
draw.ellipse([cx - r_pin, cy - r_pin, cx + r_pin, cy + r_pin], fill=(236, 232, 223, 255))

specs = [
    ("icon_16x16.png", 16), ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32), ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128), ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256), ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512), ("icon_512x512@2x.png", 1024),
]
for name, dim in specs:
    img.resize((dim, dim), Image.Resampling.LANCZOS).save(os.path.join(out_dir, name))
PYEOF

if [ -f "${ICONSET_DIR}/icon_512x512@2x.png" ]; then
    iconutil -c icns "${ICONSET_DIR}" -o "${APP_BUNDLE}/Contents/Resources/AppIcon.icns" || true
fi

cat > "${APP_BUNDLE}/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
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
    <key>NSBluetoothAlwaysUsageDescription</key>
    <string>TactileBar utiliza o Bluetooth para conectar e desconectar rapidamente seus fones e controles pareados.</string>
</dict>
</plist>
EOF

echo "==> Applying Ad-Hoc signature..."
codesign --force --deep --sign - "${APP_BUNDLE}"

echo "==> Done: ${APP_BUNDLE} created successfully."
