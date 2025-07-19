import Foundation
import Security
import UIKit

// MARK: - OpenAI API Service
class OpenAIService: ObservableObject {
    
    // MARK: - API Configuration
    private let baseURL = "https://api.openai.com/v1"
    private let keychainService = "QuoteWallAI"
    private let keychainAccount = "OpenAI_API_Key"
    
    // MARK: - Published State
    @Published var isGeneratingImage = false
    @Published var lastError: String?
    
    // MARK: - Models
    struct ImageGenerationRequest: Codable {
        let model: String
        let prompt: String
        let n: Int
        let size: String
        let quality: String
        let style: String
        
        init(prompt: String, size: ImageSize = .medium, quality: ImageQuality = .standard, style: ImageStyle = .vivid) {
            self.model = "dall-e-3"
            self.prompt = prompt
            self.n = 1
            self.size = size.rawValue
            self.quality = quality.rawValue
            self.style = style.rawValue
        }
    }
    
    struct ImageGenerationResponse: Codable {
        let created: Int
        let data: [ImageData]
        
        struct ImageData: Codable {
            let url: String
            let revisedPrompt: String?
        }
    }
    
    enum ImageSize: String, CaseIterable {
        case small = "1024x1024"
        case medium = "1024x1792"  // Good for iPhone wallpapers
        case large = "1792x1024"   // Good for landscape
        
        var displayName: String {
            switch self {
            case .small: return "Square (1024×1024)"
            case .medium: return "Portrait (1024×1792)"
            case .large: return "Landscape (1792×1024)"
            }
        }
    }
    
    enum ImageQuality: String, CaseIterable {
        case standard = "standard"
        case hd = "hd"
        
        var displayName: String {
            switch self {
            case .standard: return "Standard"
            case .hd: return "HD (Higher Cost)"
            }
        }
    }
    
    enum ImageStyle: String, CaseIterable {
        case vivid = "vivid"
        case natural = "natural"
        
        var displayName: String {
            switch self {
            case .vivid: return "Vivid"
            case .natural: return "Natural"
            }
        }
    }
    
    // MARK: - API Key Management
    func saveAPIKey(_ key: String) -> Bool {
        let data = Data(key.utf8)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecValueData as String: data
        ]
        
