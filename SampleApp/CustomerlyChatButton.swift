import SwiftUI
import CustomerlySDK

/// A SwiftUI wrapper to present the Customerly WebView from a UIKit ViewController
struct CustomerlyChatButton: View {
    @Environment(\.window) var window
    var body: some View {
        Button("Open Messenger") {
            print("Customerly: Button tapped")
            if let rootVC = window?.rootViewController {
                print("Customerly: Showing messenger...")
                Customerly.shared.show(on: rootVC)
            } else {
                print("Customerly: Error - No root view controller found")
            }
        }
        .onAppear() {
            print("Customerly: Initializing SDK...")
            let settings = CustomerlySettings(app_id: "936fd1dc")
            Customerly.shared.load(settings: settings)
            Customerly.shared.requestNotificationPermissionIfNeeded()
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
