//
//  LocationHandler.swift
//  TracKids
//
//  Created by AHMED GAMAL  on 2/8/21.
//

import Foundation
import CoreLocation

class LocationHandler : NSObject,CLLocationManagerDelegate{
    static let shared = LocationHandler()
    var locationManager: CLLocationManager!
    var location : CLLocation?
    
    override init() {
        super.init()
        locationManager = CLLocationManager()
        locationManager.delegate = self
        
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        
        case .notDetermined:
            
            break
        case .restricted , .denied:
            break
        case .authorizedAlways:
            locationManager.startUpdatingLocation()
            locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
            print("always authhhhhhhhhhh")
            
        case .authorizedWhenInUse:
            locationManager.requestAlwaysAuthorization()
        @unknown default:
            break
        }
    }
    
    
    
}
