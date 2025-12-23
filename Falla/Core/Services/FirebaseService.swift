import Foundation
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore

// MARK: - Firebase Service
class FirebaseService {
    static let shared = FirebaseService()
    
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    
    private init() {}
    
    // MARK: - Auth State
    var currentUser: User? {
        auth.currentUser
    }
    
    var isAuthenticated: Bool {
        currentUser != nil
    }
    
    // MARK: - Sign In with Email
    func signInWithEmail(email: String, password: String) async throws -> User {
        let result = try await auth.signIn(withEmail: email, password: password)
        return result.user
    }
    
    // MARK: - Sign Up with Email
    func signUpWithEmail(
        email: String,
        password: String,
        displayName: String
    ) async throws -> User {
        let result = try await auth.createUser(withEmail: email, password: password)
        
        // Update display name
        let changeRequest = result.user.createProfileChangeRequest()
        changeRequest.displayName = displayName
        try await changeRequest.commitChanges()
        
        // Create user document in Firestore
        try await createUserDocument(user: result.user, displayName: displayName)
        
        return result.user
    }
    
    // MARK: - Sign In Anonymously
    func signInAnonymously() async throws -> User {
        let result = try await auth.signInAnonymously()
        return result.user
    }
    
    // MARK: - Sign Out
    func signOut() throws {
        try auth.signOut()
    }
    
    // MARK: - Reset Password
    func resetPassword(email: String) async throws {
        try await auth.sendPasswordReset(withEmail: email)
    }
    
    // MARK: - Firestore Operations
    private func createUserDocument(user: User, displayName: String) async throws {
        let userData: [String: Any] = [
            "id": user.uid,
            "email": user.email ?? "",
            "displayName": displayName,
            "isPremium": false,
            "credits": 0,
            "createdAt": Timestamp(date: Date()),
            "lastLoginAt": Timestamp(date: Date())
        ]
        
        try await db.collection("users").document(user.uid).setData(userData)
    }
    
    func getUserDocument(userId: String) async throws -> UserModel? {
        let document = try await db.collection("users").document(userId).getDocument()
        
        guard let data = document.data() else { return nil }
        
        return UserModel(
            id: data["id"] as? String ?? userId,
            email: data["email"] as? String ?? "",
            displayName: data["displayName"] as? String ?? "",
            photoURL: data["photoURL"] as? String,
            birthDate: (data["birthDate"] as? Timestamp)?.dateValue(),
            zodiacSign: data["zodiacSign"] as? String,
            gender: data["gender"] as? String,
            isPremium: data["isPremium"] as? Bool ?? false,
            credits: data["credits"] as? Int ?? 0,
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
            lastLoginAt: (data["lastLoginAt"] as? Timestamp)?.dateValue()
        )
    }
    
    func updateUserDocument(userId: String, data: [String: Any]) async throws {
        try await db.collection("users").document(userId).updateData(data)
    }
    
    // MARK: - Auth State Listener
    func addAuthStateListener(_ listener: @escaping (User?) -> Void) -> AuthStateDidChangeListenerHandle {
        return auth.addStateDidChangeListener { _, user in
            listener(user)
        }
    }
    
    func removeAuthStateListener(_ handle: AuthStateDidChangeListenerHandle) {
        auth.removeStateDidChangeListener(handle)
    }
}
