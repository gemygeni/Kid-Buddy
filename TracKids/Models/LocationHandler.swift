//
//  LocationHandler.swift
//  TracKids
//
//  Created by AHMED GAMAL  on 2/8/21.
//

import CoreLocation
import Firebase
import GeoFire
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
            print("nnnnnnnnnnnnnnnnnot determined")
            break
        case .restricted , .denied:
            print("rrrrrrrrrrrrrestricted")
            break
        case .authorizedAlways:
            locationManager.startUpdatingLocation()
            locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
            print("alwaaaaaaays auth")
            
        case .authorizedWhenInUse:
            locationManager.requestAlwaysAuthorization()
        @unknown default:
            print("defaulllllllllllllllllt")
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let geofire = GeoFire(firebaseRef: childLocationReference)
        childLocationReference.observe(.value) { (snapshot) in
            guard let lastLocation = locations.last else {return}
            guard   let UId =  Auth.auth().currentUser?.uid else {return}
            DataHandler.shared.fetchUserInfo(UId: UId) { (user) in
                let currentUser = user
                if currentUser.accountType == 1 {
                    geofire.setLocation(lastLocation, forKey: UId) { (error) in
                        print("nnewwwwwwwwwwwwwwww child created")
                        
                        if error != nil {print(error!.localizedDescription )}
                    }
                }
            }
        }
    }
}
