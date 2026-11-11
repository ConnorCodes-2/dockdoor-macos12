import AppKit
import ServiceManagement
import SwiftUI

// Compatibility layer so DockDoor can run on macOS 12 (Monterey).
// Every wrapper uses the real API on macOS 13+ and a simpler fallback on macOS 12.

// MARK: - LabeledContent (macOS 13+)

struct LabeledContentCompat<Content: View>: View {
    private let title: Text
    private let content: Content

    init(_ titleKey: LocalizedStringKey, @ViewBuilder content: () -> Content) {
        title = Text(titleKey)
        self.content = content()
    }

    init<S: StringProtocol>(_ title: S, @ViewBuilder content: () -> Content) {
        self.title = Text(String(title))
        self.content = content()
    }

    var body: some View {
        if #available(macOS 13.0, *) {
            LabeledContent {
                content
            } label: {
                title
            }
        } else {
            HStack(alignment: .firstTextBaseline) {
                title
                Spacer(minLength: 12)
                content
            }
        }
    }
}

// MARK: - Continuous hover (macOS 13+)

enum HoverPhaseCompat {
    /// The location is nil on macOS 12, where only enter/exit events are available.
    case active(CGPoint?)
    case ended
}

extension View {
    @ViewBuilder
    func onContinuousHoverCompat(perform action: @escaping (HoverPhaseCompat) -> Void) -> some View {
        if #available(macOS 13.0, *) {
            onContinuousHover { phase in
                switch phase {
                case let .active(location): action(.active(location))
                case .ended: action(.ended)
                }
            }
        } else {
            onHover { inside in
                action(inside ? .active(nil) : .ended)
            }
        }
    }

    // MARK: - Small SwiftUI modifiers introduced in macOS 13

    @ViewBuilder
    func scrollIndicatorsHiddenCompat() -> some View {
        if #available(macOS 13.0, *) {
            scrollIndicators(.hidden)
        } else {
            self
        }
    }

    @ViewBuilder
    func scrollDisabledCompat(_ disabled: Bool) -> some View {
        if #available(macOS 13.0, *) {
            scrollDisabled(disabled)
        } else {
            self
        }
    }

    /// `View.fontWeight(_:)` (for non-Text views) is macOS 13+. On macOS 12 the weight is skipped.
    @ViewBuilder
    func fontWeightCompat(_ weight: Font.Weight?) -> some View {
        if #available(macOS 13.0, *) {
            fontWeight(weight)
        } else {
            self
        }
    }
}

// MARK: - NSHostingView.sizingOptions (macOS 13+)

extension NSHostingView {
    /// On macOS 13+ toggles `.intrinsicContentSize` sizing. On macOS 12 the hosting view
    /// always reports its ideal size, so there is nothing to toggle.
    func setIntrinsicSizing(_ enabled: Bool) {
        if #available(macOS 13.0, *) {
            sizingOptions = enabled ? [.intrinsicContentSize] : []
        }
    }
}

// MARK: - Launch at login (SMAppService is macOS 13+)

enum LaunchAtLoginManager {
    private static var agentLabel: String {
        (Bundle.main.bundleIdentifier ?? "DockDoor") + ".launchatlogin"
    }

    private static var agentURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents/\(agentLabel).plist")
    }

    static var isEnabled: Bool {
        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status == .enabled
        }
        return FileManager.default.fileExists(atPath: agentURL.path)
    }

    static func setEnabled(_ enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                NSLog("DockDoor: launch at login change failed: \(error)")
            }
            return
        }

        // macOS 12: a per-user LaunchAgent that opens the app at login.
        let fm = FileManager.default
        if enabled {
            let plist: [String: Any] = [
                "Label": agentLabel,
                "ProgramArguments": ["/usr/bin/open", "-a", Bundle.main.bundlePath],
                "RunAtLoad": true,
            ]
            do {
                try fm.createDirectory(at: agentURL.deletingLastPathComponent(), withIntermediateDirectories: true)
                let data = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
                try data.write(to: agentURL, options: .atomic)
            } catch {
                NSLog("DockDoor: could not write login agent: \(error)")
            }
        } else {
            try? fm.removeItem(at: agentURL)
        }
    }
}

struct LaunchAtLoginToggle: View {
    private let title: String
    @State private var isEnabled = LaunchAtLoginManager.isEnabled

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Toggle(title, isOn: Binding(
            get: { isEnabled },
            set: { newValue in
                LaunchAtLoginManager.setEnabled(newValue)
                isEnabled = LaunchAtLoginManager.isEnabled
            }
        ))
    }
}
