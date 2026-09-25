import SwiftUI

private struct ThemeKey: EnvironmentKey {
    static let defaultValue = Theme(isDark: false)
}

public extension EnvironmentValues {
    var kollioTheme: Theme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

public extension View {
    /// Resolves the design tokens for the current environment, including the
    /// accessibility settings that change contrast and transparency.
    func kollioThemed() -> some View {
        modifier(ThemeResolver())
    }
}

private struct ThemeResolver: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiate
    @Environment(\.colorSchemeContrast) private var contrast

    func body(content: Content) -> some View {
        let theme = Theme(
            isDark: colorScheme == .dark,
            increaseContrast: contrast == .increased || differentiate,
            reduceTransparency: reduceTransparency
        )
        content.environment(\.kollioTheme, theme)
    }
}
