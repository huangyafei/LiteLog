
import SwiftUI
import AppKit // Import AppKit for NSApplication

struct AboutView: View {
    @Environment(\.openWindow) var openWindow
    
    var body: some View {
        VStack(spacing: 16) {
            Image(nsImage: NSApplication.shared.applicationIconImage)
                .resizable()
                .scaledToFit()
                .frame(width: 96, height: 96) // Adjust size as needed
            
            Text("LiteLog")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
            
            Text("Version 1.0 (Build 1)")
                .font(.system(size: 15))
                .foregroundColor(.gray)
            
            Text("© 2024 LiteLog. All rights reserved.")
                .font(.system(size: 12))
                .foregroundColor(.gray)
            
            Spacer()
        }
        .padding(.horizontal, 40)
        .padding(.top, 40)
        .padding(.bottom, 40)
        .frame(width: 400, height: 300)
        .background(Color.backgroundGradient)
    }
}

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        AboutView()
    }
}
