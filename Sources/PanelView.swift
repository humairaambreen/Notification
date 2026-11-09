// Notification — Created by humairaambreen (https://github.com/humairaambreen)

import SwiftUI
import AppKit
import ServiceManagement

// MARK: - Theme & Panel State

enum Theme {
    static let line = Color.primary.opacity(0.25)
    static let fill = Color.primary
    static let onFill = Color(nsColor: .windowBackgroundColor)
}

final class PanelModel: ObservableObject {
    static let shared = PanelModel()

    enum Screen: Equatable {
        case list
        case detail(UUID)
        case more
    }

    @Published var screen: Screen = .list
    @Published var search = ""
    @Published var showPause = false
    @Published var showMoreSettings = false
    @Published var launchAtLogin = SMAppService.mainApp.status == .enabled

    func setLaunchAtLogin(_ on: Bool) {
        do {
            if on { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
        } catch {
            NSLog("Notification: login item change failed: \(error)")
        }
        launchAtLogin = SMAppService.mainApp.status == .enabled
    }
}

func timeString(_ date: Date) -> String {
    let f = DateFormatter()
    f.timeStyle = .short
    f.dateStyle = .none
    return f.string(from: date)
}

// MARK: - Reusable UI Components

struct SectionLabel: View {
    let title: String
    var body: some View {
        Text(title).font(.system(size: 13, weight: .bold))
    }
}

struct IconButton: View {
    let symbol: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .semibold))
                .frame(width: 30, height: 30)
                .overlay(Circle().stroke(Theme.line, lineWidth: 1))
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
    }
}

