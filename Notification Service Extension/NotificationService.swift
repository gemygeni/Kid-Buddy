//
//  NotificationService.swift
//  Notification Service Extension
//
//  Created by AHMED GAMAL  on 19/07/2022.
//

import UserNotifications

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        print("HAAAAAAAAA noty")
       self.contentHandler = contentHandler
       bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
       let userInfo: [AnyHashable : Any] = (bestAttemptContent?.userInfo)!
       if let apsInfo = userInfo["aps"] as? [AnyHashable: Any], let bestAttemptContent = bestAttemptContent, let critical =  userInfo["critical"] as? String, Int(critical)! == 1 {
           
           bestAttemptContent.title = "HAAAAAAAAA %@[Modified]"
            //critical alert try to change the sound if sound file is sent in notificaiton.
            if let sound = apsInfo["sound"] as? String {
                //sound file is present in notification. use it for critical alert..
                bestAttemptContent.sound =
                    UNNotificationSound.criticalSoundNamed(UNNotificationSoundName.init(sound),
                                                           withAudioVolume: 1.0)
            } else {
                //sound file not present in notifiation. use the default sound.
                bestAttemptContent.sound =
                                UNNotificationSound.defaultCriticalSound(withAudioVolume: 1.0)
            }
            contentHandler(bestAttemptContent)
        }
    }

    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }

}
