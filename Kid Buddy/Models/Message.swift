//
//  Message.swift
//  Kid Buddy
//
//  Created by AHMED GAMAL  on 9/7/21.
//

import Foundation
struct Message {
    let sender: String?
    let body: String?
    let recipient: String?
    let timestamp: NSNumber?
    let fromDevice: String?
    let imageURL: String?
    init(_ messageInfo: [String: Any] ) {
        self.sender = messageInfo["sender"] as? String
        self.body = messageInfo["body"] as? String
        self.recipient = messageInfo["recipient"] as? String
        self.timestamp = messageInfo["timestamp"] as? NSNumber
        self.fromDevice = messageInfo["fromDevice"] as? String
        self.imageURL = messageInfo["imageURL"] as? String
    }
}
