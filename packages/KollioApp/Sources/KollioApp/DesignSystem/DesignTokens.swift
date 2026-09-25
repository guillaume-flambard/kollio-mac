import SwiftUI

/// Kollio identity: PAPER, INK, BRANCH.
///
/// PAPER is a calm working surface. INK makes an idea durable and readable.
/// BRANCH is the signature behaviour: a thought visibly growing from another.
///
/// Views never use raw colours: they read these tokens, which resolve per colour
/// scheme and per accessibility setting.
public enum Palette {
    // MARK: Light
    public static let lightCanvasBackground = Color(hex: 0xF7F7F3)
    public static let lightSurfacePrimary = Color(hex: 0xFFFFFF)
    public static let lightSurfaceSubtle = Color(hex: 0xF0F1EB)
    public static let lightTextPrimary = Color(hex: 0x242724)
    public static let lightTextSecondary = Color(hex: 0x62675F)
    public static let lightBorderDecorative = Color(hex: 0xDDE1D8)
    public static let lightLineEssential = Color(hex: 0x7A8278)
    public static let lightAccent = Color(hex: 0x4058D8)
    public static let lightAccentSurface = Color(hex: 0xEEF1FF)
    public static let lightAttention = Color(hex: 0x8A5A18)
    public static let lightError = Color(hex: 0xAA4146)

    // MARK: Dark
    public static let darkCanvasBackground = Color(hex: 0x171A1D)
    public static let darkSurfacePrimary = Color(hex: 0x22262A)
    public static let darkSurfaceSubtle = Color(hex: 0x292E33)
    public static let darkTextPrimary = Color(hex: 0xEFF1EC)
    public static let darkTextSecondary = Color(hex: 0xADB5AE)
    public static let darkBorderDecorative = Color(hex: 0x394047)
    public static let darkLineEssential = Color(hex: 0x7D878F)
    public static let darkAccent = Color(hex: 0x9CACFF)
    public static let darkAccentSurface = Color(hex: 0x2A3355)
    public static let darkAttention = Color(hex: 0xE6B97A)
    public static let darkError = Color(hex: 0xF4A6AA)
}

/// Semantic tokens resolved for the current environment.
public struct Theme: Equatable, Sendable {
    public var isDark: Bool
    public var increaseContrast: Bool
    public var reduceTransparency: Bool

    public init(isDark: Bool, increaseContrast: Bool = false, reduceTransparency: Bool = false) {
        self.isDark = isDark
        self.increaseContrast = increaseContrast
        self.reduceTransparency = reduceTransparency
    }

    public var canvasBackground: Color { isDark ? Palette.darkCanvasBackground : Palette.lightCanvasBackground }
    public var surfacePrimary: Color { isDark ? Palette.darkSurfacePrimary : Palette.lightSurfacePrimary }
    public var surfaceSubtle: Color { isDark ? Palette.darkSurfaceSubtle : Palette.lightSurfaceSubtle }
    public var textPrimary: Color { isDark ? Palette.darkTextPrimary : Palette.lightTextPrimary }
    public var textSecondary: Color { isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary }
    public var borderDecorative: Color { isDark ? Palette.darkBorderDecorative : Palette.lightBorderDecorative }
    public var lineEssential: Color { isDark ? Palette.darkLineEssential : Palette.lightLineEssential }
    public var accent: Color { isDark ? Palette.darkAccent : Palette.lightAccent }
    public var accentSurface: Color { isDark ? Palette.darkAccentSurface : Palette.lightAccentSurface }
    public var attention: Color { isDark ? Palette.darkAttention : Palette.lightAttention }
    public var error: Color { isDark ? Palette.darkError : Palette.lightError }

    /// Decorative borders get stronger when the user asks for more contrast.
    public var decorativeBorder: Color {
        increaseContrast ? (isDark ? Color(hex: 0x5A636B) : Color(hex: 0xB7BDB2)) : borderDecorative
    }

    /// Essential lines must always stay readable, so they never lighten away.
    public var connector: Color {
        increaseContrast ? (isDark ? Color(hex: 0xA8B2BA) : Color(hex: 0x515A50)) : lineEssential
    }

    public var proposalAccent: Color { accent }
}

public extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}

/// The spacing scale. Nothing else is allowed.
public enum Space {
    public static let xs: Double = 4
    public static let s: Double = 8
    public static let m: Double = 12
    public static let l: Double = 16
    public static let xl: Double = 24
    public static let xxl: Double = 32
    public static let huge: Double = 48
    public static let giant: Double = 64
}

public enum Radius {
    public static let control: Double = 8
    public static let reference: Double = 10
    public static let richBlock: Double = 14
    public static let composer: Double = 16
}

/// Motion explains change, never decoration.
public enum Motion {
    public static let feedback: Double = 0.10
    public static let reveal: Double = 0.14
    public static let dismiss: Double = 0.16
    public static let expand: Double = 0.22
    public static let branch: Double = 0.28
    public static let camera: Double = 0.26
    public static let stagger: Double = 0.04

    /// Entrance displacement of a growing branch, in points. Small on purpose.
    public static let branchEntranceOffset: Double = 6
}

/// Native system typography. Indicative sizes, not immutable requirements.
public enum TypeScale {
    public static let invitation = Font.system(size: 28, weight: .medium)
    public static let mainContext = Font.system(size: 22, weight: .medium)
    public static let primaryThought = Font.system(size: 18, weight: .medium)
    public static let body = Font.system(size: 15, weight: .regular)
    public static let action = Font.system(size: 13, weight: .medium)
    public static let metadata = Font.system(size: 12, weight: .regular)
}

/// Depth: three levels, and no more.
public enum Elevation {
    public static func content(_ theme: Theme) -> Double { 0 }
    public static func lifted(_ theme: Theme) -> Double { increase(theme, base: 0.10) }
    public static func control(_ theme: Theme) -> Double { increase(theme, base: 0.16) }

    static func increase(_ theme: Theme, base: Double) -> Double {
        theme.increaseContrast ? 0 : base
    }
}
