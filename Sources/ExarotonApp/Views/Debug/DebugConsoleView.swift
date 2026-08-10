import SwiftUI

struct DebugConsoleView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    @ObservedObject var logger = DebugLogger.shared
    
    @State private var selectedCategory: LogCategory? = nil
    
    var filteredLogs: [LogEntry] {
        if let cat = selectedCategory {
            return logger.logs.filter { $0.category == cat }
        }
        return logger.logs
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.05, green: 0.06, blue: 0.08).ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Category Filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            FilterChip(title: "ALL", isSelected: selectedCategory == nil) {
                                selectedCategory = nil
                            }
                            ForEach(LogCategory.allCases, id: \.self) { category in
                                FilterChip(title: category.rawValue, isSelected: selectedCategory == category) {
                                    selectedCategory = category
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 12)
                    }
                    .background(Color.black.opacity(0.2))
                    
                    // Logs List
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 8, alignment: .leading) {
                                ForEach(filteredLogs) { entry in
                                    LogEntryView(entry: entry)
                                        .id(entry.id)
                                }
                            }
                            .padding()
                        }
                        .onChange(of: logger.logs.count) { _, _ in
                            if let last = filteredLogs.last {
                                withAnimation {
                                    proxy.scrollTo(last.id, anchor: .bottom)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Developer Console")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color(red: 0.05, green: 0.06, blue: 0.08), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(Color(red: 0.3, green: 0.9, blue: 0.5))
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(role: .destructive) {
                        logger.clear()
                    } label: {
                        Image(systemName: "trash")
                            .foregroundStyle(.red)
                    }
                }
            }
        }
    }
}

// MARK: - Subviews

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(isSelected ? Color(red: 0.3, green: 0.9, blue: 0.5) : Color.white.opacity(0.1))
                .foregroundStyle(isSelected ? .black : .white)
                .clipShape(Capsule())
        }
    }
}

struct LogEntryView: View {
    let entry: LogEntry
    
    private var tagColor: Color {
        switch entry.category {
        case .system: return .gray
        case .network: return .blue
        case .websocket: return .purple
        case .error: return .red
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(entry.timestamp, style: .time)
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.5))
                
                Text(entry.category.rawValue)
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .foregroundStyle(tagColor)
                
                Spacer()
            }
            
            Text(entry.message)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(.white.opacity(0.9))
                .textSelection(.enabled)
        }
        .padding(10)
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
    }
}
