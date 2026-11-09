// Notification — Created by humairaambreen (https://github.com/humairaambreen)

import Foundation
import AppKit
import SwiftUI

// MARK: - Alert models

struct BlinkStyle: Codable, Equatable {
    var durationSec = 30   // how long blinking continues before auto-stopping
    var speedMs = 300      // how long the light stays on / off per flash

    init(durationSec: Int = 30, speedMs: Int = 300) {
        self.durationSec = durationSec
        self.speedMs = speedMs
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        durationSec = try c.decodeIfPresent(Int.self, forKey: .durationSec) ?? 30
        speedMs = try c.decodeIfPresent(Int.self, forKey: .speedMs) ?? 300
    }

    static let normal = BlinkStyle(durationSec: 30, speedMs: 300)
}

func formatDuration(_ seconds: Int) -> String {
    if seconds < 60 { return "\(seconds) sec" }
    let m = seconds / 60
    let s = seconds % 60
    return s == 0 ? "\(m) min" : "\(m)m \(s)s"
}

enum BuzzPreset: String, CaseIterable, Identifiable {
    case tap, double, triple, alert
    var id: String { rawValue }
    var title: String { rawValue.capitalized }

    var taps: Int {
        switch self {
        case .tap: return 1
        case .double: return 2
        case .triple: return 3
        case .alert: return 6
        }
    }

    var gapMs: Int {
        switch self {
        case .tap: return 150
        case .double: return 150
        case .triple: return 120
        case .alert: return 80
        }
    }
}

struct BuzzStyle: Codable, Equatable {
    var taps = 3
    var gapMs = 120
    var strength = 6       // Force Touch waveform: 2 light, 4 medium, 6 strong
    var repeats = 1
    var gapSec = 5

    func isPreset(_ p: BuzzPreset) -> Bool {
        taps == p.taps && gapMs == p.gapMs && repeats == 1
    }

    mutating func apply(_ p: BuzzPreset) {
        taps = p.taps
        gapMs = p.gapMs
        repeats = 1
    }
}

struct AppRule: Codable, Identifiable, Equatable {
    var id = UUID()
    var name: String
    var aliases: [String] = []
    var bundleID = ""
    var enabled = true
    var useBlink = true
    var useCamera = false
    var useBuzz = true
    var blink = BlinkStyle(durationSec: 30, speedMs: 300)
    var cameraBlink = BlinkStyle(durationSec: 30, speedMs: 800)
    var buzz = BuzzStyle()
    var only = ""

    init(id: UUID = UUID(), name: String, aliases: [String] = [], bundleID: String = "") {
        self.id = id
        self.name = name
        self.aliases = aliases
        self.bundleID = bundleID
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, aliases, bundleID, enabled, useBlink, useCamera, useBuzz, blink, cameraBlink, buzz, only
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try c.decodeIfPresent(String.self, forKey: .name) ?? ""
        aliases = try c.decodeIfPresent([String].self, forKey: .aliases) ?? []
        bundleID = try c.decodeIfPresent(String.self, forKey: .bundleID) ?? ""
        enabled = try c.decodeIfPresent(Bool.self, forKey: .enabled) ?? true
        useBlink = try c.decodeIfPresent(Bool.self, forKey: .useBlink) ?? true
        useCamera = try c.decodeIfPresent(Bool.self, forKey: .useCamera) ?? false
        useBuzz = try c.decodeIfPresent(Bool.self, forKey: .useBuzz) ?? true
        blink = try c.decodeIfPresent(BlinkStyle.self, forKey: .blink) ?? BlinkStyle(durationSec: 30, speedMs: 300)
        cameraBlink = try c.decodeIfPresent(BlinkStyle.self, forKey: .cameraBlink) ?? BlinkStyle(durationSec: 30, speedMs: 800)
        buzz = try c.decodeIfPresent(BuzzStyle.self, forKey: .buzz) ?? BuzzStyle()
        only = try c.decodeIfPresent(String.self, forKey: .only) ?? ""
    }

    var summaryText: String {
        var parts: [String] = []
        if useBlink { parts.append("Blink") }
        if useCamera { parts.append("Camera") }
        if useBuzz { parts.append("Buzz") }
        return parts.isEmpty ? "Off" : parts.joined(separator: " + ")
    }

    var keywords: [String] {
        only.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
            .filter { !$0.isEmpty }
    }

    func matches(app: String, bundleID: String = "") -> Bool {
        if !bundleID.isEmpty, !self.bundleID.isEmpty, self.bundleID.lowercased() == bundleID.lowercased() {
            return true
        }
        let n = AppFilter.clean(app).lowercased()
        if n.isEmpty { return false }
        return ([name] + aliases).contains { AppFilter.clean($0).lowercased() == n }
    }

    func keywordsMatch(_ text: String) -> Bool {
        let k = keywords
        if k.isEmpty { return true }
        let t = text.lowercased()
        return k.contains { t.contains($0) }
    }
}

struct Settings: Codable, Equatable {
    var enabled = true
    var pausedUntil: Date? = nil
    var rules: [AppRule] = []
    var seen: [String] = []

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        enabled = try c.decodeIfPresent(Bool.self, forKey: .enabled) ?? true
        pausedUntil = try c.decodeIfPresent(Date.self, forKey: .pausedUntil)
        rules = try c.decodeIfPresent([AppRule].self, forKey: .rules) ?? []
        seen = try c.decodeIfPresent([String].self, forKey: .seen) ?? []
    }

    var isPaused: Bool {
        if let p = pausedUntil { return p > Date() }
        return false
    }
}

