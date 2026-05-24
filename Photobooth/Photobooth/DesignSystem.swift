import SwiftUI

// MARK: - Design System

enum DS {

    // MARK: Colors
    enum Color {
        static let background   = SwiftUI.Color(hex: "#0A0A0A")
        static let surface      = SwiftUI.Color(hex: "#111111")
        static let surfaceHigh  = SwiftUI.Color(hex: "#1A1A1A")
        static let gold         = SwiftUI.Color(hex: "#C9A84C")
        static let goldLight    = SwiftUI.Color(hex: "#E8C97A")
        static let goldDim      = SwiftUI.Color(hex: "#C9A84C").opacity(0.3)
        static let white        = SwiftUI.Color.white
        static let offWhite     = SwiftUI.Color(hex: "#F0EDE8")
        static let muted        = SwiftUI.Color(hex: "#888888")
        static let danger       = SwiftUI.Color(hex: "#E05252")
        static let success      = SwiftUI.Color(hex: "#52C07A")
        static let overlay      = SwiftUI.Color.black.opacity(0.6)
    }

    // MARK: Gradients
    enum Gradient {
        static let gold = LinearGradient(
            colors: [SwiftUI.Color(hex: "#E8C97A"), SwiftUI.Color(hex: "#A8742A")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        static let goldSubtle = LinearGradient(
            colors: [SwiftUI.Color(hex: "#C9A84C").opacity(0.15), SwiftUI.Color.clear],
            startPoint: .top,
            endPoint: .bottom
        )
        static let vignette = RadialGradient(
            colors: [SwiftUI.Color.clear, SwiftUI.Color.black.opacity(0.7)],
            center: .center,
            startRadius: 200,
            endRadius: 600
        )
        static let shimmer = LinearGradient(
            colors: [
                SwiftUI.Color.white.opacity(0),
                SwiftUI.Color.white.opacity(0.08),
                SwiftUI.Color.white.opacity(0)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    // MARK: Typography
    enum Font {
        // Display — grandes titres
        static func display(_ size: CGFloat, weight: SwiftUI.Font.Weight = .thin) -> SwiftUI.Font {
            .custom("Georgia", size: size).weight(weight)
        }
        // Heading — titres secondaires
        static func heading(_ size: CGFloat) -> SwiftUI.Font {
            .custom("Georgia-Bold", size: size)
        }
        // Label — textes UI
        static func label(_ size: CGFloat, weight: SwiftUI.Font.Weight = .medium) -> SwiftUI.Font {
            .system(size: size, weight: weight, design: .rounded)
        }
        // Mono — codes, PIN
        static func mono(_ size: CGFloat) -> SwiftUI.Font {
            .system(size: size, weight: .light, design: .monospaced)
        }
        // Caption
        static func caption(_ size: CGFloat) -> SwiftUI.Font {
            .system(size: size, weight: .regular, design: .rounded)
        }
    }

    // MARK: Spacing
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
        static let xxxl: CGFloat = 64
    }

    // MARK: Radius
    enum Radius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let full: CGFloat = 999
    }

    // MARK: Animation
    enum Animation {
        static let spring = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.75)
        static let smooth = SwiftUI.Animation.easeInOut(duration: 0.35)
        static let fast   = SwiftUI.Animation.easeOut(duration: 0.2)
        static let slow   = SwiftUI.Animation.easeInOut(duration: 0.6)
    }
}

// MARK: - Color Hex Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB,
                  red: Double(r) / 255,
                  green: Double(g) / 255,
                  blue: Double(b) / 255,
                  opacity: Double(a) / 255)
    }
}

// MARK: - View Modifiers
struct GoldBorderModifier: ViewModifier {
    var width: CGFloat = 1
    var cornerRadius: CGFloat = DS.Radius.md
    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(DS.Gradient.gold, lineWidth: width)
            )
    }
}

struct GlassModifier: ViewModifier {
    var radius: CGFloat = DS.Radius.md
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: radius)
                    .fill(DS.Color.surface.opacity(0.85))
                    .background(
                        RoundedRectangle(cornerRadius: radius)
                            .fill(.ultraThinMaterial)
                    )
            )
    }
}

extension View {
    func goldBorder(width: CGFloat = 1, cornerRadius: CGFloat = DS.Radius.md) -> some View {
        modifier(GoldBorderModifier(width: width, cornerRadius: cornerRadius))
    }
    func glass(radius: CGFloat = DS.Radius.md) -> some View {
        modifier(GlassModifier(radius: radius))
    }
}
