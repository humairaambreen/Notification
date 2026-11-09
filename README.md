# Notification

I built **Notification** because I usually keep my Mac in Do Not Disturb or turn off notification banners completely so pop-ups don't break my focus—but I still wanted a physical cue when an important message lands on WhatsApp, Slack, or Messages.

Instead of throwing another banner on your screen, **Notification** sits quietly in your menu bar and uses your MacBook's hardware to get your attention:

- **Caps Lock LED blink** — drives the physical Caps Lock key light directly without ever toggling Caps Lock on, so your typing stays completely normal while it blinks.
- **Camera LED blink** — pulses the green indicator light next to your FaceTime camera (without opening a preview window or recording any video).
- **Trackpad buzz** — taps your Force Touch trackpad actuator directly, even when your hand isn't resting on the trackpad.

It works even when macOS **Do Not Disturb (Focus)** is on or when an app's notification banner style is set to **None**. And the moment you press **Caps Lock** or switch to the app that pinged you, the blinking and buzzing stop right away.

---

## Download & Install

- **Live Website:** [https://notification-3tn.pages.dev](https://notification-3tn.pages.dev)

### Option 1: Direct DMG Download
1. [**Download Notification.dmg**](https://github.com/humairaambreen/Notification/releases/latest/download/Notification.dmg)
2. Open `Notification.dmg` and drag **Notification** into **Applications**.
3. Open **Notification** from Applications and allow it once under **System Settings → Privacy & Security → Accessibility**.

### Option 2: Build from Source
Make sure you have Apple's Command Line Tools installed (`xcode-select --install`), then run:

```bash
git clone https://github.com/humairaambreen/Notification.git
cd Notification
bash install.sh
```

---

## How it works

Click the **bell icon** in your menu bar:

1. **Pick your apps** — search for any installed app (or pick one from *Recently notified*) to add it.
2. **Choose your alerts** — toggle **Blink**, **Camera**, and **Buzz** in any combination you want.
3. **Filter by keyword (optional)** — type a name, word, or website under *Only when it contains* if you only care about specific messages.
4. **More settings** — expand *More settings* to pick how long the blinking should run before stopping on its own (`10s`, `30s`, `1m`, `2m`, `5m`, or anywhere up to 5 minutes), adjust the blink speed, or tune the trackpad tap strength and count.
5. **Test & Stop** — hit **Test** at the bottom of an app's page to try your setup; the button turns into **Stop** while the alert is running so you can cut it off anytime.

Everything stays local on your Mac in `~/.notification/settings.json`.

---

## Author

Built by [@humairaambreen](https://github.com/humairaambreen).
