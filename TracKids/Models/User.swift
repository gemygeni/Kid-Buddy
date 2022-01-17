//
//  User.swift
//  TracKids
//
//  Created by AHMED GAMAL  on 2/4/21.
//
import UIKit
import CoreLocation
struct User {
    var name : String
    var uid : String
    var email : String
    var phoneNumber : String
    var password : String
    var accountType : Int
    var parentID : String?
    var imageURL : String?
    var deviceID : String?
    
    init(uid : String , dictionary : [String : Any] ) {
        self.uid = uid
        self.name = dictionary["name"] as? String ?? ""
        self.email = dictionary["email"] as? String ?? ""
        self.phoneNumber = dictionary["phoneNumber"] as? String ?? ""
        self.password = dictionary["password"] as? String ?? ""
        self.accountType = dictionary["userType"] as? Int ?? 0
        self.parentID = dictionary["parentID"] as? String ?? ""
        self.imageURL = dictionary["imageURL"] as? String ?? ""
        self.deviceID = dictionary["deviceID"] as? String ?? ""
    }
}

