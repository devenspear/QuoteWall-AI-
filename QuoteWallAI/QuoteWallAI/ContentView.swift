//
//  ContentView.swift
//  QuoteWallAI
//
//  Created by Deven Spear on 7/19/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var quoteManager = QuoteManager()
    @State private var searchText = ""
    @State private var selectedQuote: Quote?
    @State private var showingSettings = false
    @State private var selectedCategory: String? = nil
    @State private var showingCategoryFilter = false
    
    var filteredQuotes: [Quote] {
        let searchFiltered = quoteManager.searchQuotes(searchText)
        
        if let category = selectedCategory {
            return searchFiltered.filter { quote in
                quote.categories.contains { $0.localizedCaseInsensitiveContains(category) }
            }
        }
        
        return searchFiltered
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // MARK: - Header
                headerSection
                
                // MARK: - Search and Filter
                searchSection
                
                // MARK: - Category Filter
                if showingCategoryFilter {
                    categoryFilterSection
                }
                
                // MARK: - Quick Actions
                quickActionsSection
                
                // MARK: - Quotes List
                quotesListSection
            }
            .navigationBarHidden(true)
            .sheet(item: $selectedQuote) { quote in
                QuoteEditorView(quote: quote)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .refreshable {
                quoteManager.loadQuotes()
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("QuoteWall AI")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    
                    Text("Create beautiful quote wallpapers")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Button(action: { showingSettings = true }) {
                    Image(systemName: "gearshape.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
            
            // Stats
            HStack(spacing: 20) {
                StatCard(
                    title: "\(quoteManager.quotes.count)",
                    subtitle: "Quotes",
                    icon: "quote.bubble.fill",
                    color: .blue
                )
                
                StatCard(
                    title: "\(quoteManager.allCategories.count)",
                    subtitle: "Categories", 
                    icon: "tag.fill",
                    color: .green
                )
                
                StatCard(
                    title: "\(filteredQuotes.count)",
                    subtitle: "Filtered",
                    icon: "line.3.horizontal.decrease.circle.fill",
                    color: .orange
                )
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 0))
    }
    
    // MARK: - Search Section
    private var searchSection: some View {
        VStack(spacing: 12) {
            HStack {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search quotes, authors, or categories...", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(12)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                
                Button(action: { showingCategoryFilter.toggle() }) {
                    Image(systemName: showingCategoryFilter ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                        .font(.title2)
                        .foregroundColor(selectedCategory != nil ? .orange : .blue)
                }
            }
            
            // Active filters
            if selectedCategory != nil || !searchText.isEmpty {
                HStack {
                    if !searchText.isEmpty {
                        FilterChip(text: "Search: \(searchText)", onRemove: { searchText = "" })
                    }
                    
                    if let category = selectedCategory {
                        FilterChip(text: "Category: \(category)", onRemove: { selectedCategory = nil })
                    }
                    
                    Spacer()
                    
                    Button("Clear All") {
                        searchText = ""
                        selectedCategory = nil
                    }
                    .font(.caption)
                    .foregroundColor(.red)
                }
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Category Filter Section
    private var categoryFilterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(quoteManager.topCategories(limit: 15), id: \.self) { category in
                    Button(action: {
                        if selectedCategory == category {
                            selectedCategory = nil
                        } else {
                            selectedCategory = category
                        }
                    }) {
                        Text(category)
                            .font(.caption)
                            .fontWeight(selectedCategory == category ? .semibold : .regular)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(selectedCategory == category ? .orange : .secondary.opacity(0.2))
                            )
                            .foregroundColor(selectedCategory == category ? .white : .primary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
        .transition(.slide)
    }
    
    // MARK: - Quick Actions
    private var quickActionsSection: some View {
        HStack(spacing: 16) {
            Button(action: {
                if let randomQuote = quoteManager.randomQuote() {
                    selectedQuote = randomQuote
                }
            }) {
                HStack {
                    Image(systemName: "dice.fill")
                    Text("Random Quote")
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.blue, in: RoundedRectangle(cornerRadius: 20))
                .foregroundColor(.white)
            }
            
            Button(action: {
                showingCategoryFilter.toggle()
            }) {
                HStack {
                    Image(systemName: "tag.fill")
                    Text("Browse Categories")
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.green, in: RoundedRectangle(cornerRadius: 20))
                .foregroundColor(.white)
            }
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    // MARK: - Quotes List
    private var quotesListSection: some View {
        Group {
            if quoteManager.isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Loading inspirational quotes...")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if filteredQuotes.isEmpty {
                emptyStateView
            } else {
                quotesList
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            Text("No quotes found")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Try adjusting your search or removing filters")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Clear Filters") {
                searchText = ""
                selectedCategory = nil
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var quotesList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(filteredQuotes) { quote in
                    QuoteCard(quote: quote) {
                        selectedQuote = quote
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - Supporting Views
struct StatCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct FilterChip: View {
    let text: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(text)
                .font(.caption)
                .lineLimit(1)
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.orange.opacity(0.2), in: RoundedRectangle(cornerRadius: 12))
        .foregroundColor(.orange)
    }
}

struct QuoteCard: View {
    let quote: Quote
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(quote.text)
                .font(.body)
                .lineLimit(nil)
                .multilineTextAlignment(.leading)
            
            HStack {
                if let author = quote.author {
                    Text("— \(author)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .italic()
                }
                
                Spacer()
                
                HStack(spacing: 6) {
                    ForEach(quote.categories.prefix(3), id: \.self) { category in
                        Text(category)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))
                            .foregroundColor(.blue)
                    }
                    
                    if quote.categories.count > 3 {
                        Text("+\(quote.categories.count - 3)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .onTapGesture(perform: onTap)
    }
}

#Preview {
    ContentView()
}
