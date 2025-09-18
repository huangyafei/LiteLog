
import SwiftUI
import AppKit

struct TextView: NSViewRepresentable {
    var text: String
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        let textView = NSTextView()
        
        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false

        textView.autoresizingMask = [.width, .height]
        
        textView.string = text
        textView.isEditable = false
        textView.isSelectable = true
        textView.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        textView.textColor = NSColor(DesignSystem.Colors.textPrimary)
        textView.backgroundColor = NSColor(DesignSystem.Colors.backgroundSecondary)
        textView.textContainerInset = NSSize(width: 10, height: 10)
        
        return scrollView
    }
    
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        if let textView = nsView.documentView as? NSTextView {
            if textView.string != text {
                textView.string = text
                textView.scrollToBeginningOfDocument(nil)
            }
        }
    }
}
