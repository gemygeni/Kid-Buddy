//
//  LocationHandler.swift
//  TracKids
//
//  Created by AHMED GAMAL  on 2/8/21.
//
import MapKit
import CoreLocation
import Firebase
import GeoFire

struct Location{
    let title : String
    let details : String
    let coordinates : CLLocationCoordinate2D
}


class LocationHandler : NSObject,CLLocationManagerDelegate{
    static let shared = LocationHandler()
    var locationManager : CLLocationManager?
    var location : CLLocation?
    var places = [Location]()
    var currentCoordinate: CLLocationCoordinate2D?
    override init() {
        super.init()
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.allowsBackgroundLocationUpdates = true
        locationManager?.startUpdatingLocation()
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        
        case .notDetermined:
            locationManager?.requestWhenInUseAuthorization()
            print("not determined")
            break
        case .restricted , .denied:
            print("restricted")
            break
        case .authorizedAlways:
            locationManager?.startUpdatingLocation()
            locationManager?.desiredAccuracy = kCLLocationAccuracyHundredMeters
            print("always auth")
            
        case .authorizedWhenInUse:
            locationManager?.startUpdatingLocation()
            locationManager?.requestAlwaysAuthorization()
        @unknown default:
            print("default")
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let geofire = GeoFire(firebaseRef: ChildLocationReference)
        guard let lastLocation = locations.last else {return}
        currentCoordinate = lastLocation.coordinate
        ChildLocationReference.observe(.value) { (snapshot) in
            guard   let UId =  Auth.auth().currentUser?.uid else {return}
            DataHandler.shared.fetchUserInfo() { (user) in
                let currentUser = user
                if currentUser.accountType == 1 {
                    geofire.setLocation(lastLocation, forKey: UId) { (error) in
                        print("new child created")
                        if error != nil {print(error!.localizedDescription )}
                    }
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        
        print(error.localizedDescription)
    }
    
//    func searchForLocationddd (with query : String , completion : @escaping(([Location]) -> Void)){
//        self.places = []
//    let geocoder = CLGeocoder()
//                geocoder.geocodeAddressString(query) { (placemarks, error) in
//                    guard let placemarks = placemarks , error == nil else {completion([])
//        
//
//                      return}
//
//                let places : [Location] = placemarks.compactMap ({ placeData  in
//                    var name = ""
//                    if let streetDetails = placeData.subThoroughfare{
//                        name += streetDetails
//                    }
//                    if let street = placeData.thoroughfare{
//                        name += " \(street)"
//                    }
//                    if let locality = placeData.locality{
//                        name += ", \(locality)"
//                    }
//
//                    if let adminRegion = placeData.administrativeArea {
//                        name += ", \(adminRegion)"
//                    }
//
//                    if let country = placeData.country{
//                        name += ", \(country)"
//                    }
//                    print("Debug : \n \(placeData) \n\n")
//
//                    let place = Location(title: name, coordinates: placeData.location?.coordinate ?? CLLocationCoordinate2D())
//                    return place
//                })
//                print("Debug : \n \(places) \n\n")
//                completion(places)
//        }
//    }
//
    func searchForLocation (with query : String , completion : @escaping(([Location]) -> Void)){
        self.places = []

        let request = MKLocalSearch.Request()
//        guard let regionLocation = currentCoordinate else{
//            print("Debug : NOOO LOcation")
//            return}
        //let region = MKCoordinateRegion(center: regionLocation, latitudinalMeters: 10000, longitudinalMeters: 10000)
        let region = MKCoordinateRegion(center: currentCoordinate ?? CLLocationCoordinate2D(), span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1))
        request.region = region
        request.naturalLanguageQuery = query
       
        let search = MKLocalSearch(request: request)
        search.start { [self] (response, error) in
            guard let response = response else { return }
            response.mapItems.forEach { (item) in

                let coordinates = item.placemark.location?.coordinate
                let name = item.placemark.name
                let details = item.placemark.title

                let place = Location(title: name ?? "", details: details ?? "", coordinates: coordinates ?? CLLocationCoordinate2D())

                self.places.append(place)
                completion(places)
          }
        }
    }
}
