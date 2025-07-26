import UserNotifications

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        if let bestAttemptContent = bestAttemptContent {
            // Görüntü URL'sini al
            var imageUrlString: String?
            
            // Önce data payload'dan dene
            if let dataImageUrl = bestAttemptContent.userInfo["imageUrl"] as? String,
               !dataImageUrl.isEmpty {
                imageUrlString = dataImageUrl
            }
            // Sonra custom payload'dan dene
            else if let attachmentUrl = bestAttemptContent.userInfo["attachmentUrl"] as? String,
                     !attachmentUrl.isEmpty {
                imageUrlString = attachmentUrl
            }
            
            // Eğer görüntü URL'si varsa indir ve ekle
            if let urlString = imageUrlString,
               let url = URL(string: urlString) {
                
                print("NotificationService: Downloading image from: \(urlString)")
                
                downloadImage(from: url) { [weak self] attachment in
                    if let attachment = attachment {
                        bestAttemptContent.attachments = [attachment]
                        print("NotificationService: Image attachment added successfully")
                    } else {
                        print("NotificationService: Failed to create image attachment")
                    }
                    
                    contentHandler(bestAttemptContent)
                }
            } else {
                print("NotificationService: No valid image URL found")
                contentHandler(bestAttemptContent)
            }
        }
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Extension süresi dolmak üzere, mevcut içeriği gönder
        if let contentHandler = contentHandler, let bestAttemptContent = bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }
    
    private func downloadImage(from url: URL, completion: @escaping (UNNotificationAttachment?) -> Void) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                print("NotificationService: Image download failed: \(error?.localizedDescription ?? "Unknown error")")
                completion(nil)
                return
            }
            
            // Geçici dosya oluştur
            let tempDirectory = NSTemporaryDirectory()
            let fileName = url.lastPathComponent.isEmpty ? "image.jpg" : url.lastPathComponent
            let tempFileURL = URL(fileURLWithPath: tempDirectory).appendingPathComponent(fileName)
            
            do {
                try data.write(to: tempFileURL)
                let attachment = try UNNotificationAttachment(identifier: "image", url: tempFileURL, options: nil)
                completion(attachment)
            } catch {
                print("NotificationService: Failed to create attachment: \(error)")
                completion(nil)
            }
        }.resume()
    }
}
