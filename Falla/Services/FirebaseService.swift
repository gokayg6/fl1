import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

// MARK: - Firebase Service (Singleton)
final class FirebaseService {
    static let shared = FirebaseService()
    
    private let auth = Auth.auth()
    private let firestore = Firestore.firestore()
    private let storage = Storage.storage()
    
    private init() {}
    
    // MARK: - Auth Properties
    var currentUser: User? { auth.currentUser }
    
    var authStateChanges: AsyncStream<User?> {
        AsyncStream { continuation in
            let handle = auth.addStateDidChangeListener { _, user in
                continuation.yield(user)
            }
            continuation.onTermination = { _ in
                self.auth.removeStateDidChangeListener(handle)
            }
        }
    }
    
    func removeAuthStateListener(_ handle: AuthStateDidChangeListenerHandle) {
        auth.removeStateDidChangeListener(handle)
    }
    
    // MARK: - Auth Methods
    func signInAnonymously() async throws -> AuthDataResult {
        try await auth.signInAnonymously()
    }
    
    func signInWithEmail(_ email: String, password: String) async throws -> AuthDataResult {
        try await auth.signIn(withEmail: email, password: password)
    }
    
    func signUpWithEmail(_ email: String, password: String) async throws -> AuthDataResult {
        try await auth.createUser(withEmail: email, password: password)
    }
    
    func signOut() throws {
        try auth.signOut()
    }
    
    func resetPassword(email: String) async throws {
        try await auth.sendPasswordReset(withEmail: email)
    }
    
    // MARK: - User Profile Methods
    func createUserProfile(userId: String, userData: [String: Any]) async throws {
        try await firestore.collection("users").document(userId).setData(userData)
    }
    
    func getUserProfile(userId: String) async throws -> DocumentSnapshot? {
        let doc = try await firestore.collection("users").document(userId).getDocument()
        return doc.exists ? doc : nil
    }
    
    func updateUserProfile(userId: String, data: [String: Any]) async throws {
        try await firestore.collection("users").document(userId).updateData(data)
    }
    
    func getUserProfileStream(userId: String) -> AsyncStream<DocumentSnapshot?> {
        AsyncStream { continuation in
            let listener = firestore.collection("users").document(userId)
                .addSnapshotListener { snapshot, error in
                    if let error = error {
                        print("Error listening to user profile: \(error)")
                        continuation.yield(nil)
                    } else {
                        continuation.yield(snapshot)
                    }
                }
            continuation.onTermination = { _ in
                listener.remove()
            }
        }
    }
    
    // MARK: - Karma Methods
    func updateKarma(userId: String, amount: Int, reason: String) async throws {
        let userRef = firestore.collection("users").document(userId)
        
        try await firestore.runTransaction { transaction, errorPointer in
            let userDoc: DocumentSnapshot
            do {
                userDoc = try transaction.getDocument(userRef)
            } catch let error as NSError {
                errorPointer?.pointee = error
                return nil
            }
            
            guard userDoc.exists else {
                let error = NSError(domain: "FirebaseService", code: -1, 
                                   userInfo: [NSLocalizedDescriptionKey: "Kullanıcı bulunamadı"])
                errorPointer?.pointee = error
                return nil
            }
            
            let currentKarma = userDoc.data()?["karma"] as? Int ?? 0
            let newKarma = currentKarma + amount
            
            if newKarma < 0 {
                let error = NSError(domain: "FirebaseService", code: -2,
                                   userInfo: [NSLocalizedDescriptionKey: "Yetersiz karma puanı"])
                errorPointer?.pointee = error
                return nil
            }
            
            transaction.updateData([
                "karma": newKarma,
                "lastKarmaUpdate": FieldValue.serverTimestamp()
            ], forDocument: userRef)
            
            return nil
        }
        
        // Add karma transaction record
        try await addKarmaTransaction(userId: userId, amount: amount, reason: reason)
    }
    
    func addKarmaTransaction(userId: String, amount: Int, reason: String) async throws {
        try await firestore.collection("users").document(userId)
            .collection("karma_transactions")
            .addDocument(data: [
                "amount": amount,
                "reason": reason,
                "timestamp": FieldValue.serverTimestamp()
            ])
    }
    
    // MARK: - Fortune Methods
    func saveFortune(userId: String, fortuneData: [String: Any]) async throws -> String {
        let docRef = try await firestore.collection("users").document(userId)
            .collection("fortunes")
            .addDocument(data: fortuneData)
        return docRef.documentID
    }
    
    func getUserFortunes(userId: String) async throws -> [FortuneModel] {
        let snapshot = try await firestore.collection("users").document(userId)
            .collection("fortunes")
            .order(by: "createdAt", descending: true)
            .getDocuments()
        
        return snapshot.documents.map { doc in
            FortuneModel(id: doc.documentID, data: doc.data())
        }
    }
    
    func getUserFortunesFromReadings(userId: String) async throws -> [QueryDocumentSnapshot] {
        let snapshot = try await firestore.collection("fortune_readings")
            .whereField("userId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        return snapshot.documents
    }
    
    func getFortune(userId: String, fortuneId: String) async throws -> DocumentSnapshot? {
        let doc = try await firestore.collection("users").document(userId)
            .collection("fortunes")
            .document(fortuneId)
            .getDocument()
        return doc.exists ? doc : nil
    }
    
    func updateFortune(userId: String, fortuneId: String, data: [String: Any]) async throws {
        try await firestore.collection("users").document(userId)
            .collection("fortunes")
            .document(fortuneId)
            .updateData(data)
    }
    
    func deleteFortune(userId: String, fortuneId: String) async throws {
        try await firestore.collection("users").document(userId)
            .collection("fortunes")
            .document(fortuneId)
            .delete()
    }
    
    // MARK: - Dream Draw Methods
    func saveDreamDraw(userId: String, data: [String: Any]) async throws -> String {
        let docRef = try await firestore.collection("users").document(userId)
            .collection("dream_draws")
            .addDocument(data: data)
        return docRef.documentID
    }
    
    func getDreamDraws(userId: String) async throws -> [QueryDocumentSnapshot] {
        let snapshot = try await firestore.collection("users").document(userId)
            .collection("dream_draws")
            .order(by: "createdAt", descending: true)
            .getDocuments()
        return snapshot.documents
    }
    
    // MARK: - Storage Methods
    func uploadImage(path: String, imageData: Data) async throws -> String {
        let storageRef = storage.reference().child(path)
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
        let downloadURL = try await storageRef.downloadURL()
        return downloadURL.absoluteString
    }
    
    func deleteImage(url: String) async throws {
        let storageRef = storage.reference(forURL: url)
        try await storageRef.delete()
    }
    
    // MARK: - Daily Check Methods
    func checkDailyLogin(userId: String) async throws -> Bool {
        let today = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-M-d"
        let todayString = formatter.string(from: today)
        
        let doc = try await firestore.collection("users").document(userId)
            .collection("daily_activities")
            .document(todayString)
            .getDocument()
        
        return doc.exists
    }
    
    func recordDailyLogin(userId: String) async throws {
        let today = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-M-d"
        let todayString = formatter.string(from: today)
        
        try await firestore.collection("users").document(userId)
            .collection("daily_activities")
            .document(todayString)
            .setData([
                "login": true,
                "timestamp": FieldValue.serverTimestamp()
            ])
    }
}
