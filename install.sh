#!/bin/bash
# One-step install: builds Notification.app, copies it to /Applications and opens it.
#   Usage: bash install.sh
set -e
cd "$(dirname "$0")"

bash build.sh

pkill -x CapsBlink 2>/dev/null || true
pkill -x Notification 2>/dev/null || true
pkill -f 'log stream.*usernoted' 2>/dev/null || true
sleep 0.5

for id in com.local.capsblink com.humairaambreen.notification; do
  for svc in Accessibility ListenEvent PostEvent Camera; do
    tccutil reset "$svc" "$id" >/dev/null 2>&1 || true
  done
done

rm -rf /Applications/CapsBlink.app /Applications/Notification.app
cp -R Notification.app /Applications/
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f /Applications/Notification.app >/dev/null 2>&1 || true

for svc in Accessibility ListenEvent PostEvent Camera; do
  tccutil reset "$svc" com.humairaambreen.notification >/dev/null 2>&1 || true
done

open /Applications/Notification.app

cat <<'EOF'

Notification is installed. Click the bell icon in the menu bar (top right).

Allow Accessibility in System Settings so it can drive your Caps Lock LED and detect notifications:
  System Settings > Privacy & Security > Accessibility > Notification > on.

Opening the Accessibility page for you now...
EOF

open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility" || true
