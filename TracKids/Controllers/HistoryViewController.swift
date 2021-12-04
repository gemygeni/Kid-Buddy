//
//  HistoryViewController.swift
//  TracKids
//
//  Created by AHMED GAMAL  on 11/22/21.
//

import UIKit
import MapKit
import GeoFire
class HistoryViewController: UIViewController {

    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var mapView: MKMapView!
    var annotations = [ChildAnnotation]()
    var historyPoints = [CLLocationCoordinate2D]()
    override func viewDidLoad() {
        super.viewDidLoad()
        configureMapView()
        spinner.startAnimating()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        fetchLocationHistory()
    }
    
    
    func configureMapView(){
        mapView.delegate = self
        self.mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        mapView.isZoomEnabled = true
    }
    var count = 0
    func fetchLocationHistory(){
        self.historyPoints = []
        self.mapView.removeAnnotations(self.mapView.annotations)
        self.mapView.removeOverlays(self.mapView.overlays)
        guard let childId = TrackingViewController.trackedChildUId else {return}
        let geofire = GeoFire(firebaseRef: HistoryReference.child(childId))
        HistoryReference.child(childId).observe(.childAdded) {[weak self] (snapshot) in
            let key = snapshot.key
            geofire.getLocationForKey(key) { (location, error) in
                guard let fetchedLocation = location else {return}
                let annotation = ChildAnnotation(uid: childId, coordinate: fetchedLocation.coordinate)
                self?.mapView.addAnnotation(annotation)
                let timeBySeconds = Double(key)
                let date = Date(timeIntervalSince1970: timeBySeconds ?? 0.00)
                let formatter = DateFormatter()
                formatter.timeZone = TimeZone.current
                formatter.dateFormat = "E HH:mm a"
                let timestamp = formatter.string(from: date)
                annotation.title = timestamp
                DataHandler.shared.convertLocationToAdress(for: location) { (place) in
                    annotation.subtitle = place?.title
                  }
                let point = fetchedLocation.coordinate
                self?.historyPoints.append(point)
                self?.drawOverlay(with: self!.historyPoints)
            }
        }
        self.spinner.stopAnimating()
    }

    
 //old version
//    func fetchLocationHistory(){
//        self.mapView.removeAnnotations(self.mapView.annotations)
//        self.mapView.removeOverlays(self.mapView.overlays)
//        guard let childId = TrackingViewController.trackedChildUId else {
//            return
//           }
//        LocationHandler.shared.fetchLocationHistory(for: childId) {[weak self] (fetchedLocations) in
//            self?.historyPoints = []
//            self?.locationHistory = fetchedLocations
//            for location in self!.locationHistory {
//                print("memo \(self!.locationHistory.count)")
//        let annotation = ChildAnnotation(uid: childId, coordinate: location.coordinate)
//                self?.mapView.addAnnotation(annotation)
//                let timestamp = location.timestamp
//
//                annotation.title = timestamp.convertDateFormatter()
//                DataHandler.shared.convertLocationToAdress(for: location) { (place) in
//                    annotation.subtitle = place?.title
//                  }
//                let point = location.coordinate
//                self?.historyPoints.append(point)
//          }
//            self?.drawOverlay(with: self!.historyPoints)
//     }
//  }
//
    
    func drawOverlay(with points : [CLLocationCoordinate2D] ){
         let historyPoints = self.historyPoints
        let polyline = MKPolyline(coordinates: historyPoints, count: historyPoints.count)
        mapView.addOverlay(polyline)
       var polylineRect = polyline.boundingMapRect
        polylineRect.size.width *= 1.1
        polylineRect.size.height *= 1.1
        self.mapView.setRegion(MKCoordinateRegion(polylineRect), animated: true)
     }
}

extension HistoryViewController : MKMapViewDelegate{
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if (annotation is MKUserLocation) {
            return nil
        }
        
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "historyAnnotation") as? MKMarkerAnnotationView
        if annotationView == nil{
            annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "historyAnnotation")
            annotationView?.canShowCallout = true
            annotationView?.calloutOffset = CGPoint(x: -5, y: 5)
            annotationView?.rightCalloutAccessoryView = UIButton(type: .system)
          }
        else{
            annotationView?.annotation = annotation
        }
        annotationView?.glyphText = "⏰"
        annotationView?.markerTintColor = .orange
         //   UIColor(displayP3Red: 0.518, green:0.263 , blue:  0.082, alpha: 1.0)
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = UIColor(red:0.07, green:0.73, blue:0.86, alpha:1.0)
           renderer.lineWidth = 4.0
//        renderer.strokeColor = UIColor(red: 17.0/255.0, green: 147.0/255.0, blue: 255.0/255.0, alpha: 1)
        renderer.lineWidth = 5.0
        return renderer
    }
}
