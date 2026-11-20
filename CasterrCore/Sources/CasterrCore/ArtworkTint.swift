import CoreImage
import CoreImage.CIFilterBuiltins
import Foundation

/// The Now Playing background color for a show's artwork: its average color, darkened so white text stays readable.
public enum ArtworkTint {
    public struct RGB: Equatable, Sendable {
        public var red: Double
        public var green: Double
        public var blue: Double
    }

    /// Brightness is capped here, which keeps white text above 4.5:1 contrast.
    static let maxBrightness = 0.35

    public static func color(of image: CGImage) -> RGB {
        let input = CIImage(cgImage: image)
        let average = CIFilter.areaAverage()
        average.inputImage = input
        average.extent = input.extent
        var pixel = [UInt8](repeating: 0, count: 4)
        if let output = average.outputImage {
            CIContext(options: [.workingColorSpace: NSNull()])
                .render(output, toBitmap: &pixel, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
                        format: .RGBA8, colorSpace: nil)
        }
        var (h, s, b) = hsb(Double(pixel[0]) / 255, Double(pixel[1]) / 255, Double(pixel[2]) / 255)
        // Lift color a little so a dark tint doesn't look muddy; leave greys grey.
        if s > 0.15 { s = min(1, s * 1.15) }
        b = min(b, maxBrightness)
        return rgb(h, s, b)
    }

    /// WCAG contrast ratio of white text on the color.
    public static func contrastWithWhite(_ c: RGB) -> Double {
        func linear(_ v: Double) -> Double { v <= 0.03928 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4) }
        let luminance = 0.2126 * linear(c.red) + 0.7152 * linear(c.green) + 0.0722 * linear(c.blue)
        return 1.05 / (luminance + 0.05)
    }

    private static func hsb(_ r: Double, _ g: Double, _ b: Double) -> (Double, Double, Double) {
        let maxV = max(r, g, b), minV = min(r, g, b), delta = maxV - minV
        var h = 0.0
        if delta > 0 {
            if maxV == r { h = ((g - b) / delta).truncatingRemainder(dividingBy: 6) }
            else if maxV == g { h = (b - r) / delta + 2 }
            else { h = (r - g) / delta + 4 }
            h /= 6
            if h < 0 { h += 1 }
        }
        return (h, maxV == 0 ? 0 : delta / maxV, maxV)
    }

    private static func rgb(_ h: Double, _ s: Double, _ v: Double) -> RGB {
        let i = floor(h * 6), f = h * 6 - i
        let p = v * (1 - s), q = v * (1 - f * s), t = v * (1 - (1 - f) * s)
        switch Int(i) % 6 {
        case 0: return RGB(red: v, green: t, blue: p)
        case 1: return RGB(red: q, green: v, blue: p)
        case 2: return RGB(red: p, green: v, blue: t)
        case 3: return RGB(red: p, green: q, blue: v)
        case 4: return RGB(red: t, green: p, blue: v)
        default: return RGB(red: v, green: p, blue: q)
        }
    }
}
