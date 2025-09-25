
import SwiftUI

struct JsonView: View {
    let title: String
    let data: Data?
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
            HStack {
                Text(title)
                    .font(DesignSystem.Typography.title)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
                
                Button(action: {
                    copyPayloadToClipboard(data)
                }) {
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 12))
                        Text("Copy")
                            .font(DesignSystem.Typography.caption)
                    }
                }
                .buttonStyle(LinearButtonStyle(variant: .ghost))
                .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            
            TextView(text: prettyPrintedJsonString(from: data))
                .frame(minHeight: 400)
        }
    }
    
    private func copyPayloadToClipboard(_ data: Data?) {
        guard let data = data else { return }
        
        let prettyJsonString: String
        if let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
           let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted) {
            prettyJsonString = String(data: prettyData, encoding: .utf8) ?? ""
        } else {
            prettyJsonString = String(data: data, encoding: .utf8) ?? ""
        }
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(prettyJsonString, forType: .string)
    }
    
    private func prettyPrintedJsonString(from data: Data?) -> String {
        guard let data = data else { return "No data" }
        
        if data.count > 1024 * 1024 { // 1MB limit
            return "Payload is too large to display (> 1MB). Please use the copy button."
        }

        guard let jsonObject = try? JSONSerialization.jsonObject(with: data, options: .allowFragments),
              let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted) else {
            return String(data: data, encoding: .utf8) ?? "Failed to decode as UTF-8 string"
        }
        return String(data: prettyData, encoding: .utf8) ?? ""
    }
}
