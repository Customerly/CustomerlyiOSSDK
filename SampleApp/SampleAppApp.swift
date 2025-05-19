import SwiftUI
import CustomerlySDK
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .list])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                            didReceive response: UNNotificationResponse,
                            withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        if let conversationId = userInfo["conversationId"] as? Int {
            Customerly.shared.navigateToConversation(conversationId: conversationId)
        }
        Customerly.shared.show(withoutNavigation: true)
        completionHandler()
    }
}

@main
struct SampleAppApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var newMessagesCount: Int = 0
    @State private var newConversationsCount: Int = 0
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                ScrollView {
                    VStack(spacing: 8) {
                        Button("Open Chat") {
                            Customerly.shared.show()
                        }
                        .padding()
                        
                        Button("Close Chat") {
                            Customerly.shared.hide()
                        }
                        .padding()
                        
                        Button("Login User") {
                            let settings = CustomerlySettings(
                                app_id: "936fd1dc",
                                user_id: "123",
                                name: "Giorgio",
                                email: "gb@customerly.io",
                            )
                            Customerly.shared.update(settings: settings)
                        }
                        .padding()
                        
                        Button("Logout User") {
                            Customerly.shared.logout()
                        }
                        .padding()
                        
                        Button("Send Event") {
                            Customerly.shared.event(name: "test_event")
                        }
                        .padding()
                        
                        Button("Set Attribute") {
                            Customerly.shared.attribute(name: "test_attribute", value: "test_value")
                        }
                        .padding()
                        
                        Button("Show New Message") {
                            Customerly.shared.showNewMessage(message: "Hello from SDK!")
                        }
                        .padding()
                        
                        Button("Send New Message") {
                            Customerly.shared.sendNewMessage(message: "Hello from SDK!")
                        }
                        .padding()
                        
                        Button("Show Article") {
                            Customerly.shared.showArticle(collectionSlug: "getting-started-with-help-center", articleSlug: "this-is-your-first-articleflex")
                        }
                        .padding()
                        
                        Button("Register Lead") {
                            Customerly.shared.registerLead(email: "lead@example.com", attributes: ["source": "sdk_test"])
                        }
                        .padding()
                        
                        Button("\(newMessagesCount) new messages") {
                            Customerly.shared.getUnreadMessagesCount { count in
                                newMessagesCount = count
                            }
                        }
                        .padding()
                        
                        Button("\(newConversationsCount) new conversations") {
                            Customerly.shared.getUnreadConversationsCount { count in
                                newConversationsCount = count
                            }
                        }
                        .padding()
                    }
                    .padding()
                }
                
                CustomerlyView(settings: CustomerlySettings(app_id: "936fd1dc")).onAppear(){
                    Customerly.shared.requestNotificationPermissionIfNeeded()
                    Customerly.shared.setOnMessengerInitialized {
                        Customerly.shared.getUnreadMessagesCount { count in
                            DispatchQueue.main.async {
                                newMessagesCount = count
                            }
                        }
                        Customerly.shared.getUnreadConversationsCount { count in
                            DispatchQueue.main.async {
                                newConversationsCount = count
                            }
                        }
                    }
                }
            }
        }
    }
}
