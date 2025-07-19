import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var openAIService = OpenAIService()
    
    // MARK: - State
    @State private var apiKey = ""
    @State private var showingAPIKeyField = false
    @State private var showingDeleteConfirmation = false
    @State private var showingSaveConfirmation = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            List {
                // MARK: - OpenAI API Section
                Section {
                    apiKeySection
                } header: {
                    Text("OpenAI Integration")
                } footer: {
                    Text("Required for AI-generated backgrounds. Get your API key from platform.openai.com")
                }
                
                // MARK: - App Information
                Section {
                    appInfoSection
                } header: {
                    Text("App Information")
                }
                
                // MARK: - Support Section
                Section {
                    supportSection
                } header: {
                    Text("Support")
                }
                
                // MARK: - About Section
                Section {
                    aboutSection
                } header: {
                    Text("About")
                } footer: {
                    Text("QuoteWall AI v1.0\nMade with ❤️ for inspiration seekers")
                        .multilineTextAlignment(.center)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                checkAPIKeyStatus()
            }
            .alert("API Key Saved", isPresented: $showingSaveConfirmation) {
                Button("OK") { }
            } message: {
                Text("Your OpenAI API key has been securely saved.")
            }
            .alert("Error", isPresented: $showingErrorAlert) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .alert("Delete API Key", isPresented: $showingDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    deleteAPIKey()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to delete your API key? This will disable AI background generation.")
            }
        }
    }
    
    // MARK: - API Key Section
    private var apiKeySection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "key.fill")
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("OpenAI API Key")
                        .font(.headline)
                    
                    if openAIService.hasAPIKey() {
                        Text("✅ API Key Configured")
                            .font(.caption)
                            .foregroundColor(.green)
                    } else {
                        Text("❌ No API Key")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                
                Spacer()
                
                Button(openAIService.hasAPIKey() ? "Update" : "Add") {
                    showingAPIKeyField.toggle()
                }
                .buttonStyle(.bordered)
            }
            
            if showingAPIKeyField {
                VStack(spacing: 12) {
                    SecureField("Enter your OpenAI API key", text: $apiKey)
                        .textFieldStyle(.roundedBorder)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    
                    HStack {
                        Button("Cancel") {
                            showingAPIKeyField = false
                            apiKey = ""
                        }
                        .buttonStyle(.bordered)
                        
                        Spacer()
                        
                        Button("Save") {
                            saveAPIKey()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
            
            if openAIService.hasAPIKey() {
                Button("Delete API Key", role: .destructive) {
                    showingDeleteConfirmation = true
                }
                .foregroundColor(.red)
            }
        }
    }
    
    // MARK: - App Information Section
    private var appInfoSection: some View {
        VStack(spacing: 0) {
            SettingsRow(
                icon: "paintbrush.fill",
                title: "Features",
                subtitle: "Quote browsing, customization, AI backgrounds",
                iconColor: .purple
            )
            
            SettingsRow(
                icon: "photo.fill",
                title: "Export Options",
                subtitle: "Save to Photos, share to social media",
                iconColor: .green
            )
            
            SettingsRow(
                icon: "iphone",
                title: "Wallpaper Sizes",
                subtitle: "iPhone, iPad, Square formats supported",
                iconColor: .blue
            )
            
            SettingsRow(
                icon: "shield.fill",
                title: "Privacy",
                subtitle: "All data stays on your device",
                iconColor: .orange
            )
        }
    }
    
    // MARK: - Support Section
    private var supportSection: some View {
        VStack(spacing: 0) {
            Button(action: {
                openURL("https://platform.openai.com/api-keys")
            }) {
                SettingsRow(
                    icon: "link",
                    title: "Get OpenAI API Key",
                    subtitle: "Visit OpenAI Platform",
                    iconColor: .blue,
                    showChevron: true
                )
            }
            .buttonStyle(.plain)
            
            Button(action: {
                openURL("mailto:support@quotewall.ai?subject=QuoteWall AI Support")
            }) {
                SettingsRow(
                    icon: "envelope.fill",
                    title: "Contact Support",
                    subtitle: "Get help with the app",
                    iconColor: .indigo,
                    showChevron: true
                )
            }
            .buttonStyle(.plain)
            
            Button(action: {
                shareApp()
            }) {
                SettingsRow(
                    icon: "square.and.arrow.up",
                    title: "Share App",
                    subtitle: "Tell your friends about QuoteWall AI",
                    iconColor: .pink,
                    showChevron: true
                )
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - About Section
    private var aboutSection: some View {
        VStack(spacing: 0) {
            SettingsRow(
                icon: "info.circle.fill",
                title: "Version",
                subtitle: "1.0.0 (Build 1)",
                iconColor: .gray
            )
            
            SettingsRow(
                icon: "heart.fill",
                title: "Made by",
                subtitle: "Deven Spear & AI Assistant",
                iconColor: .red
            )
            
            Button(action: {
                openURL("https://github.com/devenspear/QuoteWall-AI-")
            }) {
                SettingsRow(
                    icon: "chevron.left.forwardslash.chevron.right",
                    title: "Source Code",
                    subtitle: "View on GitHub",
                    iconColor: .black,
                    showChevron: true
                )
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Helper Methods
    private func checkAPIKeyStatus() {
        // Refresh the OpenAI service state
        openAIService.objectWillChange.send()
    }
    
    private func saveAPIKey() {
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedKey.isEmpty else {
            errorMessage = "Please enter a valid API key"
            showingErrorAlert = true
            return
        }
        
        if openAIService.saveAPIKey(trimmedKey) {
            showingSaveConfirmation = true
            showingAPIKeyField = false
            apiKey = ""
        } else {
            errorMessage = "Failed to save API key. Please try again."
            showingErrorAlert = true
        }
    }
    
    private func deleteAPIKey() {
        if openAIService.deleteAPIKey() {
            // Success - the UI will update automatically
        } else {
            errorMessage = "Failed to delete API key. Please try again."
            showingErrorAlert = true
        }
    }
    
    private func openURL(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
    }
    
    private func shareApp() {
        let text = "Check out QuoteWall AI - Create beautiful inspirational quote wallpapers with AI-generated backgrounds!"
        let url = URL(string: "https://github.com/devenspear/QuoteWall-AI-")!
        
        let activityVC = UIActivityViewController(activityItems: [text, url], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityVC, animated: true)
        }
    }
}

// MARK: - Settings Row Component
struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let iconColor: Color
    let showChevron: Bool
    
    init(icon: String, title: String, subtitle: String, iconColor: Color, showChevron: Bool = false) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.iconColor = iconColor
        self.showChevron = showChevron
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}

#Preview {
    SettingsView()
} 