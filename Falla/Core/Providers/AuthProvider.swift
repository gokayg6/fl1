import Foundation
import Combine
import FirebaseAuth

// MARK: - Auth Provider
class AuthProvider: ObservableObject {
    @Published var currentUser: UserModel?
    @Published var isAuthenticated: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let firebaseService = FirebaseService.shared
    private var authStateHandle: AuthStateDidChangeListenerHandle?
    
    init() {
        setupAuthStateListener()
    }
    
    deinit {
        if let handle = authStateHandle {
            firebaseService.removeAuthStateListener(handle)
        }
    }
    
    // MARK: - Auth State Listener
    private func setupAuthStateListener() {
        authStateHandle = firebaseService.addAuthStateListener { [weak self] user in
            Task { @MainActor in
                if let user = user {
                    self?.isAuthenticated = true
                    await self?.fetchUserData(userId: user.uid)
                } else {
                    self?.isAuthenticated = false
                    self?.currentUser = nil
                }
            }
        }
    }
    
    private func fetchUserData(userId: String) async {
        do {
            if let userModel = try await firebaseService.getUserDocument(userId: userId) {
                await MainActor.run {
                    self.currentUser = userModel
                }
            }
        } catch {
            print("Error fetching user data: \(error)")
        }
    }
    
    // MARK: - Sign In with Email
    func signInWithEmail(email: String, password: String) async -> Bool {
        await MainActor.run { 
            isLoading = true 
            errorMessage = nil
        }
        
        do {
            let user = try await firebaseService.signInWithEmail(email: email, password: password)
            await fetchUserData(userId: user.uid)
            
            await MainActor.run {
                isLoading = false
                isAuthenticated = true
            }
            return true
        } catch {
            await MainActor.run {
                isLoading = false
                errorMessage = error.localizedDescription
            }
            return false
        }
    }
    
    // MARK: - Sign Up with Email
    func signUpWithEmail(
        email: String,
        password: String,
        displayName: String,
        birthDate: Date? = nil,
        zodiacSign: String? = nil,
        gender: String? = nil
    ) async -> Bool {
        await MainActor.run { 
            isLoading = true 
            errorMessage = nil
        }
        
        do {
            let user = try await firebaseService.signUpWithEmail(
                email: email,
                password: password,
                displayName: displayName
            )
            
            await MainActor.run {
                isLoading = false
                isAuthenticated = true
                currentUser = UserModel(
                    id: user.uid,
                    email: email,
                    displayName: displayName,
                    birthDate: birthDate,
                    zodiacSign: zodiacSign,
                    gender: gender
                )
            }
            return true
        } catch {
            await MainActor.run {
                isLoading = false
                errorMessage = error.localizedDescription
            }
            return false
        }
    }
    
    // MARK: - Sign In with Google
    func signInWithGoogle() async -> Bool {
        await MainActor.run { 
            isLoading = true 
            errorMessage = nil
        }
        
        // TODO: Implement Google Sign In with Firebase
        // Requires GoogleSignIn SDK integration
        
        await MainActor.run {
            isLoading = false
            errorMessage = "Google Sign In coming soon"
        }
        
        return false
    }
    
    // MARK: - Sign In Anonymously (Guest)
    func signInAnonymously(birthDate: Date? = nil) async -> Bool {
        await MainActor.run { 
            isLoading = true 
            errorMessage = nil
        }
        
        do {
            let user = try await firebaseService.signInAnonymously()
            
            await MainActor.run {
                isLoading = false
                isAuthenticated = true
                currentUser = UserModel(
                    id: user.uid,
                    birthDate: birthDate
                )
            }
            return true
        } catch {
            await MainActor.run {
                isLoading = false
                errorMessage = error.localizedDescription
            }
            return false
        }
    }
    
    // MARK: - Sign Out
    func signOut() {
        do {
            try firebaseService.signOut()
            currentUser = nil
            isAuthenticated = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Reset Password
    func resetPassword(email: String) async -> Bool {
        await MainActor.run { 
            isLoading = true 
            errorMessage = nil
        }
        
        do {
            try await firebaseService.resetPassword(email: email)
            
            await MainActor.run {
                isLoading = false
            }
            return true
        } catch {
            await MainActor.run {
                isLoading = false
                errorMessage = error.localizedDescription
            }
            return false
        }
    }
}
