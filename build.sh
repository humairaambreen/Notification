#!/bin/bash
# Builds Notification.app from the Swift sources.   Usage: bash build.sh
set -e
cd "$(dirname "$0")"

if ! command -v swiftc >/dev/null 2>&1; then
  echo "swiftc not found. Install Apple's command line tools first:  xcode-select --install"
  exit 1
fi

APP="Notification.app"
LOG="$(mktemp -t notification-build)"
rm -rf "$APP" "CapsBlink.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

compile() {
  swiftc -O -swift-version 5 Sources/*.swift -o "$APP/Contents/MacOS/Notification" \
    -framework Cocoa -framework SwiftUI -framework IOKit -framework ServiceManagement -framework AVFoundation "$@"
}

echo "Compiling..."
if ! compile >"$LOG" 2>&1; then
  SDK26=$(ls -d /Library/Developer/CommandLineTools/SDKs/MacOSX26*.sdk 2>/dev/null | sort -V | tail -1 || true)
  if [ -n "$SDK26" ]; then
    echo "First attempt failed; retrying with $SDK26 ..."
    if ! compile -sdk "$SDK26" >"$LOG" 2>&1; then
      cat "$LOG"
      exit 1
    fi
  else
    cat "$LOG"
    exit 1
  fi
fi

# Generate AppIcon.icns with a crisp bell notification icon
ICONSET="$(mktemp -d -t notification-icon).iconset"
mkdir -p "$ICONSET"
swift -e '
import Cocoa

let outDir = CommandLine.arguments[1]
let sizes: [(String, Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
]

for (name, px) in sizes {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: px,
        pixelsHigh: px,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

    let s = CGFloat(px)
    let inset = s * 0.08
    let rect = NSRect(x: inset, y: inset, width: s - inset * 2, height: s - inset * 2)
    let radius = rect.width * 0.225
    let bg = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
    NSColor(calibratedWhite: 0.10, alpha: 1.0).setFill()
    bg.fill()

    let cfg = NSImage.SymbolConfiguration(pointSize: s * 0.46, weight: .bold)
        .applying(.init(paletteColors: [.white]))
    if let bell = NSImage(systemSymbolName: "bell.fill", accessibilityDescription: nil)?
        .withSymbolConfiguration(cfg) {
        let bw = bell.size.width
        let bh = bell.size.height
        let bx = (s - bw) / 2.0
        let by = (s - bh) / 2.0
        bell.draw(in: NSRect(x: bx, y: by, width: bw, height: bh))
    }

    NSGraphicsContext.restoreGraphicsState()
    if let png = rep.representation(using: .png, properties: [:]) {
        try? png.write(to: URL(fileURLWithPath: outDir + "/" + name))
    }
}
' "$ICONSET" 2>/dev/null || true

iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/AppIcon.icns" 2>/dev/null || true
rm -rf "$ICONSET"

cat > "$APP/Contents/Info.plist" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleIdentifier</key><string>com.humairaambreen.notification</string>
  <key>CFBundleName</key><string>Notification</string>
  <key>CFBundleDisplayName</key><string>Notification</string>
  <key>CFBundleExecutable</key><string>Notification</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleVersion</key><string>4</string>
  <key>CFBundleShortVersionString</key><string>4.0</string>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
  <key>NSPrincipalClass</key><string>NSApplication</string>
  <key>LSUIElement</key><true/>
  <key>NSHumanReadableCopyright</key><string>Created by humairaambreen</string>
  <key>NSCameraUsageDescription</key><string>Notification pulses the green indicator light next to the camera for notifications without capturing any video or photos.</string>
</dict>
</plist>
EOF

codesign --force --deep --sign - "$APP"
echo "Built $APP"
