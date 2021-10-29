//
//  ObservedPlacesViewController.swift
//  TracKids
//
//  Created by AHMED GAMAL  on 10/23/21.
//

import UIKit
import MapKit
import Firebase
class ObservedPlacesViewController: UIViewController, MKMapViewDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        configureMapView()
        
    }
    
    @IBOutlet weak var mapView: MKMapView!
let LocationManager = LocationHandler.shared.locationManager

    
    func configureMapView(){
        mapView.delegate = self
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        mapView.isZoomEnabled = true
      }
    
    
}
   
 
