//
//  ContentView.swift
//  QuoteWallAI
//
//  Created by Deven Spear on 7/19/25.
//

import SwiftUI

struct ContentView: View {
    @State private var searchText = ""
    @State private var selectedQuote: Quote?
    @State private var showingSettings = false
    
    // Sample quotes for immediate testing
    private let sampleQuotes = [
        Quote(id: "1", text: "The only way to do great work is to love what you do.", author: "Steve Jobs", categories: ["Success", "Motivation"]),
        Quote(id: "2", text: "Innovation distinguishes between a leader and a follower.", author: "Steve Jobs", categories: ["Innovation", "Leadership"]),
        Quote(id: "3", text: "Your time is limited, don't waste it living someone else's life.", author: "Steve Jobs", categories: ["Life", "Wisdom"]),
        Quote(id: "4", text: "The future belongs to those who believe in the beauty of their dreams.", author: "Eleanor Roosevelt", categories: ["Dreams", "Future"]),
        Quote(id: "5", text: "Success is not final, failure is not fatal: it is the courage to continue that counts.", author: "Winston Churchill", categories: ["Success", "Courage"])
    ]
    
    var filteredQuotes: [Quote] {
        if searchText.isEmpty {
            return sampleQuotes
        } else {
            return sampleQuotes.filter { quote in
                quote.text.localizedCaseInsensitiveContains(searchText) ||
                quote.author?.localizedCaseInsensitiveContains(searchText) == true ||
                quote.categories.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 16) {
                    Text("QuoteWall AI")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    
                    Text("Create beautiful quote wallpapers")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    // Search Bar
                    TextField("Search quotes...", text: $searchText)
                        .textFieldStyle(.roundedBorder)
                        .submitLabel(.search)
                }
                .padding()
                .background(.ultraThinMaterial)
                
                // Quote List
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredQuotes) { quote in
                            QuoteCardView(quote: quote)
                                .onTapGesture {
                                    selectedQuote = quote
                                }
                        }
                    }
                    .padding()
                }
                
                if filteredQuotes.isEmpty && !searchText.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "quote.bubble")
                            .font(.system(size: 50))
                            .foregroundStyle(.secondary)
                        
                        Text("No quotes found")
                            .font(.headline)
                        
                        Text("Try a different search term")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gear")
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .navigationDestination(item: $selectedQuote) { quote in
                QuoteEditorView(quote: quote)
            }
        }
    }
}

struct QuoteCardView: View {
    let quote: Quote
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(quote.text)
                .font(.body)
                .fontWeight(.medium)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
            
            HStack {
                if let author = quote.author {
                    Text("— \(author)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    ForEach(quote.categories.prefix(2), id: \.self) { category in
                        Text(category)
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.quaternary)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

#Preview {
    ContentView()
}
