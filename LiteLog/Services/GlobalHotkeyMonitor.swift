
import SwiftUI
import Carbon

class GlobalHotkeyMonitor {
    private var eventMonitor: Any?
    private var hotKeyRef: EventHotKeyRef?

    func start() {
        let hotKeyID = EventHotKeyID(signature: "LiteLog".fourCharID, id: 1)
        
        // Register Cmd+Shift+L
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: OSType(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { (nextHandler, event, userData) -> OSStatus in
            if let monitor = userData?.assumingMemoryBound(to: GlobalHotkeyMonitor.self).pointee {
                monitor.handleHotkey()
            }
            return noErr
        }, 1, &eventType, Unmanaged.passUnretained(self).toOpaque(), nil)

        let modifiers = UInt32(cmdKey | shiftKey)
        let keyCode = UInt32(kVK_ANSI_L)
        
        RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
    }

    func stop() {
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
    }

    private func handleHotkey() {
        // Post a notification to let the SwiftUI layer handle the window toggling.
        // This is more robust than trying to manage AppKit windows directly from here.
        NotificationCenter.default.post(name: .toggleMainWindow, object: nil)
    }
}

extension String {
    var fourCharID: FourCharCode {
        return self.utf16.reduce(0, {$0 << 8 + FourCharCode($1)})
    }
}
