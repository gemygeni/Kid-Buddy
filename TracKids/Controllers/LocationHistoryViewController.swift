//
//  LocationHistoryViewController.swift
//  TracKids
//
//  Created by AHMED GAMAL  on 12/1/21.
//

import UIKit
import MapKit
class LocationHistoryViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    //var locationHistory = [CLLocation]()
    var annotations = [ChildAnnotation]()
    var historyPoints = [CLLocationCoordinate2D]()
    override func viewDidLoad() {
        super.viewDidLoad()
        configureMapView()
        fetchLocationHistory()
    }
    func configureMapView(){
        mapView.delegate = self
        self.mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        mapView.isZoomEnabled = true
    }
   var count11 = 0
    var count22 = 0
    
    
    func fetchLocationHistory(){
        
        count11 += 1
        print("nnn111 \(String(describing: count11))")

        self.mapView.removeAnnotations(self.mapView.annotations)
        self.mapView.removeOverlays(self.mapView.overlays)
        guard let childId = TrackingViewController.trackedChildUId else {
            return
        }
        LocationHandler.shared.fetchLocationHistory(for: childId) {[weak self] (fetchedLocations) in
            self?.historyPoints = []
           
            for location in fetchedLocations {
               
                self?.count22 += 1
                print("nnn222 \(String(describing: self?.count22))")
        let annotation = ChildAnnotation(uid: childId, coordinate: location.coordinate)
                self?.mapView.addAnnotation(annotation)
                let timestamp = location.timestamp
                
                annotation.title = timestamp.convertDateFormatter()
                DataHandler.shared.convertLocationToAdress(for: location) { (place) in
                    annotation.subtitle = place?.title
                }
                let point = location.coordinate
                self?.historyPoints.append(point)
         }
            print("jjj \(self!.historyPoints.count)")
            self?.drawOverlay(with: self!.historyPoints)
     }
  }
    
    
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



extension LocationHistoryViewController : MKMapViewDelegate{
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

    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
    }
    
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        
        
    }
    


    
}
