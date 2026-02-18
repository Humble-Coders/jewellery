import Foundation
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import FirebaseMessaging

class FirebaseService {
    static let shared = FirebaseService()
    
    private init() {}
    
    var db: Firestore {
        Firestore.firestore()
    }
    
    var auth: Auth {
        Auth.auth()
    }
    
    var storage: Storage {
        Storage.storage()
    }
    
    var messaging: Messaging {
        Messaging.messaging()
    }
    
    func configure() {
        // Firebase is configured via GoogleService-Info.plist
        // This method can be used for any additional setup
        let settings = FirestoreSettings()
        settings.cacheSettings = PersistentCacheSettings()
        db.settings = settings
    }
}
