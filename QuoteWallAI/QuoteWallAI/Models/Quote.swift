import Foundation

// MARK: - Quote Model
struct Quote: Identifiable, Codable, Hashable {
    let id: String
    let text: String
    let author: String?
    let categories: [String]
    
    // Custom initializer
    init(id: String = UUID().uuidString, text: String, author: String? = nil, categories: [String]) {
        self.id = id
        self.text = text
        self.author = author
        self.categories = categories
    }
} 