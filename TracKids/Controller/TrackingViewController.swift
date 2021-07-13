//
//  HomeViewController.swift
//  TracKids
//
//  Created by AHMED GAMAL  on 1/30/21.
//

import UIKit
import MapKit
import Firebase



enum AccountType : Int  {
    case parent
    case child
}


class TrackingViewController: UIViewController  {
    var accountType : AccountType!
    
   // let kSecRandomDefault = SecRandomRef(bitPattern: 10)
    @IBOutlet weak var mapView: MKMapView!
    let LocationManager = LocationHandler.shared.locationManager
    
    var user : User?{
        didSet{
            if let index = user?.accountType{
                self.accountType = AccountType(rawValue: index )
                print("Account type is: \(self.accountType!)")
            }
            
            if accountType == .parent {
                fetchChildLocation()
            }
            else if accountType == .child {
                handleLocationServices()
            }
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fetchUserInfo()
        configureMapView()
    }
    
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        fetchUserInfo()
        configureMapView()
        
        if accountType == .parent {
            print("hey iam parent and i willappear")
            fetchChildLocation()
        }
        else if accountType == .child {
            print("hey iam child and i willappear")
            handleLocationServices()
        }
    }
    
    
    func fetchChildLocation()  {
        if accountType == .parent {
            let childID = "6zex1vff9uhsQZ76MhyOoLT8bOM2"
            DataHandler.shared.fetchChildLocation(uid: childID) { (location) in
                guard let fetchedLocation = location else {return}
                let region = MKCoordinateRegion(center: fetchedLocation.coordinate , span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
                DispatchQueue.main.async {
                    self.mapView.setRegion(region, animated: true)
                    let annotation = ChildAnnotation(uid: childID, coordinate: fetchedLocation.coordinate)
                    if self.mapView.annotations.contains(where: { (annotation) -> Bool in
                        guard let childAnnnotation = annotation as? ChildAnnotation else{return false}
                        childAnnnotation.updateMapView(with: fetchedLocation.coordinate)
                        return true
                    })
                     {
                    }
                    else{
                        self.mapView.addAnnotation(annotation)
                    }
                }
            }
        }
    }
    
    
    //
    func fetchUserInfo(){
        guard let UId = Auth.auth().currentUser?.uid else {return}
        DataHandler.shared.fetchUserInfo(UId: UId) { (user) in
            self.user = user
        }
    }
    
    
    @IBOutlet weak var addChild: UIButton!
    
    @IBAction func AddChildPressed(_ sender: UIButton) {
        if !IsLoggedIn(){
            performSegue(withIdentifier: "showSignIn", sender: sender)
            print("please log in")
        }
        else {
            performSegue(withIdentifier: "AddChild", sender: sender)
            print("you are logged in")
        }
    }
    
    
    private func IsLoggedIn() -> Bool {
        if user?.uid == nil {
            print("not logged in")
            return false
        }
        else {
            return true
        }
    }
    
    func configureMapView(){
        mapView.delegate = self
        mapView.addSubview(addChild)
        //mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        mapView.isZoomEnabled = true
    }
}












extension TrackingViewController : CLLocationManagerDelegate {
    func handleLocationServices(){
        guard CLLocationManager.locationServicesEnabled() else {
            print("location services disabled")
            return
        }
        LocationManager?.delegate = self
        LocationManager?.requestWhenInUseAuthorization()
        LocationManager?.requestAlwaysAuthorization()
        if LocationManager?.authorizationStatus == .authorizedAlways{
            LocationManager?.startUpdatingLocation()
            LocationManager?.desiredAccuracy = kCLLocationAccuracyHundredMeters
            print("always authorized already")
        }
        else{
            print("authorize requested")
        }
    }
}

extension TrackingViewController : MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? ChildAnnotation {
            let view = MKAnnotationView(annotation: annotation, reuseIdentifier: "childAnnotation")
            view.image = #imageLiteral(resourceName: "mazengar")
            return view
        }
        return nil
    }
}
