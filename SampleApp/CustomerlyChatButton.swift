import SwiftUI
import CustomerlySDK

/// A SwiftUI wrapper to present the Customerly WebView from a UIKit ViewController
struct CustomerlyChatButton: View {
    @Environment(\.window) var window
    var body: some View {
        Button("Open Messenger") {
            print("Customerly: Button tapped")
            Customerly.shared.show()
        }
        .onAppear() {
            print("Customerly: Initializing SDK...")
            // FIXME
            if let rootVC = window?.rootViewController {
                let settings = CustomerlySettings(app_id: "936fd1dc")
                Customerly.shared.load(parent: rootVC, settings: settings)
                Customerly.shared.requestNotificationPermissionIfNeeded()
            } else {
                print("Customerly: Error - No root view controller found")
            }
        }
        .padding()
    }
}

// Helper to access the window from SwiftUI
private struct WindowAccessor: UIViewRepresentable {
    @Binding var window: UIWindow?
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        DispatchQueue.main.async {
            self.window = view.window
        }
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}

private struct WindowEnvironmentKey: EnvironmentKey {
    static let defaultValue: UIWindow? = nil
}

extension EnvironmentValues {
    var window: UIWindow? {
        get { self[WindowEnvironmentKey.self] }
        set { self[WindowEnvironmentKey.self] = newValue }
    }
}

extension View {
    func injectWindow(_ window: Binding<UIWindow?>) -> some View {
        background(WindowAccessor(window: window))
            .environment(\.window, window.wrappedValue)
    }
}
