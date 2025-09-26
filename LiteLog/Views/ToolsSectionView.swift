
import SwiftUI

// Main container view for the "Tools" section
struct ToolsSectionView: View {
    let toolDefinitions: [ToolDefinition]
    let calledToolNames: Set<String>

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack {
                SectionHeader(title: "Tools")
                Spacer()
            }

            LazyVStack(spacing: DesignSystem.Spacing.sm) {
                ForEach(toolDefinitions) { tool in
                    ToolDefinitionRowView(
                        toolDefinition: tool,
                        isCalled: calledToolNames.contains(tool.function.name)
                    )
                }
            }
        }
    }
}

// A single collapsible row for a tool definition
struct ToolDefinitionRowView: View {
    let toolDefinition: ToolDefinition
    let isCalled: Bool
    @State private var isExpanded: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            DisclosureGroup(isExpanded: $isExpanded) {
                // Expanded content
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                    if let description = toolDefinition.function.description, !description.isEmpty {
                        Text(description)
                            .font(DesignSystem.Typography.body)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                            .padding(.bottom, DesignSystem.Spacing.sm)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if let parameters = toolDefinition.function.parameters,
                       let properties = parameters.properties,
                       !properties.isEmpty {
                        
                        ForEach(properties.keys.sorted(), id: \.self) { key in
                            if let property = properties[key] {
                                ParameterRowView(name: key, property: property)
                            }
                        }
                    }
                }
                .padding(.top, DesignSystem.Spacing.sm) // Add spacing between label and content
                
            } label: {
                // Label for the collapsible row
                HStack {
                    Text(toolDefinition.function.name)
                        .font(DesignSystem.Typography.bodyMedium)
                        .foregroundColor(DesignSystem.Colors.textPrimary)

                    if isCalled {
                        Text("CALLED")
                            .font(DesignSystem.Typography.caption.bold())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(DesignSystem.Colors.success)
                            .foregroundColor(.white)
                            .cornerRadius(DesignSystem.CornerRadius.sm)
                    }

                    Spacer()

                    Button(action: {
                        copyToClipboard(toolDefinition.function.name)
                    }) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 12))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .contentShape(Rectangle()) // Make the whole H-stack tappable for the disclosure group
                .onTapGesture {
                    withAnimation {
                        isExpanded.toggle()
                    }
                }
            }
            .accentColor(DesignSystem.Colors.textPrimary)
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.surface)
        .cornerRadius(DesignSystem.CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                .stroke(DesignSystem.Colors.border, lineWidth: 1)
        )
    }
    
    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
}

// A view for displaying a single parameter
struct ParameterRowView: View {
    let name: String
    let property: PropertyDefinition

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text(name)
                .font(DesignSystem.Typography.bodyMedium)
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .padding(.bottom, DesignSystem.Spacing.xs)
            
            Grid(alignment: .leading, horizontalSpacing: DesignSystem.Spacing.lg, verticalSpacing: DesignSystem.Spacing.sm) {
                GridRow {
                    Text("Type")
                    Text(property.type)
                }
                
                if let description = property.description, !description.isEmpty {
                    GridRow(alignment: .top) {
                        Text("Description")
                        Text(description)
                    }
                }
            }
            .font(DesignSystem.Typography.body)
            .foregroundColor(DesignSystem.Colors.textSecondary)
        }
        .padding(DesignSystem.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignSystem.Colors.backgroundSecondary)
        .cornerRadius(DesignSystem.CornerRadius.sm)
    }
}

// Helper for corner radius on specific corners
struct RectCorner: OptionSet {
    let rawValue: Int

    static let topLeft = RectCorner(rawValue: 1 << 0)
    static let topRight = RectCorner(rawValue: 1 << 1)
    static let bottomLeft = RectCorner(rawValue: 1 << 2)
    static let bottomRight = RectCorner(rawValue: 1 << 3)
    
    static let allCorners: RectCorner = [.topLeft, .topRight, .bottomLeft, .bottomRight]
}

struct RoundedCornerShape: Shape {
    var radius: CGFloat = .infinity
    var corners: RectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let w = rect.size.width
        let h = rect.size.height
        let r = min(min(self.radius, h/2), w/2)

        let tr = corners.contains(.topRight) ? r : 0
        let tl = corners.contains(.topLeft) ? r : 0
        let bl = corners.contains(.bottomLeft) ? r : 0
        let br = corners.contains(.bottomRight) ? r : 0

        path.move(to: CGPoint(x: w / 2.0, y: 0))
        path.addLine(to: CGPoint(x: w - tr, y: 0))
        path.addArc(center: CGPoint(x: w - tr, y: tr), radius: tr, startAngle: Angle(degrees: -90), endAngle: Angle(degrees: 0), clockwise: false)
        path.addLine(to: CGPoint(x: w, y: h - br))
        path.addArc(center: CGPoint(x: w - br, y: h - br), radius: br, startAngle: Angle(degrees: 0), endAngle: Angle(degrees: 90), clockwise: false)
        path.addLine(to: CGPoint(x: bl, y: h))
        path.addArc(center: CGPoint(x: bl, y: h - bl), radius: bl, startAngle: Angle(degrees: 90), endAngle: Angle(degrees: 180), clockwise: false)
        path.addLine(to: CGPoint(x: 0, y: tl))
        path.addArc(center: CGPoint(x: tl, y: tl), radius: tl, startAngle: Angle(degrees: 180), endAngle: Angle(degrees: 270), clockwise: false)
        path.closeSubpath()

        return path
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: RectCorner) -> some View {
        clipShape(RoundedCornerShape(radius: radius, corners: corners))
    }
}
