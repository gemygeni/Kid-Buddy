//
//  Child.swift
//  TracKids
//
//  Created by AHMED GAMAL  on 3/4/21.
//


import UIKit

import CoreLocation
struct Child {
    var name : String
    var phoneNumber : String
    var image : UIImage?
    var location : CLLocation?
    var locationHistory : [CLLocation]?
    init(name : String, phoneNumber : String ) {
        self.name = name
        self.phoneNumber = phoneNumber
    }
    
}
