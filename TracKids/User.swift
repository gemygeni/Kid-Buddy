//
//  User.swift
//  TracKids
//
//  Created by AHMED GAMAL  on 2/4/21.
//

import Foundation
import CoreLocation
struct User {
    var email : String
    var fullName : String
    var passWord : String
    var accountType : Int
    var uid : String
    var location : CLLocation?
    
    init(uid : String , dictionary : [String : Any] ) {
        self.uid = uid
        self.email = dictionary["email"] as? String ?? ""
        self.fullName = dictionary["fullName"] as? String ?? ""
        self.passWord = dictionary["passWord"] as? String ?? ""
        self.accountType = dictionary["userType"] as! Int
    }
}

