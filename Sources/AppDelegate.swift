// Notification — Created by humairaambreen (https://github.com/humairaambreen)

import Cocoa
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    static var shared: AppDelegate!
    static let githubURL = URL(string: "https://github.com/humairaambreen/Notification")!

    let blinker = Blinker()
    private let banners = BannerWatcher()
    private let stream = NotificationStream()
    private var statusItem: NSStatusItem!
    private let popover = NSPopover()
    private var timer: Timer?
    private var currentIcon = ""
    private var lastFiredByApp: [String: Date] = [:]
    private var activeAlertRule: AppRule?
    private var lastCapsState = NSEvent.modifierFlags.contains(.capsLock)
    private var globalFlagsMonitor: Any?
    private var localFlagsMonitor: Any?

    override init() {
        super.init()
        AppDelegate.shared = self
    }

    // MARK: - Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMainMenu()

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let b = statusItem.button {
            b.target = self
            b.action = #selector(statusClicked(_:))
            b.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        popover.behavior = .transient
        let hosting = NSHostingController(rootView: PanelView(model: PanelModel.shared, store: Store.shared))
        hosting.sizingOptions = [.preferredContentSize]
        popover.contentViewController = hosting

        let syncRunning: () -> Void = { [weak self] in
            guard let self = self else { return }
            let active = self.blinker.isRunning || CameraBlinker.shared.isRunning || Haptics.shared.isRunning
            if Store.shared.isAlerting != active {
                Store.shared.isAlerting = active
            }
        }
        blinker.onStateChanged = syncRunning
        CameraBlinker.shared.onStateChanged = syncRunning
        Haptics.shared.onStateChanged = syncRunning

        blinker.onCapsKeyPressed = { [weak self] in self?.stopAll() }
        CameraBlinker.shared.onCapsKeyPressed = { [weak self] in self?.stopAll() }

        banners.onBanner = { [weak self] app, desc in self?.handle(app: app, bundleID: "", desc: desc) }
        banners.start()
        stream.onDeliver = { [weak self] bundleID in self?.handleDelivered(bundleID: bundleID) }
        stream.start()
        setupAutoStopObservers()
        Store.shared.loadInstalledApps()

        if !AXIsProcessTrusted() {
            let opts = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
            _ = AXIsProcessTrustedWithOptions(opts)
        }

        let t = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in self?.tick() }
        RunLoop.main.add(t, forMode: .common)
        timer = t
        tick()

        if Store.shared.settings.rules.isEmpty || !Store.shared.axTrusted {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in self?.showPopover() }
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showPopover()
        return true
    }

    func applicationWillTerminate(_ notification: Notification) {
        stream.stop()
        blinker.cancel()
        CameraBlinker.shared.cancel()
        Haptics.shared.cancel()
        Thread.sleep(forTimeInterval: 0.2)
    }

    private func setupMainMenu() {
        let main = NSMenu()

        let appItem = NSMenuItem()
        main.addItem(appItem)
        let appMenu = NSMenu()
        appItem.submenu = appMenu
        appMenu.addItem(withTitle: "Quit Notification", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")

        let editItem = NSMenuItem()
        main.addItem(editItem)
        let edit = NSMenu(title: "Edit")
        editItem.submenu = edit
        edit.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        edit.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        edit.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        edit.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")

        NSApp.mainMenu = main
    }

    // MARK: - Status Item & Popover

    @objc private func statusClicked(_ sender: NSStatusBarButton) {
        if NSApp.currentEvent?.type == .rightMouseUp {
            let menu = NSMenu()
            let quit = NSMenuItem(title: "Quit Notification", action: #selector(quitApp), keyEquivalent: "q")
            quit.target = self
            menu.addItem(quit)
            statusItem.menu = menu
            statusItem.button?.performClick(nil)
            statusItem.menu = nil
            return
        }
        if popover.isShown { popover.performClose(nil) } else { showPopover() }
    }

    @objc private func quitApp() { NSApp.terminate(nil) }

    func openGitHub() {
        NSWorkspace.shared.open(AppDelegate.githubURL)
    }

    func showPopover() {
        guard let button = statusItem.button else { return }
        PanelModel.shared.search = ""
        PanelModel.shared.screen = .list
        if popover.isShown { return }
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        NSApp.activate(ignoringOtherApps: true)
        popover.contentViewController?.view.window?.makeKey()
    }

    private func tick() {
        let store = Store.shared
        let trusted = AXIsProcessTrusted()
        if store.axTrusted != trusted { store.axTrusted = trusted }

        if let rule = activeAlertRule,
           let front = NSWorkspace.shared.frontmostApplication,
           rule.matches(app: front.localizedName ?? "", bundleID: front.bundleIdentifier ?? "") {
            stopAll()
        }

        if let until = store.settings.pausedUntil, until <= Date() {
            store.settings.pausedUntil = nil
        }
        updateIcon()
    }

    private func setupAutoStopObservers() {
        lastCapsState = NSEvent.modifierFlags.contains(.capsLock)

        let handleFlags: (NSEvent) -> Void = { [weak self] event in
            guard let self = self else { return }
            let capsNow = event.modifierFlags.contains(.capsLock)
            if event.keyCode == 57 || capsNow != self.lastCapsState {
                self.lastCapsState = capsNow
                self.stopAll()
            }
        }
        globalFlagsMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged, handler: handleFlags)
        localFlagsMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { event in
            handleFlags(event)
            return event
        }

        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] note in
            guard let self = self,
                  let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else { return }
            let name = app.localizedName ?? ""
            let bid = app.bundleIdentifier ?? ""
            if let active = self.activeAlertRule, active.matches(app: name, bundleID: bid) {
                self.stopAll()
            }
        }
    }

    private func updateIcon() {
        let s = Store.shared.settings
        let name: String
        if !Store.shared.axTrusted {
            name = "exclamationmark.triangle.fill"
        } else if !s.enabled || s.isPaused {
            name = "bell.slash.fill"
        } else {
            name = "bell.fill"
        }
        guard name != currentIcon else { return }
        currentIcon = name
        let img = NSImage(systemSymbolName: name, accessibilityDescription: "Notification")
        img?.isTemplate = true
        statusItem.button?.image = img
    }

    // MARK: - Notifications -> Alerts

    private func handleDelivered(bundleID: String) {
        let store = Store.shared
        let appName = store.appName(forBundleID: bundleID)
        if !appName.isEmpty {
            store.noteSeen(appName, bundleID: bundleID)
        }
        let s = store.settings
        guard s.enabled, !s.isPaused else { return }
        guard let rule = s.rules.first(where: {
            $0.enabled && $0.matches(app: appName, bundleID: bundleID) && $0.only.trimmingCharacters(in: .whitespaces).isEmpty
        }) else { return }
        fireDeduplicated(rule)
    }

    private func handle(app rawApp: String, bundleID: String, desc: String) {
        let store = Store.shared
        let app = AppFilter.clean(rawApp)
        guard !app.isEmpty || !bundleID.isEmpty else { return }

        if !app.isEmpty { store.noteSeen(app, bundleID: bundleID) }

        let s = store.settings
        guard s.enabled, !s.isPaused else { return }
        guard let rule = s.rules.first(where: {
            $0.enabled && $0.matches(app: app, bundleID: bundleID) && $0.keywordsMatch(desc)
        }) else { return }
        fireDeduplicated(rule)
    }

    private func fireDeduplicated(_ rule: AppRule) {
        let now = Date()
        let key = rule.id.uuidString
        if let last = lastFiredByApp[key], now.timeIntervalSince(last) < 1.5 {
            return
        }
        lastFiredByApp[key] = now
        fire(rule)
    }

    func testBlink() {
        lastCapsState = NSEvent.modifierFlags.contains(.capsLock)
        blinker.blink(BlinkStyle.normal)
    }

    func testCameraBlink() {
        lastCapsState = NSEvent.modifierFlags.contains(.capsLock)
        CameraBlinker.shared.blink(BlinkStyle(durationSec: 15, speedMs: 800))
    }

    func testBuzz() {
        lastCapsState = NSEvent.modifierFlags.contains(.capsLock)
        Haptics.shared.play(BuzzStyle())
    }

    func stopAll() {
        activeAlertRule = nil
        blinker.cancel()
        CameraBlinker.shared.cancel()
        Haptics.shared.cancel()
        Store.shared.isAlerting = false
    }

    func fire(_ rule: AppRule, isTest: Bool = false) {
        lastCapsState = NSEvent.modifierFlags.contains(.capsLock)
        activeAlertRule = isTest ? nil : rule
        if rule.useBlink {
            blinker.blink(rule.blink)
        }
        if rule.useCamera {
            CameraBlinker.shared.blink(rule.cameraBlink)
        }
        if rule.useBuzz {
            Haptics.shared.play(rule.buzz)
        }
    }
}
