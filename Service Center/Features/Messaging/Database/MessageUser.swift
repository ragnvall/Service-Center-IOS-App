import Firebase
import FirebaseFirestore

public struct MessageUser: Identifiable, Codable, Equatable, Hashable{
    public var id: String // Firebase document ID
    public let senderId: String
    public let receiverId: String
    public let username: String
    public let lastMessage: String
    public let timestamp: Date
    public var hasUnreadMessage: Bool
    public var profileImageUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case senderId
        case receiverId
        case username
        case lastMessage
        case timestamp
        case hasUnreadMessage
        case profileImageUrl
    }
    
    public init(id: String,
                senderId: String,
                receiverId: String,
                username: String,
                lastMessage: String,
                timestamp: Date,
                hasUnreadMessage: Bool,
                profileImageUrl: String? = nil) {
        self.id = id
        self.senderId = senderId
        self.receiverId = receiverId
        self.username = username
        self.lastMessage = lastMessage
        self.timestamp = timestamp
        self.hasUnreadMessage = hasUnreadMessage
        self.profileImageUrl = profileImageUrl
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        senderId = try container.decode(String.self, forKey: .senderId)
        receiverId = try container.decode(String.self, forKey: .receiverId)
        username = try container.decode(String.self, forKey: .username)
        lastMessage = try container.decode(String.self, forKey: .lastMessage)
        hasUnreadMessage = try container.decode(Bool.self, forKey: .hasUnreadMessage)
        profileImageUrl = try container.decodeIfPresent(String.self, forKey: .profileImageUrl)
        
        if let timestamp = try? container.decode(Timestamp.self, forKey: .timestamp) {
            self.timestamp = timestamp.dateValue()
        } else {
            self.timestamp = Date()
        }
    }
    
    public var formattedTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}

public struct ChatMessage: Identifiable, Codable, Equatable {
    public let id: String
    public let senderId: String
    public let receiverId: String
    public let messageText: String
    public let timestamp: Date
    public let imageUrl: String?  // Marked as public

    enum CodingKeys: String, CodingKey {
        case id
        case senderId
        case receiverId
        case messageText
        case timestamp
        case imageUrl  // Include this if you expect to decode it
    }

    public init(id: String,
                senderId: String,
                receiverId: String,
                messageText: String,
                timestamp: Date,
                imageUrl: String? = nil) {
        self.id = id
        self.senderId = senderId
        self.receiverId = receiverId
        self.messageText = messageText
        self.timestamp = timestamp
        self.imageUrl = imageUrl
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        senderId = try container.decode(String.self, forKey: .senderId)
        receiverId = try container.decode(String.self, forKey: .receiverId)
        messageText = try container.decode(String.self, forKey: .messageText)
        if let timestamp = try? container.decode(Timestamp.self, forKey: .timestamp) {
            self.timestamp = timestamp.dateValue()
        } else {
            self.timestamp = Date()
        }
        imageUrl = try? container.decode(String.self, forKey: .imageUrl)
    }
    
    public var formattedTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}
