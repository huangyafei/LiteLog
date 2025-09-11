
import SwiftUI

@main
struct LiteLogApp: App {
    @StateObject private var appEnvironment = AppEnvironment()
    @Environment(\.openWindow) var openWindow

    init() {
        // 确保应用能够成为前台应用并激活菜单栏
        DispatchQueue.main.async {
            NSApplication.shared.setActivationPolicy(.regular)
            NSApplication.shared.activate(ignoringOtherApps: true)
        }
    }

    var body: some Scene {
        WindowGroup(id: "main") {
            ContentView()
                .environmentObject(appEnvironment)
                .onReceive(NotificationCenter.default.publisher(for: .settingsDidChange)) { _ in
                    appEnvironment.loadApiService()
                }
                .onAppear {
                    // 窗口出现时再次激活应用
                    NSApplication.shared.activate(ignoringOtherApps: true)
                }
        }
        .commands {
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
        }
        
        Window("Settings", id: "settings") {
            SettingsView()
        }
        .windowResizability(.contentSize)
    }
}
