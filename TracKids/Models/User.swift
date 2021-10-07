//
//  User.swift
//  TracKids
//
//  Created by AHMED GAMAL  on 2/4/21.
//
import UIKit
import CoreLocation
struct User {
    var email : String
    var phoneNumber : String
    var password : String
    var accountType : Int
    var parentID : String
    var uid : String
    init(uid : String , dictionary : [String : Any] ) {
        self.uid = uid
        self.email = dictionary["email"] as? String ?? ""
        self.phoneNumber = dictionary["phoneNumber"] as? String ?? ""
        self.password = dictionary["password"] as? String ?? ""
        self.accountType = dictionary["userType"] as! Int
        self.parentID = dictionary["ParentID"] as? String ?? ""
    }
}

