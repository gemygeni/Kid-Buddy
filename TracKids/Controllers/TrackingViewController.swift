//
//  HomeViewController.swift
//  TracKids
//
//  Created by AHMED GAMAL  on 1/30/21.
//

import UIKit
import MapKit
import Firebase
import SwiftOTP
enum AccountType : Int  {
    case parent
    case child
}

class TrackingViewController: UIViewController  {
    var accountType : AccountType!
    var childs = [User?]()
    var childsID = [String]()
    var AuthHandler : AuthStateDidChangeListenerHandle?
    var annotationImage : UIImage?
    var fetchedImageView :  UIImageView?
    var IsLoggedIn : Bool = false

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
    
    static var trackedChildUId : String?
    @IBOutlet weak var childsCollectionView: UICollectionView!
    @IBOutlet weak var addChildButton: UIButton!
    @IBOutlet weak var mapView: MKMapView!
    let locationManager = LocationHandler.shared.locationManager
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    @IBAction func changeMapTypeButtonPressed(_ sender: Any) {
        if mapView.mapType == .standard{
            mapView.mapType = .hybrid
        }
        else if mapView.mapType == .hybrid {
            mapView.mapType = .standard
        }
    }
    
    @IBAction func AddChildPressed(_ sender: UIButton) {
        if !IsLoggedIn{
            performSegue(withIdentifier: "showSignIn", sender: sender)
        }
        else if IsLoggedIn {
            if self.accountType == .parent{
                
                let alert = UIAlertController(title: "choose how to join a child", message: "create a new child account or send a code to existing one", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Send Code", style: .default, handler: { [weak self] action in
                    self?.configureDynamicLink()
                }))
                
                alert.addAction(UIAlertAction(title: "Create Account", style: .default, handler: { [weak self] action in
                    self?.performSegue(withIdentifier: "AddChildSegue", sender: sender)
                }))
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                self.present(alert, animated: true, completion: nil)
            }
            else if self.accountType == .child{
                performSegue(withIdentifier: "presentOTPSegue", sender: sender)
            }
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
        fetchUserInfo()
        configureMapView()
        if self.accountType == .parent {
            print("Debug: hey i am parent and i willappear")
            self.childsCollectionView?.reloadData()
            fetchChildLocation()
        }
        AuthHandler =  Auth.auth().addStateDidChangeListener({ [weak self] (_, user) in
            if user == nil {
                self?.centerMapOnUserLocation()
                self?.childsCollectionView?.isHidden = true
                self?.addChildButton.isHidden = true
            }
            else{
                self?.childsCollectionView?.isHidden = false
                self?.addChildButton.isHidden = false
            }
        })
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(true)
        self.tabBarItem.title = "Track"
    }
    // MARK: - function to check if user is logged in database or not.
    func CheckLogIn() -> Bool {
        if user?.uid == nil {
            print("Debug: not logged in")
            IsLoggedIn = false
            return false
        }
        else {
            IsLoggedIn = true
            return true
        }
    }
    
    // MARK: - function to fetch user data from database.
    func fetchUserInfo(){
        DataHandler.shared.fetchUserInfo { [weak self](user) in
            self?.user = user
            self?.accountType = AccountType(rawValue: user.accountType)
            self?.navigationItem.title = user.name
        }
    }
    
    // MARK: - functions to configure Map view and center on user Location.
    func configureMapView(){
        mapView.delegate = self
        self.mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        mapView.isZoomEnabled = true
    }
    
    func centerMapOnUserLocation() {
        guard let coordinate = self.locationManager?.location?.coordinate else { return }
        let region = MKCoordinateRegion(center: coordinate,
                                        latitudinalMeters: 2000,
                                        longitudinalMeters: 2000)
        mapView.setRegion(region, animated: true)
    }
    
    // MARK: - function to fetch Child realtime Location from database.
    func fetchChildLocation()  {
        if IsLoggedIn{
            if self.accountType == .parent {
                guard let  childID = TrackingViewController.trackedChildUId else {return}
                DataHandler.shared.fetchChildLocation(for: childID) { [weak self](location) in
                    guard let fetchedLocation = location else {return}
                    let region = MKCoordinateRegion(center: fetchedLocation.coordinate , span:MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
                    //display child location on the map with annotation.
                    DispatchQueue.main.async {
                        self?.mapView.setRegion(region, animated: true)
                        let annotation = ChildAnnotation(uid: childID, coordinate: fetchedLocation.coordinate)
                        if ((self!.mapView.annotations.contains(where: { (annotation) -> Bool in
                            guard let childAnnnotation = annotation as? ChildAnnotation else{return false}
                            childAnnnotation.updateMapView(with: fetchedLocation.coordinate)
                            return true
                        })))
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
    
    
    // MARK: - Navigation.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "AddChildSegue" {
            if let addChildVC = segue.destination as? AddChildViewController{
                addChildVC.delegate = self
            }
        }
    }
    
    //MARK: - function to configure Dynamic Link with OTP to send it to child device to join it in database.
    func configureDynamicLink(){
        activityIndicatorView.startAnimating()
        var components = URLComponents()
        components.scheme = "https"
        components.host = "apps.apple.com/app/1600337105"
        guard let linkParameter = components.url else { return }
        print("Debug: I am sharing \(linkParameter.absoluteString)")
        let domain = "https://trackids.page.link"
        guard let linkBuilder = DynamicLinkComponents
            .init(link: linkParameter, domainURIPrefix: domain) else {
            return
        }
        if let myBundleId = Bundle.main.bundleIdentifier {
            linkBuilder.iOSParameters = DynamicLinkIOSParameters(bundleID: myBundleId)
        }
        linkBuilder.iOSParameters?.appStoreID = "1600337105"
        linkBuilder.socialMetaTagParameters = DynamicLinkSocialMetaTagParameters()
        guard let uid =   Auth.auth().currentUser?.uid else{return}
        guard let data = Data(base64Encoded: uid) else{return}
        if let totp = TOTP(secret: data) {
            if  let otpString = totp.generate(time: Date()){
                linkBuilder.socialMetaTagParameters?.title = "Check this link & Join kid Buddy by this code: \(otpString) "
                print("Debug: otp is \(String(describing: otpString))")
                OTPReference.child(String(describing: otpString)).updateChildValues(["parentId": uid])
            }
        }
        linkBuilder.socialMetaTagParameters?.descriptionText = "if you recieved this link from your parents install kid Buddy"
        guard let longURL = linkBuilder.url else { return }
        print("Debug: The long dynamic link is \(longURL.absoluteString)")
        linkBuilder.shorten {[weak self] url, warnings, error in
            if let error = error {
                print("Debug: Oh no! Got an error! \(error)")
                return
            }
            if let warnings = warnings {
                for warning in warnings {
                    print("Debug: Warning: \(warning)")
                }
            }
            guard let url = url else { return }
            print("Debug: I have a short dynamic link to share! \(url.absoluteString)")
            self?.shareItem(with: url)
        }
    }
    
    // MARK: - function to display Activity ViewController
    func shareItem(with url: URL) {
        let subjectLine = ""
        let activityView = UIActivityViewController(activityItems: [subjectLine, url], applicationActivities: nil)
        UIApplication.shared.connectedScenes.compactMap { ($0 as? UIWindowScene)?.keyWindow }
            .first?.rootViewController?.present(activityView, animated: true, completion: {[weak self] in
                self?.activityIndicatorView.stopAnimating()
            })
      }
    
    // MARK: - function to fetch childs info and update collectionview data.
    func fetchChildsItems(){
        childs = []
        childsID = []
        guard let uid = Auth.auth().currentUser?.uid else {return}
        DataHandler.shared.fetchChildsInfo(for: uid) {[weak self] child, childID in
            self?.childs.append(child)
            self?.childsID.append(childID)
            DispatchQueue.main.async {
                self?.childsCollectionView.reloadData()
            }
        }
    }
}

// MARK: - MKMapViewDelegate Methods.
extension TrackingViewController : MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? ChildAnnotation {
            let view = MKAnnotationView(annotation: annotation, reuseIdentifier: "childAnnotation")
            view.image =  annotationImage ?? #imageLiteral(resourceName: "person").resize(70,70)
            view.layer.cornerRadius = 25
            view.clipsToBounds = true
            return view
        }
        return nil
    }
}
// MARK: - UICollectionViewDelegate, UICollectionViewDataSource Methods.
extension TrackingViewController : UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return  childs.count
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
        
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ChildProfileCell", for: indexPath)
        if let childCell = cell as? ChildsCollectionViewCell{
            childCell.profileImageView.image =  #imageLiteral(resourceName: "person").resize(70,70)
            if let child = childs[indexPath.item]{
                if let childImageURl = child.imageURL {
                    childCell.profileImageView.loadImageUsingCacheWithUrlString(childImageURl)
                    annotationImage = childCell.profileImageView.image?.resize(60,60)
                }
                else{childCell.profileImageView.image = #imageLiteral(resourceName: "person").resize(70,70)}
            }
            return childCell
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.mapView.removeAnnotations(mapView.annotations)
        trackedChild = childs[indexPath.item]
        print("Debug: tracked child now is \(String(describing: trackedChild?.name)) ")
        TrackingViewController.trackedChildUId = childsID[indexPath.item]
        if let cell = childsCollectionView.cellForItem(at: indexPath) as? ChildsCollectionViewCell {
            self.annotationImage = nil
            DispatchQueue.main.async {
                self.annotationImage = cell.profileImageView.image?.resize(60,60)
            }
        }
        guard let childId = TrackingViewController.trackedChildUId else {return}
        DataHandler.shared.fetchChildAccount(with: childId) {[weak self] user in
            print("Debug: selected \(user.name)")
            self?.tabBarItem.title = user.name + " tracked"
            self?.navigationItem.title = user.name
        }
        fetchChildLocation()
    }
}

// MARK: - delegate method triggered when new child created.
extension TrackingViewController : AddedChildDelegate{
    func didAddChild(_ sender: AddChildViewController) {
        self.fetchChildsItems()
    }
}
