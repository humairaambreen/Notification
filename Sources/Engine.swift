// Notification — Created by humairaambreen (https://github.com/humairaambreen)

import Cocoa
import IOKit
import IOKit.hid
import AVFoundation

// MARK: - Accessibility helpers

func requestAccessibility() {
    let opts = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
    _ = AXIsProcessTrustedWithOptions(opts)
    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
        NSWorkspace.shared.open(url)
    }
}

func resetAccessibility() {
    let id = Bundle.main.bundleIdentifier ?? "com.humairaambreen.notification"
    for service in ["Accessibility", "ListenEvent", "PostEvent", "Camera"] {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/tccutil")
        p.arguments = ["reset", service, id]
        p.standardOutput = Pipe()
        p.standardError = Pipe()
        try? p.run()
        p.waitUntilExit()
    }
    requestAccessibility()
}

// MARK: - Caps Lock LED hardware controller

final class CapsLED {
    private var manager: IOHIDManager?
    private let lock = NSLock()

    private func ensureManager() -> IOHIDManager {
        if let m = manager { return m }
        let m = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        let match: [String: Any] = [
            kIOHIDDeviceUsagePageKey as String: kHIDPage_GenericDesktop,
            kIOHIDDeviceUsageKey as String: kHIDUsage_GD_Keyboard,
        ]
        IOHIDManagerSetDeviceMatching(m, match as CFDictionary)
        IOHIDManagerOpen(m, IOOptionBits(kIOHIDOptionsTypeNone))
        manager = m
        return m
    }

    /// Drives the Caps Lock LED element directly without changing the Caps Lock modifier state.
    func setLED(_ on: Bool) -> Bool {
        lock.lock(); defer { lock.unlock() }
        guard AXIsProcessTrusted() else { return false }

        for attempt in 0..<2 {
            let m = ensureManager()
            guard let devices = IOHIDManagerCopyDevices(m) as? Set<IOHIDDevice>, !devices.isEmpty else {
                manager = nil
                continue
            }
            var ok = false
            for dev in devices {
                let match: [String: Any] = [
                    kIOHIDElementUsagePageKey as String: kHIDPage_LEDs,
                    kIOHIDElementUsageKey as String: kHIDUsage_LED_CapsLock,
                ]
                guard let elements = IOHIDDeviceCopyMatchingElements(dev, match as CFDictionary, IOOptionBits(kIOHIDOptionsTypeNone)) as? [IOHIDElement] else { continue }
                for el in elements {
                    let value = IOHIDValueCreateWithIntegerValue(kCFAllocatorDefault, el, 0, on ? 1 : 0)
                    var kr = IOHIDDeviceSetValue(dev, el, value)
                    if kr != kIOReturnSuccess {
                        _ = IOHIDDeviceOpen(dev, IOOptionBits(kIOHIDOptionsTypeNone))
                        kr = IOHIDDeviceSetValue(dev, el, value)
                    }
                    if kr == kIOReturnSuccess { ok = true }
                }
            }
            if ok { return true }
            if attempt == 0 { manager = nil }
        }
        return false
    }
}

// MARK: - Key LED Blinker

final class Blinker {
    private let led = CapsLED()
    private let queue = DispatchQueue(label: "notification.led", qos: .userInitiated)
    private let lock = NSLock()
    private var generation = 0
    private var running = false

    var onCapsKeyPressed: (() -> Void)?
    var onStateChanged: (() -> Void)?

    var isRunning: Bool {
        lock.lock(); defer { lock.unlock() }
        return running
    }

    private func bump() -> Int {
        lock.lock(); defer { lock.unlock() }
        generation += 1
        return generation
    }

    private func current() -> Int {
        lock.lock(); defer { lock.unlock() }
        return generation
    }

    private func setRunning(_ val: Bool) {
        lock.lock()
        running = val
        lock.unlock()
        DispatchQueue.main.async { self.onStateChanged?() }
    }

    func cancel() { _ = bump() }

    func blink(_ style: BlinkStyle) {
        let gen = bump()
        queue.async { self.run(style, gen) }
    }

    private func wait(_ ms: Int, _ gen: Int, _ initialCaps: Bool) -> Bool {
        var left = ms
        while left > 0 {
            if current() != gen { return false }
            if NSEvent.modifierFlags.contains(.capsLock) != initialCaps {
                _ = bump()
                DispatchQueue.main.async { self.onCapsKeyPressed?() }
                return false
            }
            let step = min(left, 40)
            usleep(useconds_t(step * 1000))
            left -= step
        }
        if NSEvent.modifierFlags.contains(.capsLock) != initialCaps {
            _ = bump()
            DispatchQueue.main.async { self.onCapsKeyPressed?() }
            return false
        }
        return current() == gen
    }

