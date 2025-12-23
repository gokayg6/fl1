import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authProvider: AuthProvider
    
    var body: some View {
        Group {
            if authProvider.isAuthenticated {
                MainScreen()
            } else {
                GetStartedScreen()
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthProvider())
        .environmentObject(ThemeProvider())
}
