import SwiftUI

struct QuoteEditorView: View {
    let quote: Quote
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Services
    @StateObject private var imageGenerator = ImageGenerator()
    @StateObject private var photoSaver = PhotoLibrarySaver()
    
    // MARK: - Customization State
    @State private var selectedBackgroundColor = Color.blue
    @State private var selectedFontSize: CGFloat = 24
    @State private var selectedFontWeight: Font.Weight = .medium
    @State private var textAlignment: TextAlignment = .center
    @State private var selectedWallpaperSize: ImageGenerator.WallpaperSize = .iPhonePortrait
    
    // MARK: - UI State
    @State private var showingShareSheet = false
    @State private var showingSaveConfirmation = false
    @State private var generatedWallpaper: UIImage?
    @State private var isGenerating = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    
    // MARK: - Available Options
    private let backgroundColors: [Color] = [
        .blue, .purple, .pink, .red, .orange, .yellow, .green, .teal, .indigo,
        .black, .gray, .brown, Color(.systemBlue), Color(.systemPurple)
    ]
    
    private let fontSizes: [CGFloat] = [16, 18, 20, 22, 24, 26, 28, 32, 36, 40]
    private let fontWeights: [(String, Font.Weight)] = [
        ("Light", .light), ("Regular", .regular), ("Medium", .medium), 
        ("Semibold", .semibold), ("Bold", .bold), ("Heavy", .heavy)
    ]
    
    private let wallpaperSizes: [ImageGenerator.WallpaperSize] = [
        .iPhonePortrait, .iPhoneLandscape, .iPadPortrait, .square
    ]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // MARK: - Live Preview
                wallpaperPreview
                    .frame(height: 400)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(radius: 8)
                    .padding()
                
