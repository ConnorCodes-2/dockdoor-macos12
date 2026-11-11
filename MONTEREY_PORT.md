# DockDoor 1.42.4 patched for macOS 12 (Monterey) — UNTESTED

Deployment target lowered from 13.0 to 12.0. Changes (all macOS 13+ APIs wrapped, real API still used on 13+):

| Area | Change |
|---|---|
| Project | Deployment target 12.0; removed LaunchAtLogin-Modern package (needs macOS 13); added `Extensions/MontereyCompat.swift` |
| Launch at login | Own toggle: SMAppService on 13+, a LaunchAgent plist on 12 |
| Settings window | `NavigationSplitView` -> `NavigationView` on 12; grouped `Form` -> scrolling `Form` on 12 |
| `LabeledContent` | `LabeledContentCompat` (HStack on 12) |
| `onContinuousHover` | `onContinuousHoverCompat` (plain `onHover` on 12: no cursor position) |
| Card grid | `NSHostingView.sizingOptions` guarded; `sizeThatFits` is 13+, so `intrinsicContentSize` is used on 12 |
| Misc | `View.fontWeight` on non-Text views, `scrollIndicators`, `scrollDisabled`, `URL.host()` |

Known limitations on 12: edge-scroll while hovering in the Alt-Tab switcher is off, some font weights are skipped,
settings pages look plainer, no Liquid Glass, newer SF Symbols may render blank.
Not compiled or run by the author of this patch. Build with the workflow in `.github/workflows/build-macos12.yml`.
