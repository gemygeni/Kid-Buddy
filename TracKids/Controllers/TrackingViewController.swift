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
    
    protocol TrackingManagerDelegate{
        func didSelectedChild(trackedChildUId : String)
    }
    extension Notification.Name{
        static let TrackedChildDidChange = Notification.Name("TrackedChildDidChange")
    }


    class TrackingViewController: UIViewController  {
        var delegate : TrackingManagerDelegate?
        var accountType : AccountType!
        var childs = [Child?]()
        var childsID = [String]()
        var AuthHandler : AuthStateDidChangeListenerHandle?
        var annotationImage : UIImage?
        var trackedChild : Child?
        var IsLoggedIn : Bool = false
        
        
        
        static var trackedChildUId : String?{
                didSet{
                    
                    NotificationCenter.default.post(name: .TrackedChildDidChange, object: TrackingViewController.trackedChildUId)
                }
            }
        
        
        override var preferredStatusBarStyle: UIStatusBarStyle {
            return .lightContent
        }
      
        
        @IBOutlet weak var childsCollectionView: UICollectionView!
        
        @IBOutlet weak var mapView: MKMapView!
        let LocationManager = LocationHandler.shared.locationManager
        
        var user : User?{
            didSet{
                IsLoggedIn = true
                if let index = user?.accountType{
                    self.accountType = AccountType(rawValue: index )
                    print("Account type is: \(self.accountType!)")
                    }
                if accountType == .parent {
                    fetchChildLocation()
                    fetchChildsItems()
                    
                }
                else if accountType == .child {
                    handleLocationServices()
                }
            }
        }
        
        
        
//        override func viewDidLoad() {
//            super.viewDidLoad()
//            childsCollectionView.delegate = self
//            childsCollectionView.dataSource = self
//            fetchUserInfo()
//
//            if accountType == .parent {
//            fetchChildLocation()
//         }
//        }
//

        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(true)
            childsCollectionView.delegate = self
            childsCollectionView.dataSource = self
            fetchUserInfo()
            configureMapView()
            if accountType == .parent {
                print("hey iam parent and i willappear")
                //if IsLoggedIn{
                fetchChildLocation()
                   //  }
            }
       
            else if accountType == .child {
                print("hey iam child and i willappear")
                handleLocationServices()
               }
            AuthHandler =  Auth.auth().addStateDidChangeListener({ (_, user) in
                if user == nil {
                    
                    self.resetMap()
                    self.childsCollectionView.isHidden = true
                    self.addChildButton.isHidden = true
                }
                else{
                    self.childsCollectionView.isHidden = false
                    self.addChildButton.isHidden = false
                }
            })
        }
         
        
        func resetMap(){
            self.mapView.removeAnnotations( self.mapView.annotations)
            let Location = self.LocationManager?.location?.coordinate
            let region = MKCoordinateRegion(center: Location ?? CLLocationCoordinate2D() , span: MKCoordinateSpan(latitudeDelta: 20, longitudeDelta: 20))
            self.mapView.setRegion(region, animated: true)
self.mapView.setVisibleMapRect(self.mapView.visibleMapRect, edgePadding: UIEdgeInsets(top: 100.0, left:100.0, bottom: 100.0, right: 100.0), animated: true)
            print("mappppp resettttttt")
        }
        
        
        
        func fetchChildLocation()  {
           if IsLoggedIn{
            if accountType == .parent {
                guard let  childID = TrackingViewController.trackedChildUId else {return}
               print("in fetchChildLocation childID is \(childID)")
                DataHandler.shared.fetchChildLocation(for: childID) { (location) in
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
            else{
                resetMap()
            }
            
        }
        
        
        func fetchUserInfo(){
            DataHandler.shared.fetchUserInfo() { (user) in
                self.user = user
            }
        }
        
        
        @IBOutlet weak var addChildButton: UIButton!
        
        @IBAction func AddChildPressed(_ sender: UIButton) {
            if !IsLoggedIn{
                performSegue(withIdentifier: "showSignIn", sender: sender)
                print("please log in")
            }
            else {
                
                if accountType == .parent{
                    performSegue(withIdentifier: "AddChildSegue", sender: sender)
                    print("you are logged in")
                } else if accountType == .child{
                    // performSegue(withIdentifier: "showAddParentSegue", sender: sender)
                }
            }
        }
        
         func CheckLogIn() -> Bool {
            if user?.uid == nil {
                print("not logged in")
                IsLoggedIn = false
                return false
            }
            else {
                IsLoggedIn = true
                return true
            }
        }
        
        func configureMapView(){
            mapView.delegate = self
            if accountType == .child {
                self.mapView.showsUserLocation = true
            }
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
                view.image =   annotationImage ?? #imageLiteral(resourceName: "person").resize(70 , 70)
                view.layer.cornerRadius = 25
                view.clipsToBounds = true
                return view
            }
            return nil
        }
    }
    
    extension TrackingViewController : UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
        
            func fetchChildsItems(){
            childs = []
            childsID = []
            DataHandler.shared.fetchChildInfo() { (child,childID) in
                self.childs.append(child)
                self.childsID.append(childID)
                DispatchQueue.main.async {
                    self.childsCollectionView.reloadData()
                }
            }
        }
        
        
        func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            return  childs.count
        }
        
        func numberOfSections(in collectionView: UICollectionView) -> Int {
            return 1
        }
        
        func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ChildProfileCell", for: indexPath)
            if let childCell = cell as? ChildsCollectionViewCell{
                childCell.profileImageView.image = nil
                if  let child = childs[indexPath.item]{
                if let childImageURl = child.ImageURL {
                    childCell.profileImageView.loadImageUsingCacheWithUrlString(childImageURl)
                    annotationImage = childCell.profileImageView.image?.resize(70 , 70)
                    }
                 }
                return childCell
               }
            return cell
        }
        
        func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
            self.mapView.removeAnnotations(mapView.annotations)
            trackedChild = childs[indexPath.item]
            print("tracked child now is \(String(describing: trackedChild?.ChildName)) ")
            TrackingViewController.trackedChildUId = childsID[indexPath.item]
            print("tracked child now is \(String(describing: TrackingViewController.trackedChildUId)) ")
            if let cell = childsCollectionView.cellForItem(at: indexPath) as? ChildsCollectionViewCell {
                self.annotationImage = nil
                DispatchQueue.main.async {
                    self.annotationImage = cell.profileImageView.image?.resize(70 , 70)
                }
            }
            fetchChildLocation()
        }
    }
