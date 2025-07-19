import SwiftUI
import UIKit

// MARK: - Share Sheet for UIActivityViewController
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    let applicationActivities: [UIActivity]?
    let onComplete: ((UIActivity.ActivityType?, Bool, [Any]?, Error?) -> Void)?
    
    init(items: [Any], 
         applicationActivities: [UIActivity]? = nil,
         onComplete: ((UIActivity.ActivityType?, Bool, [Any]?, Error?) -> Void)? = nil) {
        self.items = items
        self.applicationActivities = applicationActivities
        self.onComplete = onComplete
    }
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: applicationActivities
        )
        
        controller.completionWithItemsHandler = onComplete
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No updates needed
    }
}

// MARK: - Photo Library Saver
class PhotoLibrarySaver: NSObject, ObservableObject {
    @Published var saveStatus: SaveStatus = .idle
    
    enum SaveStatus: Equatable {
        case idle
        case saving
        case success
        case error(String)
        
        static func == (lhs: SaveStatus, rhs: SaveStatus) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle), (.saving, .saving), (.success, .success):
                return true
            case (.error(let lhsMessage), .error(let rhsMessage)):
                return lhsMessage == rhsMessage
            default:
                return false
            }
        }
    }
    
    func saveImageToPhotos(_ image: UIImage) {
        saveStatus = .saving
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    @objc private func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        DispatchQueue.main.async {
            if let error = error {
                self.saveStatus = .error(error.localizedDescription)
            } else {
                self.saveStatus = .success
            }
        }
    }
}

// MARK: - Sharing Helper Extensions
extension ShareSheet {
    // Convenience initializer for sharing images
    static func forImage(_ image: UIImage, onComplete: ((Bool) -> Void)? = nil) -> ShareSheet {
        return ShareSheet(
            items: [image],
            onComplete: { activityType, completed, items, error in
                onComplete?(completed)
            }
        )
    }
    
    // Convenience initializer for sharing text and image
    static func forQuoteWallpaper(_ image: UIImage, quote: Quote, onComplete: ((Bool) -> Void)? = nil) -> ShareSheet {
        let shareText = "\"\(quote.text)\""
        let authorText = quote.author.map { "— \($0)" } ?? ""
        let fullText = [shareText, authorText, "#QuoteWallAI #Inspiration"].joined(separator: "\n")
        
        return ShareSheet(
            items: [fullText, image],
            onComplete: { activityType, completed, items, error in
                onComplete?(completed)
            }
        )
    }
}

// MARK: - Activity Type Extensions
extension UIActivity.ActivityType {
    var displayName: String {
        switch self {
        case .postToFacebook: return "Facebook"
        case .postToTwitter: return "Twitter"
        case .postToWeibo: return "Weibo"
        case .message: return "Messages"
        case .mail: return "Mail"
        case .print: return "Print"
        case .copyToPasteboard: return "Copy"
        case .assignToContact: return "Assign to Contact"
        case .saveToCameraRoll: return "Save to Photos"
        case .addToReadingList: return "Reading List"
        case .postToFlickr: return "Flickr"
        case .postToVimeo: return "Vimeo"
        case .postToTencentWeibo: return "Tencent Weibo"
        case .airDrop: return "AirDrop"
        case .openInIBooks: return "Books"
        default: return "Share"
        }
    }
} 