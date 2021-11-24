//
//  HistoryViewController.swift
//  TracKids
//
//  Created by AHMED GAMAL  on 11/22/21.
//

import UIKit
import MapKit
class HistoryViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
}

//var distanceFilter: CLLocationDistance { get set }

//check if this location is the same as the last one we logged
//(iOS will sometimes call this function twice in quick succession, so we filter out duplicates)


//if (locValue.latitude == lastLocation.latitude && locValue.longitude == lastLocation.latitude){
//    return
//}
//

//func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
//    let renderer = MKPolylineRenderer(overlay: overlay)
//    renderer.strokeColor = UIColor(red: 17.0/255.0, green: 147.0/255.0, blue: 255.0/255.0, alpha: 1)
//    renderer.lineWidth = 5.0
//    return renderer
//}

