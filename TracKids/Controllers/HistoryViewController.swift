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
    var locationHistory = [CLLocation]()
    var annotations = [ChildAnnotation]()

    override func viewDidLoad() {
        super.viewDidLoad()
        fetchLocationHistory()
    }
    
    func fetchLocationHistory(){
        locationHistory = []
        guard let childId = TrackingViewController.trackedChildUId else {
            return
        }
        //let ali = "xbfS3m7GbgPXn45fCwp8YfGw42M2"
        LocationHandler.shared.fetchLocationHistory(for: childId) {[weak self] (locationHistory) in
            print("xxx \(locationHistory.count)")
            self?.locationHistory = locationHistory
            for location in locationHistory {
        let annotation = ChildAnnotation(uid: childId, coordinate: location.coordinate)
                self?.mapView.addAnnotation(annotation)
                print("xxx \(String(describing: self?.annotations))")
        }
     }
  }
}



//            let annotations : [MKAnnotation]  = (self?.locationHistory.compactMap({ (location) -> MKAnnotation? in
//                let annotation = ChildAnnotation(uid: childId, coordinate: location.coordinate)
//                return annotation
//
//            }))!


//
//func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
//    let renderer = MKPolylineRenderer(overlay: overlay)
//    renderer.strokeColor = UIColor(red: 17.0/255.0, green: 147.0/255.0, blue: 255.0/255.0, alpha: 1)
//    renderer.lineWidth = 5.0
//    return renderer
//
//  //  or
////    renderer.strokeColor = UIColor(red:0.07, green:0.73, blue:0.86, alpha:1.0)
////    renderer.lineWidth = 4.0
//
//}
//
//
//
//
//func addAnnotationFromHistory(_ annotation: MKAnnotation) {
//
//    let span = MKCoordinateSpan.init(latitudeDelta: 0.015, longitudeDelta: 0.015)
//    let region = MKCoordinateRegion(center: annotation.coordinate, span: span)
//    self.mapView.addAnnotation(annotation)
//    self.mapView.selectAnnotation(annotation, animated: true)
//    self.mapView.setRegion(region, animated: true)
//}
//
//func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
//    if !(annotation is MKUserLocation) {
//        let pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: String(annotation.hash))
//
//        rightButton.setImage(UIImage(named: "Next"), for: UIControl.State.normal)
//        rightButton.tag = annotation.hash
//
//        pinView.animatesDrop = true
//        pinView.canShowCallout = true
//        pinView.rightCalloutAccessoryView = rightButton
//
//        return pinView
//    } else {
//        return nil
//    }
//}
//
//
//
//
//
//func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
//}
//
//func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
//    view.removeFromSuperview()
//    self.mapView.removeAnnotation(view.annotation!)
//    self.mapView.removeOverlays(self.mapView!.overlays)
//    self.flagDir = false
//}
//
//
//
//
//@objc func rightButtonClicked(_ sender: UIButton) {
//    if MapData.setRoute {
//        twoPointsRoute()
//        MapData.departurePlacemark = nil
//        MapData.destinationPlacemark = nil
//        MapData.setRoute = false
//        return
//    }
//    guard let currentPlacemark = currentPlacemark else { return }
//    let directionRequest = MKDirections.Request()
//    let destinationPlacemark = MKPlacemark(placemark: currentPlacemark)
//
//    directionRequest.source = MKMapItem.forCurrentLocation()
//    directionRequest.destination = MKMapItem(placemark: destinationPlacemark)
//    directionRequest.transportType = .automobile
//
//    // calculate the directions / route
//    let directions = MKDirections(request: directionRequest)
//    directions.calculate { (directionsResponse, error) in
//        guard let directionsResponse = directionsResponse else {
//            if let error = error {
//                print("error:", error)
//                let alert = UIAlertController(title: "Error", message: "Can't find way to this location", preferredStyle: .alert)
//                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
//                self.present(alert, animated: true, completion: nil)
//            }
//            return
//        }
//        let route = directionsResponse.routes[0]
//        self.mapView.removeOverlays(self.mapView!.overlays)
//        self.mapView.addOverlay(route.polyline, level: .aboveRoads)
//
//        var routeRect = route.polyline.boundingMapRect
//        routeRect.size.width *= 1.1
//        routeRect.size.height *= 1.1
//        self.mapView.setRegion(MKCoordinateRegion(routeRect), animated: true)
//        self.flagDir = true
//    }
//}
//
//
//
