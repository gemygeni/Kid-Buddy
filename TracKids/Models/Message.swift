//
//  Message.swift
//  TracKids
//
//  Created by AHMED GAMAL  on 9/7/21.
//

import Foundation
struct Message {
    let sender : String?
    let body  : String?
    let recipient : String?
    let timestamp : NSNumber?
    init(_ MessageInfo : [String  : Any] ) {
        self.sender = MessageInfo["sender"] as? String
        self.body = MessageInfo["body"] as? String
        self.recipient = MessageInfo["recipient"] as? String
        self.timestamp = MessageInfo["timestamp"] as? NSNumber
    }
}
