    //
    //  DataHandler.swift
    //  TracKids
    //
    //  Created by AHMED GAMAL  on 2/4/21.
    //
    import Foundation
    import Firebase
    import GeoFire
    import UIKit

    let DBReference = Database.database().reference()
    let UserReference = DBReference.child("users")
    let ChildLocationReference = DBReference.child("childLocation")
    let TrackedChildsReference = DBReference.child("TrackedChilds")
    let MessagesReference = DBReference.child("Messages")
    let ObservedPlacesReference = DBReference.child("ObservedPlaces")
    let HistoryReference = DBReference.child("LocationHistory")
    let storage = Storage.storage()
    var FetchedPlaces = [CLLocation]()
    var placesId = [String]()

    struct DataHandler{
        static  let shared  = DataHandler()
        
        func fetchUserInfo(completion : @escaping (User) -> Void) {
            guard let uid = Auth.auth().currentUser?.uid else {return}
            UserReference.child(uid).observeSingleEvent(of: .value) { (snapshot) in
                let userID = snapshot.key
                guard let userInfo = snapshot.value as? [String : Any] else {return}
                let user = User(uid: userID, dictionary: userInfo)
                completion(user)
            }
        }
        
        func fetchChildAccount(with childId : String, completion : @escaping (User) -> Void){
            guard let uid = Auth.auth().currentUser?.uid else {return}
            TrackedChildsReference.child(uid).child(childId).observeSingleEvent(of: .value) { snapshot in
                let childID = snapshot.key
                guard let childInfo = snapshot.value as? [String : Any] else {return}
                let child = User(uid: childID, dictionary: childInfo)
                completion(child)
            }
        }
        
        func fetchChildsInfo(for uid : String, completion : @escaping (User ,  _ childID : String) -> Void)  {
            TrackedChildsReference.child(uid).observe(.childAdded, with: { (snapshot) in
                guard let childInfo = snapshot.value as? [String : Any] else {
                    return}
                let childID = snapshot.key
                let child = User(uid: childID, dictionary: childInfo)
                completion(child,childID)
                print("33 good info")
            })
        }
        
        func fetchChildLocation(for childID : String, completion : @escaping (CLLocation?) -> Void){
            let geofire = GeoFire(firebaseRef: ChildLocationReference)
            ChildLocationReference.observe(.value) { (snapshot) in
                geofire.getLocationForKey(childID) { (location, error) in
                    if error != nil {print(error!.localizedDescription) }
                    guard let childLocation = location else {return}
                    completion(childLocation)
                }
            }
        }
        
        
        func fetchObservedPlaces(for childID : String, completion : @escaping ([CLLocation]?, [String]) -> Void){
            FetchedPlaces = []
            placesId = []
            guard let uid = Auth.auth().currentUser?.uid else {return}
            let geofire = GeoFire(firebaseRef: ObservedPlacesReference.child(uid).child(childID))
            ObservedPlacesReference.child(uid).child(childID).observe(.childAdded) { (snapshot) in
                let key = snapshot.key
                placesId.append(key)
                geofire.getLocationForKey(key) { (location, error) in
                    if error != nil {print(error!.localizedDescription) }
                    guard let FetchedPlace = location else {return}
                    FetchedPlaces.append(FetchedPlace)
                    completion(FetchedPlaces,placesId)
                }
            }
        }
        
        func uploadObservedPlace(_ location : CLLocation, for Child : String){
            guard let uid = Auth.auth().currentUser?.uid else {return}
            let placeReference = ObservedPlacesReference.child(uid).child(Child)
            let key = placeReference.childByAutoId().key
            let geoFire = GeoFire(firebaseRef: placeReference)
            geoFire.setLocation(location, forKey: key ?? "no key")
        }
        
        func uploadMessageWithInfo(_ messageText : String , _ recipient : String)  {
            guard  let sender = Auth.auth().currentUser?.uid else{return}
            let messageBody = messageText
            let recipient = recipient
            let timestamp = Int(Date().timeIntervalSince1970)
            let fromDevice : String? = AppDelegate.DEVICEID
            let messsageInfo = ["sender" : sender,
                                "body"  : messageBody,
                                "recipient" : recipient,
                                "timestamp" : timestamp,
                                "fromDevice": fromDevice ?? "no device"] as [String : Any]
            self.fetchUserInfo { (user) in
                if user.accountType == 0 {
                    MessagesReference.child(sender).child(recipient).childByAutoId().updateChildValues(messsageInfo)
                }
                else if user.accountType == 1 {
                    MessagesReference.child(user.parentID!).child(sender).childByAutoId().updateChildValues(messsageInfo)
                }
            }
        }
        
        func convertLocationToAdress(for location : CLLocation?, completion : @escaping((Location?) -> Void)) {
            let geocoder = CLGeocoder()
            geocoder.reverseGeocodeLocation(location!) { (placeMarks, error) in
                if error != nil {print(error!.localizedDescription) }
                guard let placemarks = placeMarks , error == nil else {completion(nil)
                    return}
                
                let placeData = placemarks[0]
                var name = ""
                if let streetDetails = placeData.subThoroughfare{
                    name += streetDetails
                }
                if let street = placeData.thoroughfare{
                    name += " \(street)"
                }
                if let locality = placeData.locality{
                    name += ", \(locality)"
                }
                
                if let adminRegion = placeData.administrativeArea {
                    name += ", \(adminRegion)"
                }
                
                if let country = placeData.country{
                    name += ", \(country)"
                }
                let place = Location(title: name, details: "", coordinates: placeData.location?.coordinate ?? CLLocationCoordinate2D())
                completion(place)
            }
        }
        
        func sendPushNotification(to recipientToken : String, sender : String, body : String) {
            if let url = URL(string: AppDelegate.NOTIFICATION_URL) {
                var request = URLRequest(url: url)
                request.allHTTPHeaderFields = ["Content-Type":"application/json", "Authorization":"key=\(AppDelegate.SERVERKEY)"]
                request.httpMethod = "POST"
                request.httpBody = "{\"to\":\"\(recipientToken)\",\"notification\":{\"title\":\"\(sender)\",\"body\":\"\(body)\",\"sound\":\"default\",\"content-available\":\"1\",\"badge\":\"1\"}}".data(using: .utf8)
                URLSession.shared.dataTask(with: request) { (data, urlresponse, error) in
                    if error != nil {
                        print("error")
                    } else {
                        print("Successfully sent!.....")
                    }
                }.resume()
            }
        }
        
        func fetchDeviceID(for uid : String,  completion : @escaping (String) -> Void) {
            UserReference.child(uid).observeSingleEvent(of: .value) { (snapshot) in
                guard let dictionary = snapshot.value as? [String:Any] else {return}
                let recipientDevice = dictionary["deviceID"] as! String
                let name = dictionary["name"] as! String
                print("device name is \(name)")
                print("Device is \(recipientDevice)")
                completion(recipientDevice)
            }
        }
        
        
        
        func removeAccount( for currentUser : String, completion : @escaping () -> Void ){
            UserReference.child(currentUser).removeValue { error, reference in
                ChildLocationReference.child(currentUser).removeValue { error, reference in
                    HistoryReference.child(currentUser).removeValue { error, reference in
                        TrackedChildsReference.child(currentUser).removeValue { error, reference in
                            ObservedPlacesReference.child(currentUser).removeValue { error, reference in
                                MessagesReference.child(currentUser).removeValue { error, reference in
                                    completion()
                                    print("removed successfully")
                                }
                            }
                        }
                    }
                }
            }
        }
        
        func removeChild(of parentUid : String, withId childID : String){
            self.fetchChildAccount(with: childID) { child in
                guard  let parentId = Auth.auth().currentUser?.uid else{return}
                UserReference.child(childID).removeValue { error, reference in
                    HistoryReference.child(parentId).child(childID).removeValue { error, response in
                        ChildLocationReference.child(parentId).child(childID).removeValue { error, reference in
                            MessagesReference.child(parentId).child(childID).removeValue { error, reference in
                                TrackedChildsReference.child(parentId).child(childID).removeValue { error, reference in
                                    ObservedPlacesReference.child(parentId).child(childID).removeValue { error, reference in
                                        let storage = Storage.storage()
                                        if    let url = child.imageURL{
                                            let storageRef = storage.reference(forURL: url)
                                            storageRef.delete { error in
                                                if let error = error {
                                                    print(error)
                                                } else {
                                                    print("Debug: child account removed successfully")
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        
        func updateChildInfo(forId childId : String, withImage newImage : UIImage, name: String, completion : @escaping () -> Void){
            guard let parenId = Auth.auth().currentUser?.uid else {return}
            self.fetchChildAccount(with: childId) { child in
                let storageReference = storage.reference()
                let childName = child.name
                let imageReference  = storageReference.child("ChildsPictures/\(parenId)/\(childName).jpg")
                imageReference.delete { error in
                    if error != nil{print("error in deleting\(String(describing: error?.localizedDescription))")}
                    else {
                        if let imageData =  newImage.jpegData(compressionQuality: 0.3){
                            let newImageReference  = storageReference.child("ChildsPictures/\(parenId)/\(name).jpg")
                            
                            newImageReference.putData(imageData, metadata: nil) { metaData, error in
                                
                                if error != nil {print(error!.localizedDescription)}
                                newImageReference.downloadURL { (url, error) in
                                    if error != nil {print(error!.localizedDescription)}
                                    if let downloadedURL = url{
                                        let urlReference = UserReference.child(childId)
                                        let trackedChildReference = TrackedChildsReference.child(parenId).child(childId)
                                        trackedChildReference.updateChildValues(["imageURL" : downloadedURL.absoluteString, "name" : name]) { error, reference in
                                            if error != nil {print(error!.localizedDescription)}
                                            urlReference.updateChildValues(["imageURL" : downloadedURL.absoluteString, "name" : name]) { error, reference in
                                                if error != nil {print(error!.localizedDescription)}
                                                completion()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        
    }