struct GitHubMark: Shape {
    func path(in rect: CGRect) -> Path {
        let s = min(rect.width, rect.height) / 24.0
        var p = Path()
        p.move(to: CGPoint(x: 12 * s, y: 1.5 * s))
        p.addCurve(to: CGPoint(x: 1.5 * s, y: 12 * s),
                   control1: CGPoint(x: 6.2 * s, y: 1.5 * s),
                   control2: CGPoint(x: 1.5 * s, y: 6.2 * s))
        p.addCurve(to: CGPoint(x: 8.7 * s, y: 22.0 * s),
                   control1: CGPoint(x: 1.5 * s, y: 16.6 * s),
                   control2: CGPoint(x: 4.5 * s, y: 20.5 * s))
        p.addCurve(to: CGPoint(x: 9.4 * s, y: 21.3 * s),
                   control1: CGPoint(x: 9.2 * s, y: 22.1 * s),
                   control2: CGPoint(x: 9.4 * s, y: 21.7 * s))
        p.addLine(to: CGPoint(x: 9.4 * s, y: 19.3 * s))
        p.addCurve(to: CGPoint(x: 4.9 * s, y: 17.4 * s),
                   control1: CGPoint(x: 6.5 * s, y: 19.9 * s),
                   control2: CGPoint(x: 5.9 * s, y: 17.9 * s))
        p.addCurve(to: CGPoint(x: 3.7 * s, y: 15.8 * s),
                   control1: CGPoint(x: 4.6 * s, y: 16.7 * s),
                   control2: CGPoint(x: 3.9 * s, y: 15.8 * s))
        p.addCurve(to: CGPoint(x: 4.8 * s, y: 15.9 * s),
                   control1: CGPoint(x: 3.4 * s, y: 15.6 * s),
                   control2: CGPoint(x: 4.3 * s, y: 15.6 * s))
        p.addCurve(to: CGPoint(x: 6.5 * s, y: 17.6 * s),
                   control1: CGPoint(x: 5.5 * s, y: 16.2 * s),
                   control2: CGPoint(x: 5.9 * s, y: 17.1 * s))
        p.addCurve(to: CGPoint(x: 9.5 * s, y: 17.4 * s),
                   control1: CGPoint(x: 7.4 * s, y: 18.9 * s),
                   control2: CGPoint(x: 8.8 * s, y: 18.0 * s))
        p.addCurve(to: CGPoint(x: 10.2 * s, y: 15.7 * s),
                   control1: CGPoint(x: 9.6 * s, y: 16.7 * s),
                   control2: CGPoint(x: 9.9 * s, y: 16.1 * s))
        p.addCurve(to: CGPoint(x: 5.5 * s, y: 10.4 * s),
                   control1: CGPoint(x: 7.6 * s, y: 15.4 * s),
                   control2: CGPoint(x: 5.5 * s, y: 14.1 * s))
        p.addCurve(to: CGPoint(x: 6.6 * s, y: 7.5 * s),
                   control1: CGPoint(x: 5.5 * s, y: 9.2 * s),
                   control2: CGPoint(x: 5.9 * s, y: 8.2 * s))
        p.addCurve(to: CGPoint(x: 6.7 * s, y: 4.7 * s),
                   control1: CGPoint(x: 6.4 * s, y: 6.8 * s),
                   control2: CGPoint(x: 6.2 * s, y: 5.5 * s))
        p.addCurve(to: CGPoint(x: 9.6 * s, y: 5.8 * s),
                   control1: CGPoint(x: 7.6 * s, y: 4.4 * s),
                   control2: CGPoint(x: 9.6 * s, y: 5.8 * s))
        p.addCurve(to: CGPoint(x: 14.4 * s, y: 5.8 * s),
                   control1: CGPoint(x: 11.1 * s, y: 5.4 * s),
                   control2: CGPoint(x: 12.9 * s, y: 5.4 * s))
        p.addCurve(to: CGPoint(x: 17.3 * s, y: 4.7 * s),
                   control1: CGPoint(x: 14.4 * s, y: 5.8 * s),
                   control2: CGPoint(x: 16.4 * s, y: 4.4 * s))
        p.addCurve(to: CGPoint(x: 17.4 * s, y: 7.5 * s),
                   control1: CGPoint(x: 17.8 * s, y: 5.5 * s),
                   control2: CGPoint(x: 17.6 * s, y: 6.8 * s))
        p.addCurve(to: CGPoint(x: 18.5 * s, y: 10.4 * s),
                   control1: CGPoint(x: 18.1 * s, y: 8.2 * s),
                   control2: CGPoint(x: 18.5 * s, y: 9.2 * s))
        p.addCurve(to: CGPoint(x: 13.8 * s, y: 15.7 * s),
                   control1: CGPoint(x: 18.5 * s, y: 14.1 * s),
                   control2: CGPoint(x: 16.4 * s, y: 15.4 * s))
        p.addCurve(to: CGPoint(x: 14.6 * s, y: 17.8 * s),
                   control1: CGPoint(x: 14.3 * s, y: 16.2 * s),
                   control2: CGPoint(x: 14.6 * s, y: 17.0 * s))
        p.addLine(to: CGPoint(x: 14.6 * s, y: 21.3 * s))
        p.addCurve(to: CGPoint(x: 15.3 * s, y: 22.0 * s),
                   control1: CGPoint(x: 14.6 * s, y: 21.7 * s),
                   control2: CGPoint(x: 14.8 * s, y: 22.1 * s))
        p.addCurve(to: CGPoint(x: 22.5 * s, y: 12 * s),
                   control1: CGPoint(x: 19.5 * s, y: 20.5 * s),
                   control2: CGPoint(x: 22.5 * s, y: 16.6 * s))
        p.addCurve(to: CGPoint(x: 12 * s, y: 1.5 * s),
                   control1: CGPoint(x: 22.5 * s, y: 6.2 * s),
                   control2: CGPoint(x: 17.8 * s, y: 1.5 * s))
        p.closeSubpath()
        return p
    }
}

struct GitHubIconButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            GitHubMark()
                .fill(Color.primary)
                .frame(width: 15, height: 15)
                .frame(width: 30, height: 30)
                .overlay(Circle().stroke(Theme.line, lineWidth: 1))
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
    }
}

