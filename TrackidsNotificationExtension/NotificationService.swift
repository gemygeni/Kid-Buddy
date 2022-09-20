//
//  NotificationService.swift
//  TrackidsNotificationExtension
//
//  Created by AHMED GAMAL  on 18/09/2022.
//

import UserNotifications

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
          self.contentHandler = contentHandler
          bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        guard let bestAttemptContent = self.bestAttemptContent else { return }
        let userInfo: [AnyHashable : Any] = (bestAttemptContent.userInfo)
        
        if let aps = userInfo["aps"] as? [AnyHashable: Any], let sound = aps["sound"] as? String, sound.contains("critical"){
            bestAttemptContent.sound =  UNNotificationSound.criticalSoundNamed(UNNotificationSoundName.init("criticalAlert.m4a"),
                                                                  withAudioVolume: 1.0)
            }
                contentHandler(bestAttemptContent)
       }
    override func serviceExtensionTimeWillExpire() {
        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }
}