                // MARK: - Customization Controls
                ScrollView {
                    VStack(spacing: 20) {
                        customizationControls
                        actionButtons
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Export") {
                        generateAndExportWallpaper()
                    }
                    .fontWeight(.semibold)
                    .disabled(isGenerating)
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let wallpaper = generatedWallpaper {
                    ShareSheet.forQuoteWallpaper(wallpaper, quote: quote) { completed in
                        if completed {
                            showingSaveConfirmation = true
                        }
                    }
                }
            }
            .alert("Export Status", isPresented: $showingSaveConfirmation) {
                Button("OK") { }
            } message: {
                Text("Wallpaper exported successfully!")
            }
            .alert("Error", isPresented: $showingErrorAlert) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .onChange(of: photoSaver.saveStatus) { _, newStatus in
                switch newStatus {
                case .success:
                    showingSaveConfirmation = true
                case .error(let message):
                    errorMessage = message
                    showingErrorAlert = true
                default:
                    break
                }
            }
        }
    }
    
    // MARK: - Live Preview
    private var wallpaperPreview: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                selectedBackgroundColor
                    .ignoresSafeArea()
                
                // Quote Text
                VStack(spacing: 12) {
                    Text(quote.text)
                        .font(.system(size: selectedFontSize, weight: selectedFontWeight))
                        .foregroundColor(.white)
                        .multilineTextAlignment(textAlignment)
                        .lineLimit(nil)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 1, y: 1)
                    
                    if let author = quote.author {
                        Text("— \(author)")
                            .font(.system(size: selectedFontSize * 0.7, weight: .light))
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(textAlignment)
                            .shadow(color: .black.opacity(0.3), radius: 1, x: 1, y: 1)
                    }
                }
                .padding(24)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Generation overlay
                if isGenerating {
                    Rectangle()
                        .fill(.black.opacity(0.3))
                        .overlay(
                            ProgressView("Generating...")
                                .foregroundColor(.white)
                        )
                }
            }
        }
    }
    
    // MARK: - Customization Controls
    private var customizationControls: some View {
        VStack(spacing: 24) {
            // Wallpaper Size Selection
            VStack(alignment: .leading, spacing: 12) {
                Text("Wallpaper Size")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(wallpaperSizes, id: \.displayName) { size in
                            Text(size.displayName)
                                .font(.system(size: 14, weight: selectedWallpaperSize.displayName == size.displayName ? .bold : .regular))
                                .foregroundColor(selectedWallpaperSize.displayName == size.displayName ? .white : .primary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(selectedWallpaperSize.displayName == size.displayName ? Color.orange : Color.gray.opacity(0.2))
                                )
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        selectedWallpaperSize = size
                                    }
                                }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            // Background Colors
            VStack(alignment: .leading, spacing: 12) {
                Text("Background Color")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                    ForEach(backgroundColors.indices, id: \.self) { index in
                        let color = backgroundColors[index]
                        Circle()
                            .fill(color)
                            .frame(width: 40, height: 40)
                            .overlay(
                                Circle()
                                    .stroke(selectedBackgroundColor == color ? Color.primary : Color.clear, lineWidth: 3)
                            )
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedBackgroundColor = color
                                }
                            }
                    }
                }
            }
            
            // Font Size
            VStack(alignment: .leading, spacing: 12) {
                Text("Font Size")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(fontSizes, id: \.self) { size in
                            Text("\(Int(size))")
                                .font(.system(size: 16, weight: selectedFontSize == size ? .bold : .regular))
                                .foregroundColor(selectedFontSize == size ? .white : .primary)
                                .frame(width: 40, height: 40)
                                .background(
                                    Circle()
                                        .fill(selectedFontSize == size ? Color.blue : Color.gray.opacity(0.2))
                                )
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        selectedFontSize = size
                                    }
                                }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            // Font Weight
            VStack(alignment: .leading, spacing: 12) {
                Text("Font Weight")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(fontWeights, id: \.0) { weight in
                            Text(weight.0)
                                .font(.system(size: 14, weight: selectedFontWeight == weight.1 ? .bold : .regular))
                                .foregroundColor(selectedFontWeight == weight.1 ? .white : .primary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(selectedFontWeight == weight.1 ? Color.blue : Color.gray.opacity(0.2))
                                )
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        selectedFontWeight = weight.1
                                    }
                                }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            // Text Alignment
            VStack(alignment: .leading, spacing: 12) {
                Text("Text Alignment")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                HStack(spacing: 20) {
                    alignmentButton(alignment: .leading, icon: "text.alignleft", title: "Left")
                    alignmentButton(alignment: .center, icon: "text.aligncenter", title: "Center")
                    alignmentButton(alignment: .trailing, icon: "text.alignright", title: "Right")
                }
            }
        }
    }
    
    private func alignmentButton(alignment: TextAlignment, icon: String, title: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(textAlignment == alignment ? .white : .primary)
                .frame(width: 50, height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(textAlignment == alignment ? Color.blue : Color.gray.opacity(0.2))
                )
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                textAlignment = alignment
            }
        }
    }
    
    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: 16) {
            Button(action: {
                // TODO: Generate AI background (Phase 3)
                print("🎨 Generate AI background")
            }) {
                HStack {
                    Image(systemName: "sparkles")
                    Text("Generate AI Background")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.purple)
                .foregroundColor(.white)
                .cornerRadius(12)
                .fontWeight(.semibold)
            }
            .disabled(true) // Will enable in Phase 3
            .opacity(0.6)
            
            Button(action: {
                generateAndExportWallpaper()
            }) {
                HStack {
                    if isGenerating {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "square.and.arrow.up")
                    }
                    Text(isGenerating ? "Generating..." : "Export Wallpaper")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(12)
                .fontWeight(.semibold)
            }
            .disabled(isGenerating)
            
            Button(action: {
                generateAndSaveToPhotos()
            }) {
                HStack {
                    if photoSaver.saveStatus == .saving {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "photo")
                    }
                    Text(photoSaver.saveStatus == .saving ? "Saving..." : "Save to Photos")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.indigo)
                .foregroundColor(.white)
                .cornerRadius(12)
                .fontWeight(.semibold)
            }
            .disabled(photoSaver.saveStatus == .saving || isGenerating)
        }
    }
    
    // MARK: - Generation Methods
    private func generateAndExportWallpaper() {
        generateWallpaper { image in
            self.generatedWallpaper = image
            self.showingShareSheet = true
        }
    }
    
    private func generateAndSaveToPhotos() {
        generateWallpaper { image in
            self.photoSaver.saveImageToPhotos(image)
        }
    }
    
    private func generateWallpaper(completion: @escaping (UIImage) -> Void) {
        isGenerating = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            let config = ImageGenerator.WallpaperConfig(
                quote: self.quote,
                backgroundColor: UIColor(self.selectedBackgroundColor),
                fontSize: self.selectedFontSize,
                fontWeight: self.convertToUIFontWeight(self.selectedFontWeight),
                textAlignment: self.convertToNSTextAlignment(self.textAlignment),
                size: self.selectedWallpaperSize
            )
            
            if let image = self.imageGenerator.generateWallpaper(config: config) {
                DispatchQueue.main.async {
                    self.isGenerating = false
                    completion(image)
                }
            } else {
                DispatchQueue.main.async {
                    self.isGenerating = false
                    self.errorMessage = "Failed to generate wallpaper"
                    self.showingErrorAlert = true
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    private func convertToUIFontWeight(_ weight: Font.Weight) -> UIFont.Weight {
        switch weight {
        case .ultraLight: return .ultraLight
        case .thin: return .thin
        case .light: return .light
        case .regular: return .regular
        case .medium: return .medium
        case .semibold: return .semibold
        case .bold: return .bold
        case .heavy: return .heavy
        case .black: return .black
        default: return .medium
        }
    }
    
    private func convertToNSTextAlignment(_ alignment: TextAlignment) -> NSTextAlignment {
        switch alignment {
        case .leading: return .left
        case .center: return .center
        case .trailing: return .right
        }
    }
}

#Preview {
    QuoteEditorView(quote: Quote(
        text: "The only way to do great work is to love what you do.",
        author: "Steve Jobs",
        categories: ["Success", "Motivation"]
    ))
} 