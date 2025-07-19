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

// MARK: - Quote Container for JSON
struct QuoteContainer: Codable {
    let quotes: [Quote]
}

// MARK: - Quote Manager
class QuoteManager: ObservableObject {
    @Published var quotes: [Quote] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let fileName = "quotes"
    
    init() {
        loadQuotes()
    }
    
    // MARK: - Load Quotes from JSON
    func loadQuotes() {
        isLoading = true
        errorMessage = nil
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let quotes = try self.loadQuotesFromBundle()
                
                DispatchQueue.main.async {
                    self.quotes = quotes
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to load quotes: \(error.localizedDescription)"
                    self.isLoading = false
                    
                    // Fallback to sample quotes
                    self.quotes = self.fallbackQuotes()
                }
            }
        }
    }
    
    private func loadQuotesFromBundle() throws -> [Quote] {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "json") else {
            throw QuoteError.fileNotFound
        }
        
        let data = try Data(contentsOf: url)
        let container = try JSONDecoder().decode(QuoteContainer.self, from: data)
        return container.quotes
    }
    
    // MARK: - Search and Filter
    func searchQuotes(_ searchText: String) -> [Quote] {
        if searchText.isEmpty {
            return quotes
        }
        
        return quotes.filter { quote in
            quote.text.localizedCaseInsensitiveContains(searchText) ||
            quote.author?.localizedCaseInsensitiveContains(searchText) == true ||
            quote.categories.contains { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    func quotesByCategory(_ category: String) -> [Quote] {
        return quotes.filter { quote in
            quote.categories.contains { $0.localizedCaseInsensitiveContains(category) }
        }
    }
    
    func randomQuote() -> Quote? {
        return quotes.randomElement()
    }
    
    // MARK: - Categories
    var allCategories: [String] {
        let categorySet = Set(quotes.flatMap { $0.categories })
        return Array(categorySet).sorted()
    }
    
    func topCategories(limit: Int = 10) -> [String] {
        let categoryCount = Dictionary(grouping: quotes.flatMap { $0.categories }, by: { $0 })
            .mapValues { $0.count }
        
        return categoryCount.sorted { $0.value > $1.value }
            .prefix(limit)
            .map { $0.key }
    }
    
    // MARK: - Fallback Quotes
    private func fallbackQuotes() -> [Quote] {
        return [
            Quote(
                id: "fallback-1",
                text: "The only way to do great work is to love what you do.",
                author: "Steve Jobs",
                categories: ["Success", "Motivation", "Work"]
            ),
            Quote(
                id: "fallback-2",
                text: "Innovation distinguishes between a leader and a follower.",
                author: "Steve Jobs",
                categories: ["Innovation", "Leadership", "Success"]
            ),
            Quote(
                id: "fallback-3",
                text: "Your time is limited, don't waste it living someone else's life.",
                author: "Steve Jobs",
                categories: ["Life", "Wisdom", "Authenticity"]
            ),
            Quote(
                id: "fallback-4",
                text: "The future belongs to those who believe in the beauty of their dreams.",
                author: "Eleanor Roosevelt",
                categories: ["Dreams", "Future", "Belief"]
            ),
            Quote(
                id: "fallback-5",
                text: "Success is not final, failure is not fatal: it is the courage to continue that counts.",
                author: "Winston Churchill",
                categories: ["Success", "Courage", "Perseverance"]
            )
        ]
    }
}

// MARK: - Quote Errors
enum QuoteError: LocalizedError {
    case fileNotFound
    case invalidData
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "Quotes file not found in app bundle"
        case .invalidData:
            return "Invalid quote data format"
        case .decodingError:
            return "Failed to decode quotes from JSON"
        }
    }
} 