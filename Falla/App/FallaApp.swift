import SwiftUI
import FirebaseCore

// MARK: - App Delegate for Firebase
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

// MARK: - Main App
@main
struct FallaApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authProvider = AuthProvider()
    @StateObject private var themeProvider = ThemeProvider()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authProvider)
                .environmentObject(themeProvider)
                .preferredColorScheme(.dark)
        }
    }
}
