
import SwiftUI
import Splash

struct HighlightedJsonView: View {
    let data: Data?

    private static let highlighter = SyntaxHighlighter(format: AttributedStringOutputFormat(theme: .midnight(withFont: .init(size: 12))))

    

    var body: some View {
        ZStack(alignment: .topTrailing) {
            ScrollView {
                Text(highlightedText())
                    .font(.system(size: 12, design: .monospaced))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color(red: 15/255, green: 17/255, blue: 25/255))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
            )

            Button(action: copyToClipboard) {
                Image(systemName: "doc.on.doc")
            }
            .padding(8)
            .buttonStyle(PlainButtonStyle())
            .foregroundColor(.white)
        }
        .frame(minHeight: 100, maxHeight: .infinity)
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
