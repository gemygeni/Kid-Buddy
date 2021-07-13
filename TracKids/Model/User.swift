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
    var passWord : String
    var accountType : Int
    var uid : String
    var location : CLLocation?
    var image : UIImage?
    
    init(uid : String , dictionary : [String : Any] ) {
        self.uid = uid
        self.email = dictionary["email"] as? String ?? ""
        self.phoneNumber = dictionary["phoneNumber"] as? String ?? ""
        self.passWord = dictionary["passWord"] as? String ?? ""
        self.accountType = dictionary["userType"] as! Int
    }
}

