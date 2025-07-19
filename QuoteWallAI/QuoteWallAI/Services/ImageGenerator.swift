import SwiftUI
import UIKit

// MARK: - Image Generation Service
class ImageGenerator: ObservableObject {
    
    // MARK: - Wallpaper Size Options
    enum WallpaperSize {
        case iPhonePortrait     // 1170 x 2532 (iPhone 14 Pro)
        case iPhoneLandscape    // 2532 x 1170
        case iPadPortrait       // 1668 x 2388 (iPad Pro 11")
        case square             // 1080 x 1080 (Instagram)
        case custom(width: CGFloat, height: CGFloat)
        
        var dimensions: CGSize {
            switch self {
            case .iPhonePortrait:
                return CGSize(width: 1170, height: 2532)
            case .iPhoneLandscape:
                return CGSize(width: 2532, height: 1170)
            case .iPadPortrait:
                return CGSize(width: 1668, height: 2388)
            case .square:
                return CGSize(width: 1080, height: 1080)
            case .custom(let width, let height):
                return CGSize(width: width, height: height)
            }
        }
        
        var displayName: String {
            switch self {
            case .iPhonePortrait: return "iPhone (Portrait)"
            case .iPhoneLandscape: return "iPhone (Landscape)"
            case .iPadPortrait: return "iPad (Portrait)"
            case .square: return "Square (Social)"
            case .custom: return "Custom Size"
            }
        }
    }
    
    // MARK: - Generation Parameters
    struct WallpaperConfig {
        let quote: Quote
        let backgroundColor: UIColor
        let fontSize: CGFloat
        let fontWeight: UIFont.Weight
        let textAlignment: NSTextAlignment
        let size: WallpaperSize
        let backgroundImage: UIImage?
        
        init(quote: Quote, 
             backgroundColor: UIColor = .systemBlue,
             fontSize: CGFloat = 24,
             fontWeight: UIFont.Weight = .medium,
             textAlignment: NSTextAlignment = .center,
             size: WallpaperSize = .iPhonePortrait,
             backgroundImage: UIImage? = nil) {
            self.quote = quote
            self.backgroundColor = backgroundColor
            self.fontSize = fontSize
            self.fontWeight = fontWeight
            self.textAlignment = textAlignment
            self.size = size
            self.backgroundImage = backgroundImage
        }
    }
    
