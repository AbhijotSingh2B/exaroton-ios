import SwiftUI

// MARK: - Console Line View
// Parses basic ANSI color codes and renders colored text.

struct ConsoleLineView: View {
    let line: String

    var body: some View {
        Text(attributedLine)
            .font(.system(size: 12, weight: .regular, design: .monospaced))
            .frame(maxWidth: .infinity, alignment: .leading)
            .textSelection(.enabled)
    }

    // MARK: ANSI Parser

    private var attributedLine: AttributedString {
        var result = AttributedString()
        let cleaned = stripANSI(line)
        var attr = AttributedString(cleaned)
        attr.foregroundColor = lineColor(for: cleaned)
        attr.font = .system(size: 12, weight: .regular, design: .monospaced)
        result.append(attr)
        return result
    }

    private func stripANSI(_ input: String) -> String {
        // Remove ESC[...m sequences
        let pattern = "\u{1B}\\[[0-9;]*m"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(input.startIndex..., in: input)
        return regex?.stringByReplacingMatches(in: input, range: range, withTemplate: "") ?? input
    }

    private func lineColor(for line: String) -> Color {
        let l = line.lowercased()
        if l.contains("[error]") || l.contains("[severe]") || l.contains("exception") || l.contains("caused by") {
            return Color(red: 1.0, green: 0.4, blue: 0.4)
        } else if l.contains("[warn]") {
            return Color(red: 1.0, green: 0.8, blue: 0.3)
        } else if l.contains("[info]") {
            return Color(white: 0.85)
        } else if l.contains("done") || l.contains("started") {
            return Color(red: 0.4, green: 1.0, blue: 0.6)
        }
        return Color(white: 0.7)
    }
}
