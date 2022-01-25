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
        var childs = [User?]()
        var childsID = [String]()
        var AuthHandler : AuthStateDidChangeListenerHandle?
        var annotationImage : UIImage?
        var fetchedImageView :  UIImageView?
        var trackedChild : User?{
            didSet{
                self.annotationImage = nil
                DispatchQueue.main.async { [self] in
                    if  let childImageURl = self.trackedChild?.imageURL {
                        self.fetchedImageView?.loadImageUsingCacheWithUrlString(childImageURl)
                        self.annotationImage = self.fetchedImageView?.image
                        self.fetchChildLocation()
                    }
                }
            }
        }
        var IsLoggedIn : Bool = false
        
        static var trackedChildUId : String?{
            didSet{
                
                NotificationCenter.default.post(name: .TrackedChildDidChange, object: TrackingViewController.trackedChildUId)
            }
        }
        
        @IBOutlet weak var childsCollectionView: UICollectionView!
        
        @IBOutlet weak var mapView: MKMapView!
        let locationManager = LocationHandler.shared.locationManager
        
        @IBAction func changeMapTypeButtonPressed(_ sender: Any) {
            if mapView.mapType == .standard{
                mapView.mapType = .hybrid
            }
            else if mapView.mapType == .hybrid {
                mapView.mapType = .standard
            }
        }
        
        var user : User?{
            didSet{
                IsLoggedIn = true
                if let index = user?.accountType{
                    self.accountType = AccountType(rawValue: index )
                    print("Debug: Account type is: \(self.accountType!)")
                }
                if self.accountType == .parent {
                    fetchChildLocation()
                    fetchChildsItems()
                }
//                else if TrackingViewController.accountType == .child {
//                    print("xxx in user init")
//                    handleLocationServices()
//                }
            }
        }
        
        override func viewDidLoad() {
            super.viewDidLoad()
            childsCollectionView.delegate = self
            childsCollectionView.dataSource = self
            configureMapView()
            centerMapOnUserLocation()
            LocationHandler.shared.StartObservingPlaces()
            var dict = [String: Any]()
            dict.updateValue(0, forKey: "badgeCount")
            UserDefaults.standard.register(defaults: dict)

        }
        
        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(true)
            childsCollectionView.delegate = self
            childsCollectionView.dataSource = self
            fetchUserInfo()
            configureMapView()
            if self.accountType == .parent {
                print("hey iam parent and i willappear")
                fetchChildLocation()
            }
            
//            else if TrackingViewController.accountType == .child {
//                print("hey iam child and i willappear")
//                handleLocationServices()
//            }
            AuthHandler =  Auth.auth().addStateDidChangeListener({ [weak self] (_, user) in
                if user == nil {
                    self?.centerMapOnUserLocation()
                    self?.childsCollectionView.isHidden = true
                    self?.addChildButton.isHidden = true
                    // self.childsCollectionView.removeFromSuperview()
                    // self.addChildButton.removeFromSuperview()
                }
                else{
                    self?.childsCollectionView.isHidden = false
                    self?.addChildButton.isHidden = false
                }
            })
        }
        
            
        func centerMapOnUserLocation() {
            guard let coordinate = self.locationManager?.location?.coordinate else { return }
            let region = MKCoordinateRegion(center: coordinate,
                                            latitudinalMeters: 2000,
                                            longitudinalMeters: 2000)
            mapView.setRegion(region, animated: true)
        }
        
        func fetchChildLocation()  {
            if IsLoggedIn{
                if self.accountType == .parent {
                    guard let  childID = TrackingViewController.trackedChildUId else {return}
                    DataHandler.shared.fetchChildLocation(for: childID) { [weak self](location) in
                        guard let fetchedLocation = location else {return}
                        let region = MKCoordinateRegion(center: fetchedLocation.coordinate , span:MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
                        DispatchQueue.main.async {
                            self?.mapView.setRegion(region, animated: true)
                            let annotation = ChildAnnotation(uid: childID, coordinate: fetchedLocation.coordinate)
                            if ((self!.mapView.annotations.contains(where: { (annotation) -> Bool in
                                guard let childAnnnotation = annotation as? ChildAnnotation else{return false}
                                childAnnnotation.updateMapView(with: fetchedLocation.coordinate)
                                return true
                            })) )
                            {
                            }
                            else{
                                self?.mapView.addAnnotation(annotation)
                            }
                        }
                    }
                }
            }
            else{
                centerMapOnUserLocation()
            }
        }
        
        func fetchUserInfo(){
            DataHandler.shared.fetchUserInfo { [weak self](user) in
                self?.user = user
                self?.accountType = AccountType(rawValue: user.accountType)
            }
        }
        
        @IBOutlet weak var addChildButton: UIButton!
        @IBAction func AddChildPressed(_ sender: UIButton) {
            if !IsLoggedIn{
                performSegue(withIdentifier: "showSignIn", sender: sender)
                print("please log in")
            }
            else if IsLoggedIn {
                if self.accountType == .parent{
                    performSegue(withIdentifier: "AddChildSegue", sender: sender)
                    print("you are logged in")
                } else if self.accountType == .child{
                    print("child are logged in")
                   // howww
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
            self.mapView.showsUserLocation = true
            mapView.userTrackingMode = .follow
            mapView.isZoomEnabled = true
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
            guard let uid = Auth.auth().currentUser?.uid else {return}
            DataHandler.shared.fetchChildsInfo(for: uid) {[weak self] (child,childID) in
                self?.childs.append(child)
                self?.childsID.append(childID)
                DispatchQueue.main.async {
                    self?.childsCollectionView.reloadData()
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
                    if let childImageURl = child.imageURL {
                        childCell.profileImageView.loadImageUsingCacheWithUrlString(childImageURl)
                        annotationImage = childCell.profileImageView.image?.resize(70 , 70)
                    }
                    else{childCell.profileImageView.image = #imageLiteral(resourceName: "person").resize(70 , 70)}
                }
                return childCell
            }
            return cell
        }
        
        func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
            self.mapView.removeAnnotations(mapView.annotations)
            trackedChild = childs[indexPath.item]
            print("tracked child now is \(String(describing: trackedChild?.name)) ")
            TrackingViewController.trackedChildUId = childsID[indexPath.item]
            print("tracked child now is \(String(describing: TrackingViewController.trackedChildUId)) ")
            if let cell = childsCollectionView.cellForItem(at: indexPath) as? ChildsCollectionViewCell {
                self.annotationImage = nil
                DispatchQueue.main.async {
                    self.annotationImage = cell.profileImageView.image?.resize(60 , 60)
                }
            }
            fetchChildLocation()
        }
    }
