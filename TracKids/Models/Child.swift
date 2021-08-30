//
//  Child.swift
//  TracKids
//
//  Created by AHMED GAMAL  on 8/27/21.
//

import Foundation
import CoreLocation
struct Child {
    var ParentID : String
    
    var ChildName : String
    var ImageURL : String
    var ChildPhoneNumber : String
    var CurrentLocation : CLLocation?
    var History : [CLLocation]?
    
    init(ParentID : String ,ChildInfo : [String  : Any] ) {
        self.ParentID = ParentID
        self.ChildName = ChildInfo["ChildName"] as? String ?? ""
        self.ChildPhoneNumber = ChildInfo["ChildPhoneNumber"] as? String ?? ""

        self.ImageURL = ChildInfo["ImageURL"] as? String ?? ""
        self.CurrentLocation = ChildInfo["CurrentLocation"] as? CLLocation ?? nil
        self.History = ChildInfo["History"] as? [CLLocation] ?? nil
    }
}