    private func run(_ style: BlinkStyle, _ gen: Int) {
        let base = NSEvent.modifierFlags.contains(.capsLock)
        setRunning(true)
        defer {
            let currentCaps = NSEvent.modifierFlags.contains(.capsLock)
            _ = led.setLED(currentCaps)
            setRunning(false)
        }

        let speed = max(80, style.speedMs)
        let totalMs = max(1, style.durationSec) * 1000
        let deadline = DispatchTime.now().uptimeNanoseconds + UInt64(totalMs) * 1_000_000

        while DispatchTime.now().uptimeNanoseconds < deadline {
            _ = led.setLED(!base)
            if !wait(speed, gen, base) { break }
            _ = led.setLED(base)
            if !wait(speed, gen, base) { break }
        }
    }
}

// MARK: - Camera Indicator LED Blinker

final class CameraBlinker {
    static let shared = CameraBlinker()

    private let queue = DispatchQueue(label: "notification.camera", qos: .userInitiated)
    private let lock = NSLock()
    private var generation = 0
    private var running = false
    private var session: AVCaptureSession?

    var onCapsKeyPressed: (() -> Void)?
    var onStateChanged: (() -> Void)?

    var isRunning: Bool {
        lock.lock(); defer { lock.unlock() }
        return running
    }

    private init() {}

    func requestPermissionIfNeeded() {
        if AVCaptureDevice.authorizationStatus(for: .video) == .notDetermined {
            AVCaptureDevice.requestAccess(for: .video) { _ in }
        }
    }

    private func bump() -> Int {
        lock.lock(); defer { lock.unlock() }
        generation += 1
        return generation
    }

    private func current() -> Int {
        lock.lock(); defer { lock.unlock() }
        return generation
    }

    private func setRunning(_ val: Bool) {
        lock.lock()
        running = val
        lock.unlock()
        DispatchQueue.main.async { self.onStateChanged?() }
    }

    func cancel() {
        _ = bump()
        queue.async { [weak self] in
            if let s = self?.session, s.isRunning {
                s.stopRunning()
            }
            self?.setRunning(false)
        }
    }

    func blink(_ style: BlinkStyle) {
        let gen = bump()
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        if status == .notDetermined {
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    self.queue.async { self.run(style, gen) }
                }
            }
            return
        }
        queue.async { self.run(style, gen) }
    }

    private func ensureSession() -> AVCaptureSession? {
        if let s = session { return s }
        let discovery = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera],
            mediaType: .video,
            position: .unspecified
        )
        guard let cam = discovery.devices.first ?? AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: cam) else { return nil }
        let s = AVCaptureSession()
        s.beginConfiguration()
        s.sessionPreset = .low
        if s.canAddInput(input) { s.addInput(input) }
        let output = AVCaptureVideoDataOutput()
        output.alwaysDiscardsLateVideoFrames = true
        output.setSampleBufferDelegate(nil, queue: nil)
        if s.canAddOutput(output) { s.addOutput(output) }
        s.commitConfiguration()
        session = s
        return s
    }

    private func wait(_ ms: Int, _ gen: Int, _ initialCaps: Bool) -> Bool {
        var left = ms
        while left > 0 {
            if current() != gen { return false }
            if NSEvent.modifierFlags.contains(.capsLock) != initialCaps {
                _ = bump()
                DispatchQueue.main.async { self.onCapsKeyPressed?() }
                return false
            }
            let step = min(left, 40)
            usleep(useconds_t(step * 1000))
            left -= step
        }
        if NSEvent.modifierFlags.contains(.capsLock) != initialCaps {
            _ = bump()
            DispatchQueue.main.async { self.onCapsKeyPressed?() }
            return false
        }
        return current() == gen
    }

    private func run(_ style: BlinkStyle, _ gen: Int) {
        guard AVCaptureDevice.authorizationStatus(for: .video) == .authorized,
              let s = ensureSession() else { return }
        let baseCaps = NSEvent.modifierFlags.contains(.capsLock)
        setRunning(true)
        defer {
            if s.isRunning { s.stopRunning() }
            setRunning(false)
        }

        let onMs = max(400, style.speedMs)
        let offMs = max(600, style.speedMs)
        let totalMs = max(1, style.durationSec) * 1000
        let deadline = DispatchTime.now().uptimeNanoseconds + UInt64(totalMs) * 1_000_000

        while DispatchTime.now().uptimeNanoseconds < deadline {
            if current() != gen { break }
            if !s.isRunning { s.startRunning() }
            if !wait(onMs, gen, baseCaps) { break }
            if s.isRunning { s.stopRunning() }
            if !wait(offMs, gen, baseCaps) { break }
        }
    }
}

