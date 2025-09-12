
import SwiftUI
import Splash

struct HighlightedJsonView: View {
    let data: Data?

    private static let highlighter = SyntaxHighlighter(format: AttributedStringOutputFormat(theme: .midnight(withFont: .init(size: 12))))

    

    var body: some View {
        ScrollView {
            Text(highlightedText())
                .font(DesignSystem.Typography.mono)
                .padding(DesignSystem.Spacing.lg)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(DesignSystem.Colors.backgroundSecondary)
        .cornerRadius(DesignSystem.CornerRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .stroke(DesignSystem.Colors.border, lineWidth: 1)
        )
        .frame(minHeight: 120, maxHeight: .infinity)
    }

    private func prettyPrintedJsonString() -> String {
        guard let data = data else { return "No data" }
        guard let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
              let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted) else {
            return String(data: data, encoding: .utf8) ?? "Failed to decode as UTF-8 string"
        }
        return String(data: prettyData, encoding: .utf8) ?? ""
    }

    private func highlightedText() -> AttributedString {
        let highlighted = Self.highlighter.highlight(prettyPrintedJsonString())
        return AttributedString(highlighted)
    }
    
    private func copyToClipboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(prettyPrintedJsonString(), forType: .string)
    }
}
