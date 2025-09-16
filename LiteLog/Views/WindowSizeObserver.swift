
import SwiftUI
import AppKit

struct WindowSizeObserver: ViewModifier {
    @Binding var width: Double
    @Binding var height: Double

    func body(content: Content) -> some View {
        content
            .background(
                WindowAccessor(width: $width, height: $height)
            )
    }
}

private struct WindowAccessor: NSViewRepresentable {
    @Binding var width: Double
    @Binding var height: Double

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                context.coordinator.setup(window: window)
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(width: $width, height: $height)
    }

    class Coordinator: NSObject {
        @Binding var width: Double
        @Binding var height: Double
        private var window: NSWindow?

        init(width: Binding<Double>, height: Binding<Double>) {
            _width = width
            _height = height
        }

        func setup(window: NSWindow) {
            self.window = window
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(windowDidResize),
                                                   name: NSWindow.didResizeNotification,
                                                   object: window)
            // Set initial size
            updateSize(window: window)
        }

        @objc private func windowDidResize(_ notification: Notification) {
            if let window = notification.object as? NSWindow {
                updateSize(window: window)
            }
        }

        private func updateSize(window: NSWindow) {
            let frame = window.frame
            DispatchQueue.main.async {
                self.width = frame.size.width
                self.height = frame.size.height
            }
        }

        deinit {
            if let window = window {
                NotificationCenter.default.removeObserver(self,
                                                          name: NSWindow.didResizeNotification,
                                                          object: window)
            }
        }
    }
}

extension View {
    func observeWindowSize(width: Binding<Double>, height: Binding<Double>) -> some View {
        self.modifier(WindowSizeObserver(width: width, height: height))
    }
}