struct Chip: View {
    let title: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .foregroundColor(selected ? Theme.onFill : Color.primary)
                .background(Capsule().fill(selected ? Theme.fill : Color.clear))
                .overlay(Capsule().stroke(selected ? Color.clear : Theme.line, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

struct ModeButton: View {
    let title: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .padding(.horizontal, 6)
                .foregroundColor(selected ? Theme.onFill : Color.primary)
                .background(RoundedRectangle(cornerRadius: 9).fill(selected ? Theme.fill : Color.clear))
                .overlay(RoundedRectangle(cornerRadius: 9).stroke(selected ? Color.clear : Theme.line, lineWidth: 1))
                .contentShape(RoundedRectangle(cornerRadius: 9))
        }
        .buttonStyle(.plain)
    }
}

struct PillButton: View {
    let title: String
    var filled = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .foregroundColor(filled ? Theme.onFill : Color.primary)
                .background(Capsule().fill(filled ? Theme.fill : Color.clear))
                .overlay(Capsule().stroke(filled ? Color.clear : Theme.line, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

struct ToggleRow: View {
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 8) {
            Text(title).font(.system(size: 13)).fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 8)
            Toggle("", isOn: $isOn).labelsHidden().toggleStyle(.switch)
        }
    }
}

struct SliderRow: View {
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    var step: Int = 1
    let label: (Int) -> String

    var body: some View {
        VStack(spacing: 2) {
            HStack {
                Text(title).font(.system(size: 13))
                Spacer()
                Text(label(value)).font(.system(size: 13, weight: .semibold))
            }
            Slider(
                value: Binding(get: { Double(value) }, set: { value = Int($0.rounded()) }),
                in: Double(range.lowerBound)...Double(range.upperBound),
                step: Double(step)
            )
            .tint(Color.primary)
        }
    }
}

struct BackButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: "chevron.left").font(.system(size: 12, weight: .bold))
                Text(title).font(.system(size: 13, weight: .semibold))
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Root Panel View

struct PanelView: View {
    @ObservedObject var model: PanelModel
    @ObservedObject var store: Store

    var body: some View {
        VStack(spacing: 0) {
            if !store.axTrusted {
                PermissionScreen()
            } else {
                switch model.screen {
                case .list:
                    ListScreen(model: model, store: store)
                case .detail(let id):
                    DetailScreen(model: model, store: store, id: id)
                case .more:
                    MoreScreen(model: model, store: store)
                }
            }
        }
        .frame(width: 340)
        .fixedSize(horizontal: false, vertical: true)
    }
}

struct PermissionScreen: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "bell.fill")
                    .font(.system(size: 15, weight: .bold))
                Text("Notification")
                    .font(.system(size: 17, weight: .bold))
                Spacer()
                GitHubIconButton { AppDelegate.shared.openGitHub() }
            }

            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: "hand.raised.fill")
                    .font(.system(size: 26))
                Text("Allow Accessibility")
                    .font(.system(size: 16, weight: .bold))
                Text("Notification needs Accessibility permission first so it can drive your Caps Lock LED and detect notifications.")
                    .font(.system(size: 13))
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 8) {
                    PillButton(title: "Allow Accessibility", filled: true) { requestAccessibility() }
                    PillButton(title: "Reset") { resetAccessibility() }
                }
                .padding(.top, 4)

                Text("Already switched on in System Settings? Click Reset, then turn it on once more.")
                    .font(.system(size: 11))
                    .opacity(0.75)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 2)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.line, lineWidth: 1))

            HStack {
                Spacer()
                Button("Quit Notification") { NSApp.terminate(nil) }
                    .buttonStyle(.plain)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.red)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .frame(width: 340, alignment: .topLeading)
    }
}

// MARK: - App List Screen (Home)

struct Candidate: Identifiable {
    let id: String
    let name: String
    let aliases: [String]
    let bundleID: String
}

struct ListScreen: View {
    @ObservedObject var model: PanelModel
    @ObservedObject var store: Store

    private var query: String { model.search.trimmingCharacters(in: .whitespaces).lowercased() }

    private var watched: [AppRule] {
        let q = query
        return store.settings.rules.filter { q.isEmpty || $0.name.lowercased().contains(q) }
    }