        // Delete existing item first
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    func getAPIKey() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let key = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return key
    }
    
    func deleteAPIKey() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
    
    func hasAPIKey() -> Bool {
        return getAPIKey() != nil
    }
    
    // MARK: - Image Generation
    func generateBackground(for quote: Quote, completion: @escaping (Result<UIImage, Error>) -> Void) {
        guard let apiKey = getAPIKey() else {
            completion(.failure(OpenAIError.noAPIKey))
            return
        }
        
        isGeneratingImage = true
        lastError = nil
        
        let prompt = createPrompt(for: quote)
        let request = ImageGenerationRequest(prompt: prompt)
        
        generateImage(request: request, apiKey: apiKey) { result in
            DispatchQueue.main.async {
                self.isGeneratingImage = false
                
                switch result {
                case .success(let image):
                    completion(.success(image))
                case .failure(let error):
                    self.lastError = error.localizedDescription
                    completion(.failure(error))
                }
            }
        }
    }
    
    private func createPrompt(for quote: Quote) -> String {
        // Create artistic prompt based on quote content and categories
        let baseStyle = "Beautiful, artistic wallpaper background, abstract, modern, high quality, no text, "
        
        // Determine mood and style from quote categories and content
        let categories = quote.categories.joined(separator: " ").lowercased()
        let quoteText = quote.text.lowercased()
        
        var moodWords: [String] = []
        var colorScheme: String = ""
        
        // Analyze categories for mood
        if categories.contains("motivation") || categories.contains("success") {
            moodWords.append("inspiring")
            moodWords.append("energetic")
            colorScheme = "warm colors, golden hour lighting"
        } else if categories.contains("peace") || categories.contains("wisdom") {
            moodWords.append("serene")
            moodWords.append("calming")
            colorScheme = "cool blues and purples, soft lighting"
        } else if categories.contains("love") || categories.contains("friendship") {
            moodWords.append("warm")
            moodWords.append("heartfelt")
            colorScheme = "soft pinks and warm tones"
        } else if categories.contains("nature") || quoteText.contains("nature") {
            moodWords.append("natural")
            moodWords.append("organic")
            colorScheme = "nature-inspired greens and earth tones"
        } else {
            moodWords.append("elegant")
            moodWords.append("sophisticated")
            colorScheme = "gradient colors, professional"
        }
        
        // Add visual elements based on quote content
        var visualElements: [String] = []
        
        if quoteText.contains("sky") || quoteText.contains("cloud") {
            visualElements.append("clouds")
        }
        if quoteText.contains("ocean") || quoteText.contains("sea") || quoteText.contains("water") {
            visualElements.append("flowing water")
        }
        if quoteText.contains("mountain") || quoteText.contains("peak") {
            visualElements.append("mountain silhouettes")
        }
        if quoteText.contains("light") || quoteText.contains("sun") {
            visualElements.append("rays of light")
        }
        if quoteText.contains("star") || quoteText.contains("night") {
            visualElements.append("starry patterns")
        }
        
        // Construct final prompt
        let mood = moodWords.joined(separator: ", ")
        let elements = visualElements.isEmpty ? "abstract flowing shapes" : visualElements.joined(separator: ", ")
        
        return "\(baseStyle)\(mood), \(colorScheme), featuring \(elements), minimalist, professional wallpaper quality, 4K resolution"
    }
    
    private func generateImage(request: ImageGenerationRequest, apiKey: String, completion: @escaping (Result<UIImage, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/images/generations") else {
            completion(.failure(OpenAIError.invalidURL))
            return
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(OpenAIError.invalidResponse))
                return
            }
            
            guard let data = data else {
                completion(.failure(OpenAIError.noData))
                return
            }
            
            // Check for API errors
            if httpResponse.statusCode != 200 {
                if let errorResponse = try? JSONDecoder().decode(OpenAIErrorResponse.self, from: data) {
                    completion(.failure(OpenAIError.apiError(errorResponse.error.message)))
                } else {
                    completion(.failure(OpenAIError.httpError(httpResponse.statusCode)))
                }
                return
            }
            
            do {
                let response = try JSONDecoder().decode(ImageGenerationResponse.self, from: data)
                
                guard let imageData = response.data.first,
                      let imageURL = URL(string: imageData.url) else {
                    completion(.failure(OpenAIError.noImageURL))
                    return
                }
                
                // Download the image
                self.downloadImage(from: imageURL, completion: completion)
                
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    private func downloadImage(from url: URL, completion: @escaping (Result<UIImage, Error>) -> Void) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data, let image = UIImage(data: data) else {
                completion(.failure(OpenAIError.invalidImageData))
                return
            }
            
            completion(.success(image))
        }.resume()
    }
}

// MARK: - Error Handling
enum OpenAIError: LocalizedError {
    case noAPIKey
    case invalidURL
    case invalidResponse
    case noData
    case noImageURL
    case invalidImageData
    case apiError(String)
    case httpError(Int)
    
    var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "No OpenAI API key found. Please add your API key in Settings."
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from OpenAI API"
        case .noData:
            return "No data received from OpenAI API"
        case .noImageURL:
            return "No image URL in response"
        case .invalidImageData:
            return "Invalid image data received"
        case .apiError(let message):
            return "OpenAI API Error: \(message)"
        case .httpError(let code):
            return "HTTP Error: \(code)"
        }
    }
}

struct OpenAIErrorResponse: Codable {
    let error: OpenAIErrorDetail
    
    struct OpenAIErrorDetail: Codable {
        let message: String
        let type: String?
        let code: String?
    }
} 