// MARK: - Trackpad Haptics

final class Haptics {
    static let shared = Haptics()

    private typealias CreateFn = @convention(c) (UInt64) -> Unmanaged<CFTypeRef>?
    private typealias OpenFn = @convention(c) (CFTypeRef) -> IOReturn
    private typealias ActuateFn = @convention(c) (CFTypeRef, Int32, UInt32, Float, Float) -> IOReturn
    private typealias CloseFn = @convention(c) (CFTypeRef) -> IOReturn

    private var createFn: CreateFn?
    private var openFn: OpenFn?
    private var actuateFn: ActuateFn?
    private var closeFn: CloseFn?

    private let queue = DispatchQueue(label: "notification.haptics", qos: .userInitiated)
    private let lock = NSLock()
    private var generation = 0
    private var running = false

    var onStateChanged: (() -> Void)?

    var isAvailable: Bool {
        createFn != nil && openFn != nil && actuateFn != nil && closeFn != nil
    }

    var isRunning: Bool {
        lock.lock(); defer { lock.unlock() }
        return running
    }

    private init() {
        guard let mt = dlopen("/System/Library/PrivateFrameworks/MultitouchSupport.framework/MultitouchSupport", RTLD_NOW)
        else { return }
        func sym<T>(_ name: String) -> T? { dlsym(mt, name).map { unsafeBitCast($0, to: T.self) } }
        createFn = sym("MTActuatorCreateFromDeviceID")
        openFn = sym("MTActuatorOpen")
        actuateFn = sym("MTActuatorActuate")
        closeFn = sym("MTActuatorClose")
    }

    private func bump() -> Int {
        lock.lock(); defer { lock.unlock() }
        generation += 1
        return generation
    }

    private func current() -> Int {
        lock.lock(); defer { lock.unlock() }
        return generation
    }

    private func setRunning(_ val: Bool) {
        lock.lock()
        running = val
        lock.unlock()
        DispatchQueue.main.async { self.onStateChanged?() }
    }

    func cancel() { _ = bump() }

    func play(_ style: BuzzStyle) {
        let gen = bump()
        queue.async { self.run(style, gen) }
    }

    private func wait(_ ms: Int, _ gen: Int) -> Bool {
        var left = ms
        while left > 0 {
            if current() != gen { return false }
            let step = min(left, 50)
            usleep(useconds_t(step * 1000))
            left -= step
        }
        return current() == gen
    }

    private func run(_ style: BuzzStyle, _ gen: Int) {
        guard isAvailable else { return }
        setRunning(true)
        defer { setRunning(false) }

        let repeats = max(1, style.repeats)
        for r in 0..<repeats {
            if current() != gen { return }
            burst(style, gen)
            if r < repeats - 1 && !wait(max(1, style.gapSec) * 1000, gen) { return }
        }
    }

    private func burst(_ style: BuzzStyle, _ gen: Int) {
        guard let actuate = actuateFn, let close = closeFn, let actuator = openActuator() else { return }
        let taps = max(1, style.taps)
        for i in 0..<taps {
            if i > 0 && !wait(max(40, style.gapMs), gen) { break }
            if current() != gen { break }
            _ = actuate(actuator, Int32(style.strength), 0, 0, 0)
        }
        usleep(50_000)
        _ = close(actuator)
    }

    private func openActuator() -> CFTypeRef? {
        guard let create = createFn, let open = openFn else { return nil }
        var iter: io_iterator_t = 0
        guard IOServiceGetMatchingServices(kIOMainPortDefault, IOServiceMatching("AppleMultitouchDevice"), &iter) == KERN_SUCCESS
        else { return nil }
        defer { IOObjectRelease(iter) }
        while case let dev = IOIteratorNext(iter), dev != 0 {
            defer { IOObjectRelease(dev) }
            guard let id = IORegistryEntryCreateCFProperty(dev, "Multitouch ID" as CFString, kCFAllocatorDefault, 0)?
                .takeRetainedValue() as? NSNumber,
                let actuator = create(id.uint64Value)?.takeRetainedValue()
            else { continue }
            if open(actuator) == kIOReturnSuccess { return actuator }
        }
        return nil
    }
}

// MARK: - Notification Center Banner Reader (Accessibility)

final class BannerWatcher {
    var onBanner: ((String, String) -> Void)?
    private var seen = Set<String>()

