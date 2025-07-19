import SwiftUI

struct QuoteEditorView: View {
    let quote: Quote
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Quote Editor")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Coming Soon!")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Selected Quote:")
                        .font(.headline)
                    
                    Text(quote.text)
                        .font(.body)
                        .padding()
                        .background(.quaternary)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    if let author = quote.author {
                        Text("— \(author)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    QuoteEditorView(quote: Quote(text: "Sample quote", author: "Author", categories: ["Test"]))
} 