    // MARK: - Generate Wallpaper
    func generateWallpaper(config: WallpaperConfig) -> UIImage? {
        let size = config.size.dimensions
        let scale = UIScreen.main.scale
        
        // Create high-resolution image context
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let rect = CGRect(origin: .zero, size: size)
            
            // Draw background
            drawBackground(in: rect, config: config, context: context.cgContext)
            
            // Draw quote text
            drawQuoteText(in: rect, config: config)
        }
    }
    
    // MARK: - Background Drawing
    private func drawBackground(in rect: CGRect, config: WallpaperConfig, context: CGContext) {
        if let backgroundImage = config.backgroundImage {
            // Draw custom background image
            backgroundImage.draw(in: rect)
            
            // Add color overlay if needed
            context.setFillColor(config.backgroundColor.withAlphaComponent(0.3).cgColor)
            context.fill(rect)
        } else {
            // Draw solid color background
            context.setFillColor(config.backgroundColor.cgColor)
            context.fill(rect)
            
            // Add subtle gradient for depth
            drawGradientBackground(in: rect, baseColor: config.backgroundColor, context: context)
        }
    }
    
    private func drawGradientBackground(in rect: CGRect, baseColor: UIColor, context: CGContext) {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        // Create gradient from darker to lighter
        let darkColor = baseColor.adjustBrightness(-0.15)
        let lightColor = baseColor.adjustBrightness(0.1)
        
        let colors = [darkColor.cgColor, lightColor.cgColor]
        
        guard let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: [0.0, 1.0]) else {
            return
        }
        
        // Draw diagonal gradient
        let startPoint = CGPoint(x: 0, y: 0)
        let endPoint = CGPoint(x: rect.width, y: rect.height)
        
        context.drawLinearGradient(gradient, start: startPoint, end: endPoint, options: [])
    }
    
    // MARK: - Text Drawing
    private func drawQuoteText(in rect: CGRect, config: WallpaperConfig) {
        let padding: CGFloat = max(rect.width * 0.08, 40) // Responsive padding
        let textRect = rect.insetBy(dx: padding, dy: padding)
        
        // Draw main quote
        drawMainQuote(in: textRect, config: config)
        
        // Draw author if available
        if let author = config.quote.author {
            drawAuthor(author, in: textRect, config: config)
        }
    }
    
    private func drawMainQuote(in rect: CGRect, config: WallpaperConfig) {
        let quote = config.quote.text
        
        // Calculate optimal font size for the space
        let adjustedFontSize = calculateOptimalFontSize(
            text: quote,
            rect: rect,
            baseFontSize: config.fontSize,
            fontWeight: config.fontWeight
        )
        
        // Create font and text attributes
        let font = UIFont.systemFont(ofSize: adjustedFontSize, weight: config.fontWeight)
        let textColor = UIColor.white
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = config.textAlignment
        paragraphStyle.lineBreakMode = .byWordWrapping
        paragraphStyle.lineSpacing = adjustedFontSize * 0.2 // 20% line spacing
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor,
            .paragraphStyle: paragraphStyle,
            .shadow: createTextShadow()
        ]
        
        let attributedText = NSAttributedString(string: quote, attributes: attributes)
        
        // Calculate text size and center it
        let textSize = attributedText.boundingRect(
            with: rect.size,
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        ).size
        
        let textRect = CGRect(
            x: rect.minX,
            y: rect.minY + (rect.height - textSize.height) * 0.4, // Slightly above center
            width: rect.width,
            height: textSize.height
        )
        
        attributedText.draw(in: textRect)
    }
    
    private func drawAuthor(_ author: String, in rect: CGRect, config: WallpaperConfig) {
        let authorText = "— \(author)"
        let fontSize = config.fontSize * 0.6 // Smaller font for author
        let font = UIFont.systemFont(ofSize: fontSize, weight: .light)
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = config.textAlignment
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.white.withAlphaComponent(0.9),
            .paragraphStyle: paragraphStyle,
            .shadow: createTextShadow()
        ]
        
        let attributedAuthor = NSAttributedString(string: authorText, attributes: attributes)
        
        // Position author near bottom
        let authorHeight = attributedAuthor.boundingRect(
            with: rect.size,
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        ).size.height
        
        let authorRect = CGRect(
            x: rect.minX,
            y: rect.maxY - authorHeight - (rect.height * 0.15),
            width: rect.width,
            height: authorHeight
        )
        
        attributedAuthor.draw(in: authorRect)
    }
    
    // MARK: - Helper Methods
    private func calculateOptimalFontSize(text: String, rect: CGRect, baseFontSize: CGFloat, fontWeight: UIFont.Weight) -> CGFloat {
        var fontSize = baseFontSize
        let maxFontSize = min(rect.width * 0.08, 60) // Cap at reasonable size
        let minFontSize: CGFloat = 16
        
        // Start with base size, adjust if needed
        fontSize = min(fontSize, maxFontSize)
        
        let testFont = UIFont.systemFont(ofSize: fontSize, weight: fontWeight)
        let testAttributes: [NSAttributedString.Key: Any] = [
            .font: testFont
        ]
        
        let testText = NSAttributedString(string: text, attributes: testAttributes)
        let testSize = testText.boundingRect(
            with: CGSize(width: rect.width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        ).size
        
        // If text is too large, reduce font size
        if testSize.height > rect.height * 0.6 {
            fontSize = max(fontSize * (rect.height * 0.6 / testSize.height), minFontSize)
        }
        
        return fontSize
    }
    
    private func createTextShadow() -> NSShadow {
        let shadow = NSShadow()
        shadow.shadowColor = UIColor.black.withAlphaComponent(0.4)
        shadow.shadowOffset = CGSize(width: 2, height: 2)
        shadow.shadowBlurRadius = 4
        return shadow
    }
}

// MARK: - UIColor Extensions
extension UIColor {
    func adjustBrightness(_ amount: CGFloat) -> UIColor {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        
        if getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) {
            brightness = max(0, min(1, brightness + amount))
            return UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: alpha)
        }
        
        return self
    }
} 