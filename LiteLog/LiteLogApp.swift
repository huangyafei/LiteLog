
import SwiftUI

@main
struct LiteLogApp: App {
    @StateObject private var appEnvironment = AppEnvironment()
    @StateObject private var contentViewModel: ContentViewModel
    @Environment(\.openWindow) var openWindow
    private let hotkeyMonitor = GlobalHotkeyMonitor()

    // 使用 @AppStorage 存储主窗口的尺寸
    @AppStorage("mainWindowWidth") var mainWindowWidth: Double = 1200
    @AppStorage("mainWindowHeight") var mainWindowHeight: Double = 800

    init() {
        let env = AppEnvironment()
        _appEnvironment = StateObject(wrappedValue: env)
        _contentViewModel = StateObject(wrappedValue: ContentViewModel(appEnvironment: env))

        // 确保应用能够成为前台应用并激活菜单栏
        DispatchQueue.main.async {
            NSApplication.shared.setActivationPolicy(.regular)
            NSApplication.shared.activate(ignoringOtherApps: true)
        }
        hotkeyMonitor.start()
    }

    var body: some Scene {
        WindowGroup(id: "main") {
            ContentView(viewModel: contentViewModel)
                .environmentObject(appEnvironment)
                .onReceive(NotificationCenter.default.publisher(for: .settingsDidChange)) { _ in
                    appEnvironment.loadApiService()
                }
                .observeWindowSize(width: $mainWindowWidth, height: $mainWindowHeight) // 观察并保存窗口尺寸
                .onReceive(NotificationCenter.default.publisher(for: .toggleMainWindow)) { _ in
                    toggleMainWindow()
                }
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: mainWindowWidth, height: mainWindowHeight) // 应用存储的尺寸
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About LiteLog") {
                    openWindow(id: "about")
                }
            }

            CommandMenu("LiteLog") {
                Button("Quit LiteLog") {
                    NSApplication.shared.terminate(nil)
                }.keyboardShortcut("q", modifiers: .command)
            }
            
            CommandGroup(replacing: .appSettings) {
                Button("Settings...") {
                   openWindow(id: "settings")
                }
                .keyboardShortcut(",", modifiers: .command)
            }
            
            CommandGroup(replacing: .help) {
                Button("LiteLog Help") {
                    if let url = URL(string: "https://github.com/huangyafei/LiteLog") {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
        }
        
        Window("Settings", id: "settings") {
            SettingsView()
        }
        .windowResizability(.contentSize)

        Window("About LiteLog", id: "about") {
            AboutView()
        }
        .windowResizability(.contentSize)
        .windowStyle(.hiddenTitleBar)
    }
    
    private func toggleMainWindow() {
        // Find the main window
        if let window = NSApp.windows.first(where: { $0.canBecomeMain && $0.isVisible }) {
            // If it's visible and key, hide it.
            window.orderOut(nil)
        } else {
            // If the window is not visible, first activate the app to bring it to the front.
            NSRunningApplication.current.activate(options: [.activateIgnoringOtherApps])
            // Then, use the SwiftUI way to open the window.
            openWindow(id: "main")
        }
    }
}