    private var candidates: [Candidate] {
        let q = query
        let rules = store.settings.rules

        func watchedAlready(_ names: [String]) -> Bool {
            names.contains { n in rules.contains { $0.matches(app: n) } }
        }
        func installedMatch(_ name: String) -> InstalledApp? {
            let n = name.lowercased()
            return store.installed.first { app in ([app.name] + app.aliases).contains { $0.lowercased() == n } }
        }

        var out: [Candidate] = []
        var used = Set<String>()

        if q.isEmpty {
            for s in store.settings.seen.prefix(6) {
                let key = s.lowercased()
                if used.contains(key) || watchedAlready([s]) { continue }
                used.insert(key)
                if let a = installedMatch(s) {
                    out.append(Candidate(id: key, name: a.name, aliases: a.aliases, bundleID: a.id))
                } else {
                    out.append(Candidate(id: key, name: s, aliases: [], bundleID: ""))
                }
            }
            return out
        }

        for a in store.installed {
            let names = [a.name] + a.aliases
            if !names.contains(where: { $0.lowercased().contains(q) }) { continue }
            if watchedAlready(names) { continue }
            let key = a.name.lowercased()
            if used.contains(key) { continue }
            used.insert(key)
            out.append(Candidate(id: key, name: a.name, aliases: a.aliases, bundleID: a.id))
            if out.count >= 30 { break }
        }
        for s in store.settings.seen where s.lowercased().contains(q) {
            let key = s.lowercased()
            if used.contains(key) || watchedAlready([s]) { continue }
            used.insert(key)
            out.append(Candidate(id: key, name: s, aliases: [], bundleID: ""))
        }
        return out
    }

    var body: some View {
        let cands = candidates
        let totalRows = watched.count + cands.count
        return VStack(alignment: .leading, spacing: 12) {
            header
            if model.showPause && !store.settings.isPaused { pauseOptions }
            if store.settings.isPaused { pausedBar }
            searchField
            if totalRows > 6 {
                ScrollView {
                    VStack(alignment: .leading, spacing: 2) {
                        content(cands)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(height: 310)
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    content(cands)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .frame(width: 340, alignment: .topLeading)
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "bell.fill")
                .font(.system(size: 15, weight: .bold))
            Text("Notification")
                .font(.system(size: 17, weight: .bold))
            Spacer()
            IconButton(symbol: store.settings.isPaused ? "play.fill" : "pause.fill") {
                if store.settings.isPaused {
                    store.resume()
                } else {
                    model.showPause.toggle()
                }
            }
            GitHubIconButton {
                AppDelegate.shared.openGitHub()
            }
            IconButton(symbol: "gearshape.fill") {
                model.showPause = false
                model.screen = .more
            }
        }
    }

    private var pauseOptions: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Pause for").font(.system(size: 12, weight: .semibold))
            HStack(spacing: 8) {
                Chip(title: "30 min", selected: false) { startPause(30) }
                Chip(title: "1 hour", selected: false) { startPause(60) }
                Chip(title: "2 hours", selected: false) { startPause(120) }
            }
            HStack(spacing: 8) {
                Chip(title: "4 hours", selected: false) { startPause(240) }
                Chip(title: "Until I resume", selected: false) { startPause(nil) }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.line, lineWidth: 1))
    }

    private func startPause(_ minutes: Int?) {
        store.pause(minutes: minutes)
        model.showPause = false
    }

