import Foundation
import FirebaseFirestore

// MARK: - Fortune Type
enum FortuneType: String, CaseIterable, Codable {
    case tarot = "tarot"
    case coffee = "coffee"
    case palm = "palm"
    case astrology = "astrology"
    case face = "face"
    case katina = "katina"
    case dream = "dream"
    case daily = "daily"
    
    var displayName: String {
        switch self {
        case .tarot: return "Tarot Falı"
        case .coffee: return "Kahve Falı"
        case .palm: return "El Falı"
        case .astrology: return "Astroloji"
        case .face: return "Yüz Analizi"
        case .katina: return "Katina Falı"
        case .dream: return "Rüya Yorumu"
        case .daily: return "Günlük Fal"
        }
    }
    
    var iconName: String {
        switch self {
        case .tarot: return "icon_tarot"
        case .coffee: return "icon_coffee"
        case .palm: return "icon_palm"
        case .astrology: return "icon_astrology"
        case .face: return "icon_face"
        case .katina: return "icon_katina"
        case .dream: return "icon_water"
        case .daily: return "icon_astrology"
        }
    }
    
    var colorHex: String {
        switch self {
        case .tarot: return "#C97CF6"
        case .coffee: return "#C4A477"
        case .palm: return "#9B8ED0"
        case .astrology: return "#E6D3A3"
        case .face: return "#7CB342"
        case .katina: return "#5DADE2"
        case .dream: return "#7C6FA8"
        case .daily: return "#FFD700"
        }
    }
}

// MARK: - Fortune Status
enum FortuneStatus: String, Codable {
    case pending = "pending"
    case completed = "completed"
    case failed = "failed"
}

// MARK: - Fortune Model
struct FortuneModel: Identifiable, Codable {
    let id: String
    let userId: String
    let type: FortuneType
    let status: FortuneStatus
    let title: String
    let interpretation: String
    let inputData: [String: String]
    let selectedCards: [String]
    let imageUrls: [String]
    let question: String?
    let fortuneTellerId: String?
    let createdAt: Date
    let completedAt: Date?
    var isFavorite: Bool
    var rating: Int
    let notes: String?
    let isForSelf: Bool
    let targetPersonName: String?
    let metadata: [String: String]
    let karmaUsed: Int
    let isPremium: Bool
    
    // MARK: - Init from Firestore
    init(id: String, data: [String: Any]) {
        self.id = id
        self.userId = data["userId"] as? String ?? ""
        
        let typeString = (data["type"] as? String ?? "tarot").lowercased()
        self.type = FortuneType(rawValue: typeString) ?? .tarot
        
        let statusString = (data["status"] as? String ?? "completed").lowercased()
        self.status = FortuneStatus(rawValue: statusString) ?? .completed
        
        self.title = data["title"] as? String ?? ""
        self.interpretation = data["interpretation"] as? String ?? ""
        self.inputData = data["inputData"] as? [String: String] ?? [:]
        self.selectedCards = data["selectedCards"] as? [String] ?? []
        self.imageUrls = data["imageUrls"] as? [String] ?? []
        self.question = data["question"] as? String
        self.fortuneTellerId = data["fortuneTellerId"] as? String
        
        // Handle Firestore Timestamp
        if let timestamp = data["createdAt"] as? Timestamp {
            self.createdAt = timestamp.dateValue()
        } else {
            self.createdAt = Date()
        }
        
        if let timestamp = data["completedAt"] as? Timestamp {
            self.completedAt = timestamp.dateValue()
        } else {
            self.completedAt = nil
        }
        
        self.isFavorite = data["isFavorite"] as? Bool ?? false
        self.rating = data["rating"] as? Int ?? 0
        self.notes = data["notes"] as? String
        self.isForSelf = data["isForSelf"] as? Bool ?? true
        self.targetPersonName = data["targetPersonName"] as? String
        self.metadata = data["metadata"] as? [String: String] ?? [:]
        self.karmaUsed = data["karmaUsed"] as? Int ?? 0
        self.isPremium = data["isPremium"] as? Bool ?? false
    }
    
    // MARK: - Sample Data for Preview
    static let sampleFortunes: [FortuneModel] = [
        FortuneModel(
            id: "1",
            data: [
                "userId": "user1",
                "type": "tarot",
                "status": "completed",
                "title": "Tarot Yorumu",
                "interpretation": "Kartlarınız yeni bir başlangıca işaret ediyor...",
                "createdAt": Timestamp(date: Date().addingTimeInterval(-3600)),
                "isFavorite": true,
                "rating": 5,
                "karmaUsed": 8
            ]
        ),
        FortuneModel(
            id: "2",
            data: [
                "userId": "user1",
                "type": "coffee",
                "status": "completed",
                "title": "Kahve Falı",
                "interpretation": "Fincanınızda güzel haberler görünüyor...",
                "createdAt": Timestamp(date: Date().addingTimeInterval(-86400)),
                "isFavorite": false,
                "rating": 4,
                "karmaUsed": 5
            ]
        ),
        FortuneModel(
            id: "3",
            data: [
                "userId": "user1",
                "type": "palm",
                "status": "completed",
                "title": "El Falı",
                "interpretation": "Yaşam çizginiz uzun ve sağlıklı...",
                "createdAt": Timestamp(date: Date().addingTimeInterval(-172800)),
                "isFavorite": false,
                "rating": 3,
                "karmaUsed": 10
            ]
        )
    ]
}
