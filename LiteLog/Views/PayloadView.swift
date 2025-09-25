
import SwiftUI

struct PayloadView: View {
    let requestPayload: Data?
    let responsePayload: Data?

    @State private var selectedView: ViewType = .formatted

    enum ViewType: String, CaseIterable, CustomStringConvertible {
        case formatted = "Formatted"
        case json = "JSON"
        
        var description: String {
            return self.rawValue
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxl) {
            LinearPicker(selection: $selectedView, options: ViewType.allCases)
                .frame(maxWidth: .infinity, alignment: .leading)

            if selectedView == .formatted {
                FormattedView(requestPayload: requestPayload, responsePayload: responsePayload)
            } else {
                JsonView(title: "Request Payload", data: requestPayload)
                JsonView(title: "Response Payload", data: responsePayload)
            }
        }
        .padding(DesignSystem.Spacing.xl)
        .linearCard()
    }
}