    private var pausedBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "pause.fill")
            Text(store.settings.pausedUntil == Date.distantFuture
                 ? "Paused"
                 : "Paused until \(timeString(store.settings.pausedUntil ?? Date()))")
                .font(.system(size: 12, weight: .semibold))
            Spacer()
            PillButton(title: "Resume") { store.resume() }
        }
        .padding(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.line, lineWidth: 1))
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
            TextField("Search apps", text: $model.search)
                .textFieldStyle(.plain)
                .font(.system(size: 14))
            if !model.search.isEmpty {
                Button { model.search = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.line, lineWidth: 1))
    }

    @ViewBuilder
    private func content(_ cands: [Candidate]) -> some View {
        if store.settings.rules.isEmpty && query.isEmpty && cands.isEmpty {
            VStack(spacing: 8) {
                Image(systemName: "bell").font(.system(size: 24))
                Text("Search for an app to add it").font(.system(size: 13, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
        } else {
            if !watched.isEmpty {
                SectionLabel(title: "Your apps").padding(.top, 4).padding(.bottom, 4)
                ForEach(watched) { rule in watchedRow(rule) }
            }
            if !cands.isEmpty {
                SectionLabel(title: query.isEmpty ? "Recently notified" : "Add")
                    .padding(.top, 10)
                    .padding(.bottom, 4)
                ForEach(cands) { c in candidateRow(c) }
            }
            if !query.isEmpty && watched.isEmpty && cands.isEmpty {
                Text("No apps found")
                    .font(.system(size: 13))
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private func subtitle(_ rule: AppRule) -> String {
        rule.only.isEmpty ? rule.summaryText : rule.summaryText + " · filtered"
    }

    private func watchedRow(_ rule: AppRule) -> some View {
        HStack(spacing: 10) {
            Button {
                model.search = ""
                model.showMoreSettings = false
                model.screen = .detail(rule.id)
            } label: {
                HStack(spacing: 10) {
                    Image(nsImage: appIcon(bundleID: rule.bundleID)).resizable().frame(width: 30, height: 30)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(rule.name).font(.system(size: 14, weight: .medium)).lineLimit(1)
                        Text(subtitle(rule)).font(.system(size: 11))
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right").font(.system(size: 11, weight: .semibold))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            Toggle("", isOn: store.ruleBinding(rule.id).enabled)
                .toggleStyle(.switch)
                .labelsHidden()
        }
        .padding(.vertical, 6)
    }

    private func candidateRow(_ c: Candidate) -> some View {
        Button {
            let id = store.addRule(name: c.name, aliases: c.aliases, bundleID: c.bundleID)
            model.search = ""
            model.showMoreSettings = false
            model.screen = .detail(id)
        } label: {
            HStack(spacing: 10) {
                Image(nsImage: appIcon(bundleID: c.bundleID)).resizable().frame(width: 30, height: 30)
                Text(c.name).font(.system(size: 14)).lineLimit(1)
                Spacer(minLength: 0)
                Image(systemName: "plus.circle").font(.system(size: 20))
            }
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - App Detail Screen

struct DetailScreen: View {
    @ObservedObject var model: PanelModel
    @ObservedObject var store: Store
    let id: UUID

    var body: some View {
        if store.settings.rules.contains(where: { $0.id == id }) {
            DetailBody(model: model, store: store, rule: store.ruleBinding(id))
        } else {
            Color.clear.onAppear { model.screen = .list }
        }
    }
}

struct DetailBody: View {
    @ObservedObject var model: PanelModel
    @ObservedObject var store: Store
    @Binding var rule: AppRule

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            topBar
            if model.showMoreSettings {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        modePicker
                        filterSection
                        moreSettingsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                }
                .frame(height: 320)
            } else {
                VStack(alignment: .leading, spacing: 18) {
                    modePicker
                    filterSection
                    moreSettingsSection
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 4)
            }
            bottomBar
        }
        .frame(width: 340, alignment: .topLeading)
    }

    private var topBar: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                BackButton(title: "Apps") {
                    AppDelegate.shared.stopAll()
                    model.screen = .list
                }
                Spacer()
                Toggle("", isOn: $rule.enabled)
                    .toggleStyle(.switch)
                    .labelsHidden()
            }
            HStack(spacing: 12) {
                Image(nsImage: appIcon(bundleID: rule.bundleID)).resizable().frame(width: 44, height: 44)
                Text(rule.name).font(.system(size: 20, weight: .bold)).lineLimit(1)
                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    private var modePicker: some View {
        HStack(spacing: 8) {
            ModeButton(title: "Blink", selected: rule.useBlink) {
                if rule.useBlink && !rule.useCamera && !rule.useBuzz {
                    rule.useBlink = false
                    rule.useBuzz = true
                } else {
                    rule.useBlink.toggle()
                }
            }
            ModeButton(title: "Camera", selected: rule.useCamera) {
                if rule.useCamera && !rule.useBlink && !rule.useBuzz {
                    rule.useCamera = false
                    rule.useBlink = true
                } else {
                    rule.useCamera.toggle()
                    if rule.useCamera {
                        CameraBlinker.shared.requestPermissionIfNeeded()
                    }
                }
            }
            ModeButton(title: "Buzz", selected: rule.useBuzz) {
                if rule.useBuzz && !rule.useBlink && !rule.useCamera {
                    rule.useBuzz = false
                    rule.useBlink = true
                } else {
                    rule.useBuzz.toggle()
                }
            }
        }
    }

    private var moreSettingsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Button {
                model.showMoreSettings.toggle()
            } label: {
                HStack(spacing: 6) {
                    Text("More settings")
                        .font(.system(size: 13, weight: .semibold))
                    Spacer()
                    Image(systemName: model.showMoreSettings ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11, weight: .bold))
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity)
                .overlay(RoundedRectangle(cornerRadius: 9).stroke(Theme.line, lineWidth: 1))
                .contentShape(RoundedRectangle(cornerRadius: 9))
            }
            .buttonStyle(.plain)

            if model.showMoreSettings {
                VStack(alignment: .leading, spacing: 18) {
                    if rule.useBlink { blinkSection }
                    if rule.useCamera { cameraBlinkSection }
                    if rule.useBuzz { buzzSection }
                }
                .padding(.top, 2)
            }
        }
    }

    private var blinkSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel(title: "Key blink")

            VStack(alignment: .leading, spacing: 6) {
                Text("Stop after").font(.system(size: 12, weight: .medium)).opacity(0.8)
                HStack(spacing: 6) {
                    Chip(title: "10s", selected: rule.blink.durationSec == 10) { rule.blink.durationSec = 10 }
                    Chip(title: "30s", selected: rule.blink.durationSec == 30) { rule.blink.durationSec = 30 }
                    Chip(title: "1m", selected: rule.blink.durationSec == 60) { rule.blink.durationSec = 60 }
                    Chip(title: "2m", selected: rule.blink.durationSec == 120) { rule.blink.durationSec = 120 }
                    Chip(title: "5m", selected: rule.blink.durationSec == 300) { rule.blink.durationSec = 300 }
                }
            }

            SliderRow(title: "Duration", value: $rule.blink.durationSec, range: 5...300, step: 5) {
                formatDuration($0)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Blink speed").font(.system(size: 12, weight: .medium)).opacity(0.8)
                HStack(spacing: 6) {
                    Chip(title: "Fast", selected: rule.blink.speedMs == 150) { rule.blink.speedMs = 150 }
                    Chip(title: "Normal", selected: rule.blink.speedMs == 300) { rule.blink.speedMs = 300 }
                    Chip(title: "Slow", selected: rule.blink.speedMs == 600) { rule.blink.speedMs = 600 }
                }
            }

            SliderRow(title: "Flash interval", value: $rule.blink.speedMs, range: 100...800, step: 50) { "\($0) ms" }
        }
    }

    private var cameraBlinkSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel(title: "Camera blink")

            VStack(alignment: .leading, spacing: 6) {
                Text("Stop after").font(.system(size: 12, weight: .medium)).opacity(0.8)
                HStack(spacing: 6) {
                    Chip(title: "10s", selected: rule.cameraBlink.durationSec == 10) { rule.cameraBlink.durationSec = 10 }
                    Chip(title: "30s", selected: rule.cameraBlink.durationSec == 30) { rule.cameraBlink.durationSec = 30 }
                    Chip(title: "1m", selected: rule.cameraBlink.durationSec == 60) { rule.cameraBlink.durationSec = 60 }
                    Chip(title: "2m", selected: rule.cameraBlink.durationSec == 120) { rule.cameraBlink.durationSec = 120 }
                    Chip(title: "5m", selected: rule.cameraBlink.durationSec == 300) { rule.cameraBlink.durationSec = 300 }
                }
            }

            SliderRow(title: "Duration", value: $rule.cameraBlink.durationSec, range: 5...300, step: 5) {
                formatDuration($0)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Blink speed").font(.system(size: 12, weight: .medium)).opacity(0.8)
                HStack(spacing: 6) {
                    Chip(title: "Fast", selected: rule.cameraBlink.speedMs == 500) { rule.cameraBlink.speedMs = 500 }
                    Chip(title: "Normal", selected: rule.cameraBlink.speedMs == 800) { rule.cameraBlink.speedMs = 800 }
                    Chip(title: "Slow", selected: rule.cameraBlink.speedMs == 1400) { rule.cameraBlink.speedMs = 1400 }
                }
            }

            SliderRow(title: "Flash interval", value: $rule.cameraBlink.speedMs, range: 400...2000, step: 100) { "\($0) ms" }
        }
    }

    private var buzzSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(title: "Trackpad buzz")
            if !Haptics.shared.isAvailable {
                Text("No Force Touch trackpad found").font(.system(size: 12, weight: .medium))
            }
            HStack(spacing: 8) {
                ForEach(BuzzPreset.allCases) { p in
                    Chip(title: p.title, selected: rule.buzz.isPreset(p)) { rule.buzz.apply(p) }
                }
            }
            HStack(spacing: 8) {
                Chip(title: "Light", selected: rule.buzz.strength == 2) { rule.buzz.strength = 2 }
                Chip(title: "Medium", selected: rule.buzz.strength == 4) { rule.buzz.strength = 4 }
                Chip(title: "Strong", selected: rule.buzz.strength == 6) { rule.buzz.strength = 6 }
            }
            SliderRow(title: "Taps", value: $rule.buzz.taps, range: 1...10) { "\($0)" }
            if rule.buzz.taps > 1 {
                SliderRow(title: "Tap spacing", value: $rule.buzz.gapMs, range: 60...400, step: 10) { "\($0) ms" }
            }
            SliderRow(title: "Repeat", value: $rule.buzz.repeats, range: 1...10) { $0 == 1 ? "Once" : "\($0)×" }
            if rule.buzz.repeats > 1 {
                SliderRow(title: "Pause between", value: $rule.buzz.gapSec, range: 2...60) { "\($0) s" }
            }
        }
    }

    private var filterSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionLabel(title: "Only when it contains")
            TextField("Anything — or a name / website", text: $rule.only)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .padding(9)
                .overlay(RoundedRectangle(cornerRadius: 9).stroke(Theme.line, lineWidth: 1))
        }
    }

    private var bottomBar: some View {
        HStack {
            PillButton(title: store.isAlerting ? "Stop" : "Test", filled: true) {
                if store.isAlerting {
                    AppDelegate.shared.stopAll()
                } else {
                    AppDelegate.shared.fire(rule, isTest: true)
                }
            }
            Spacer()
            Button {
                AppDelegate.shared.stopAll()
                let id = rule.id
                model.screen = .list
                store.removeRule(id)
            } label: {
                Text("Remove").font(.system(size: 13, weight: .semibold)).foregroundColor(.red)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}

// MARK: - Settings Screen

struct MoreScreen: View {
    @ObservedObject var model: PanelModel
    @ObservedObject var store: Store

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                BackButton(title: "Apps") {
                    AppDelegate.shared.stopAll()
                    model.screen = .list
                }
                Spacer()
                GitHubIconButton {
                    AppDelegate.shared.openGitHub()
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                SectionLabel(title: "Test")
                HStack(spacing: 8) {
                    PillButton(title: "Blink", filled: true) { AppDelegate.shared.testBlink() }
                    PillButton(title: "Camera", filled: true) { AppDelegate.shared.testCameraBlink() }
                    PillButton(title: "Buzz", filled: true) { AppDelegate.shared.testBuzz() }
                    if store.isAlerting {
                        PillButton(title: "Stop") { AppDelegate.shared.stopAll() }
                    }
                }
            }

            ToggleRow(
                title: "Launch at login",
                isOn: Binding(get: { model.launchAtLogin }, set: { model.setLaunchAtLogin($0) })
            )

            HStack {
                Button {
                    AppDelegate.shared.openGitHub()
                } label: {
                    Text("@humairaambreen")
                        .font(.system(size: 12, weight: .medium))
                        .opacity(0.6)
                }
                .buttonStyle(.plain)

                Spacer()

                Button("Quit Notification") { NSApp.terminate(nil) }
                    .buttonStyle(.plain)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.red)
            }
            .padding(.top, 4)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .frame(width: 340, alignment: .topLeading)
    }
}