    func start() {
        let t = Thread { [self] in
            while true {
                usleep(400_000)
                if AXIsProcessTrusted() { tick() } else { seen = [] }
            }
        }
        t.qualityOfService = .utility
        t.start()
    }

    private struct Banner { let key: String; let app: String; let desc: String }

    private func tick() {
        guard let nc = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.notificationcenterui").first
        else { return }
        let ax = AXUIElementCreateApplication(nc.processIdentifier)
        let windows = attr(ax, "AXWindows") as? [AXUIElement] ?? []

        if windows.contains(where: { isPanel($0) }) {
            seen = []
            return
        }

        var current: [Banner] = []
        for w in windows { collect(w, 0, &current) }

        let keys = Set(current.map { $0.key })
        let fresh = current.filter { !seen.contains($0.key) }
        seen = keys
        for b in fresh {
            let app = b.app
            let desc = b.desc
            DispatchQueue.main.async { [weak self] in self?.onBanner?(app, desc) }
        }
    }

    private func collect(_ e: AXUIElement, _ depth: Int, _ out: inout [Banner]) {
        if depth > 8 { return }
        let sub = attr(e, "AXSubrole") as? String ?? ""
        if sub.hasPrefix("AXNotificationCenter") {
            let desc = attr(e, "AXDescription") as? String ?? ""
            let app = AppFilter.clean(desc.components(separatedBy: ", ").first ?? "")
            out.append(Banner(key: sub + "|" + desc, app: app, desc: desc))
            return
        }
        for c in attr(e, "AXChildren") as? [AXUIElement] ?? [] { collect(c, depth + 1, &out) }
    }

    private func isPanel(_ e: AXUIElement, _ depth: Int = 0) -> Bool {
        if attr(e, "AXIdentifier") as? String == "widget-editor-button" { return true }
        if depth >= 5 { return false }
        return (attr(e, "AXChildren") as? [AXUIElement] ?? []).contains { isPanel($0, depth + 1) }
    }

    private func attr(_ e: AXUIElement, _ a: String) -> AnyObject? {
        var v: AnyObject?
        AXUIElementCopyAttributeValue(e, a as CFString, &v)
        return v
    }
}

// MARK: - System Notification Delivery Stream (usernoted)

final class NotificationStream {
    var onDeliver: ((String) -> Void)?
    private var process: Process?
    private var seenIDs: [String] = []

    func start() {
        let t = Thread { [weak self] in
            self?.runLoop()
        }
        t.qualityOfService = .utility
        t.start()
    }

    func stop() {
        process?.terminate()
        process = nil
    }

    private func runLoop() {
        while true {
            let p = Process()
            p.executableURL = URL(fileURLWithPath: "/usr/bin/log")
            p.arguments = [
                "stream",
                "--info",
                "--style", "compact",
                "--predicate", "process == \"usernoted\" AND (eventMessage CONTAINS \"Delivering <NotificationRecord\" OR eventMessage CONTAINS \"Presenting <NotificationRecord\")",
            ]
            let pipe = Pipe()
            p.standardOutput = pipe
            p.standardError = FileHandle.nullDevice
            do {
                try p.run()
                self.process = p
            } catch {
                usleep(2_000_000)
                continue
            }

            let handle = pipe.fileHandleForReading
            var buffer = Data()
            while p.isRunning {
                let chunk = handle.availableData
                if chunk.isEmpty { break }
                buffer.append(chunk)
                while let nl = buffer.firstIndex(of: 0x0A) {
                    let lineData = buffer.subdata(in: 0..<nl)
                    buffer.removeSubrange(0...nl)
                    if let line = String(data: lineData, encoding: .utf8) {
                        parse(line: line)
                    }
                }
            }
            usleep(1_000_000)
        }
    }

    private func parse(line: String) {
        guard (line.contains("Delivering <NotificationRecord") || line.contains("Presenting <NotificationRecord")),
              let bundleID = extract(from: line, key: "app:\""),
              !bundleID.isEmpty else { return }
        let uuid = extract(from: line, key: "uuid:\"") ?? extract(from: line, key: "ident:\"") ?? UUID().uuidString
        let dedupKey = bundleID + "|" + uuid
        if seenIDs.contains(dedupKey) { return }
        seenIDs.append(dedupKey)
        if seenIDs.count > 50 { seenIDs.removeFirst() }
        DispatchQueue.main.async { [weak self] in
            self?.onDeliver?(bundleID)
        }
    }

    private func extract(from text: String, key: String) -> String? {
        guard let r = text.range(of: key) else { return nil }
        let rest = text[r.upperBound...]
        guard let end = rest.firstIndex(of: "\"") else { return nil }
        return String(rest[..<end])
    }
}