// MARK: - Installed apps

enum AppFilter {
    static func clean(_ name: String) -> String {
        let n = String(String.UnicodeScalarView(name.unicodeScalars.filter { $0.properties.generalCategory != .format }))
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if n.hasPrefix("FACETIME_") { return "FaceTime" }
        return n
    }
}

struct InstalledApp: Identifiable, Hashable {
    let id: String
    let name: String
    let aliases: [String]
    let path: String
}

func scanInstalledApps() -> [InstalledApp] {
    var result: [String: InstalledApp] = [:]
    let fm = FileManager.default

    func add(_ url: URL) {
        guard url.pathExtension == "app", let b = Bundle(url: url), let id = b.bundleIdentifier else { return }
        let stem = url.deletingPathExtension().lastPathComponent
        var names: [String] = []
        for dict in [b.localizedInfoDictionary, b.infoDictionary] {
            for k in ["CFBundleDisplayName", "CFBundleName"] {
                if let n = dict?[k] as? String, !n.isEmpty, !names.contains(n) { names.append(n) }
            }
        }
        if !names.contains(stem) { names.append(stem) }
        guard let first = names.first else { return }
        result[id] = InstalledApp(id: id, name: first, aliases: Array(names.dropFirst()), path: url.path)
    }

    let roots = [
        "/Applications",
        "/Applications/Utilities",
        "/System/Applications",
        "/System/Applications/Utilities",
        NSHomeDirectory() + "/Applications",
    ]
    for root in roots {
        guard let items = try? fm.contentsOfDirectory(
            at: URL(fileURLWithPath: root),
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) else { continue }
        for item in items {
            if item.pathExtension == "app" {
                add(item)
            } else if root == "/Applications",
                      let sub = try? fm.contentsOfDirectory(at: item, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]) {
                for s in sub { add(s) }
            }
        }
    }
    return result.values.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
}

func appIcon(bundleID: String) -> NSImage {
    if !bundleID.isEmpty, let u = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
        return NSWorkspace.shared.icon(forFile: u.path)
    }
    return NSImage(systemSymbolName: "bell.fill", accessibilityDescription: nil) ?? NSImage()
}

// MARK: - Store

final class Store: ObservableObject {
    static let shared = Store()
    static let dir = NSHomeDirectory() + "/.notification"
    static let path = dir + "/settings.json"
    private static let legacyPath = NSHomeDirectory() + "/.capsblink/panel.json"

    @Published var settings: Settings { didSet { save() } }
    @Published var axTrusted = false
    @Published var isAlerting = false
    @Published var installed: [InstalledApp] = []

    private init() {
        let fm = FileManager.default
        if let data = fm.contents(atPath: Store.path),
           let s = try? JSONDecoder().decode(Settings.self, from: data) {
            settings = s
        } else if let legacy = fm.contents(atPath: Store.legacyPath),
                  let s = try? JSONDecoder().decode(Settings.self, from: legacy) {
            settings = s
        } else {
            settings = Settings()
        }
        save()
    }

    private func save() {
        try? FileManager.default.createDirectory(atPath: Store.dir, withIntermediateDirectories: true)
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let d = try? enc.encode(settings) {
            FileManager.default.createFile(atPath: Store.path, contents: d)
        }
    }

    func loadInstalledApps() {
        DispatchQueue.global(qos: .utility).async {
            let found = scanInstalledApps()
            DispatchQueue.main.async { self.installed = found }
        }
    }

    func ruleBinding(_ id: UUID) -> Binding<AppRule> {
        Binding(
            get: { self.settings.rules.first(where: { $0.id == id }) ?? AppRule(name: "") },
            set: { new in
                if let i = self.settings.rules.firstIndex(where: { $0.id == id }) {
                    self.settings.rules[i] = new
                }
            }
        )
    }

    func addRule(name: String, aliases: [String], bundleID: String) -> UUID {
        let r = AppRule(name: name, aliases: aliases, bundleID: bundleID)
        settings.rules.append(r)
        settings.seen.removeAll { AppFilter.clean($0).lowercased() == name.lowercased() }
        return r.id
    }

    func removeRule(_ id: UUID) {
        settings.rules.removeAll { $0.id == id }
    }

    func noteSeen(_ app: String, bundleID: String = "") {
        let cleaned = AppFilter.clean(app)
        guard !cleaned.isEmpty else { return }
        if settings.rules.contains(where: { $0.matches(app: cleaned, bundleID: bundleID) }) { return }
        if settings.seen.contains(where: { AppFilter.clean($0).lowercased() == cleaned.lowercased() }) { return }
        settings.seen.insert(cleaned, at: 0)
        if settings.seen.count > 30 { settings.seen.removeLast() }
    }

    func appName(forBundleID bundleID: String) -> String {
        if let found = installed.first(where: { $0.id.lowercased() == bundleID.lowercased() }) {
            return found.name
        }
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID),
           let b = Bundle(url: url) {
            for dict in [b.localizedInfoDictionary, b.infoDictionary] {
                for k in ["CFBundleDisplayName", "CFBundleName"] {
                    if let n = dict?[k] as? String, !n.isEmpty { return AppFilter.clean(n) }
                }
            }
            return AppFilter.clean(url.deletingPathExtension().lastPathComponent)
        }
        return ""
    }

    func pause(minutes: Int?) {
        if let m = minutes {
            settings.pausedUntil = Date().addingTimeInterval(TimeInterval(m * 60))
        } else {
            settings.pausedUntil = Date.distantFuture
        }
    }

    func resume() {
        settings.pausedUntil = nil
    }
}
