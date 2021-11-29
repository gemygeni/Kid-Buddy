//
//  ChildAnnotation.swift
//  TracKids
//
//  Created by AHMED GAMAL  on 2/16/21.
//


import MapKit
class ChildAnnotation: NSObject, MKAnnotation {
   dynamic var coordinate: CLLocationCoordinate2D
    var uid : String
    var title: String?
    var subtitle: String?
    init(uid : String ,coordinate : CLLocationCoordinate2D) {
        self.coordinate = coordinate
        self.uid = uid
    }
    
    func updateMapView(with coordinate : CLLocationCoordinate2D)  {
        UIView.animate(withDuration: 0.3) {
            self.coordinate = coordinate
        }
    }
}
