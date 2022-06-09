    //
    //  DataHandler.swift
    //  TracKids
    //
    //  Created by AHMED GAMAL  on 2/4/21.
    import UIKit
    import Firebase
    import GeoFire
    import CryptoKit


    let DBReference = Database.database().reference()
    let UserReference = DBReference.child("users")
    let ChildLocationReference = DBReference.child("childLocation")
    let TrackedChildsReference = DBReference.child("TrackedChilds")
    let MessagesReference = DBReference.child("Messages")
    let ObservedPlacesReference = DBReference.child("ObservedPlaces")
    let HistoryReference = DBReference.child("LocationHistory")
    let storage = Storage.storage()
    var FetchedPlaces = [CLLocation]()
    var placesIds = [String]()

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
            placesIds = []
            guard let uid = Auth.auth().currentUser?.uid else {return}
            let geofire = GeoFire(firebaseRef: ObservedPlacesReference.child(uid).child(childID))
            ObservedPlacesReference.child(uid).child(childID).observe(.childAdded) { (snapshot) in
                let key = snapshot.key
                placesIds.append(key)
                geofire.getLocationForKey(key) { (location, error) in
                    if error != nil {print(error!.localizedDescription) }
                    guard let FetchedPlace = location else {return}
                    FetchedPlaces.append(FetchedPlace)
                    completion(FetchedPlaces,placesIds)
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
        
        func uploadMessageWithInfo(_ messageText : String , _ recipient : String, ImageURL : String? ,completion : @escaping(() -> Void) )  {
            guard  let sender = Auth.auth().currentUser?.uid else{return}
            let messageBody = messageText
            let recipient = recipient
            let timestamp = Int(Date().timeIntervalSince1970)
            let fromDevice : String? = AppDelegate.DEVICEID
            let messsageInfo = ["sender" : sender,
                                "body"  : messageBody,
                                "recipient" : recipient,
                                "timestamp" : timestamp,
                                "fromDevice": fromDevice ?? "no device",
                                "imageURL" : ImageURL ?? ""] as [String : Any]
            self.fetchUserInfo { (user) in
                if user.accountType == 0 {
                    MessagesReference.child(sender).child(recipient).childByAutoId().updateChildValues(messsageInfo) { error, reference in
                        if error != nil {
                            print(error?.localizedDescription as Any)
                        }
                        else {
                            completion()
                        }
                    }
                }
                else if user.accountType == 1 {
                    MessagesReference.child(user.parentID!).child(sender).childByAutoId().updateChildValues(messsageInfo) { error, reference in
                        if error != nil {
                            print(error?.localizedDescription as Any)
                        }
                        else {
                            completion()
                        }
                    }
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
                        print("Successfully sent notification!.....")
                    }
                }.resume()
            }
        }
     //   "data": {"CRITICAL_ALERT":"YES"}
      //,\"data\":{\"isCritical\":\"1\"}
        
        
        
        
        
        
        
        
        func sendCriticalAlert(to recipientToken : String, sender : String, body : String) {
           let accessToken =  getAccessToken()
            if let url = URL(string: AppDelegate.NOTIFICATION_URL) {
                var request = URLRequest(url: url)
                request.allHTTPHeaderFields = ["Content-Type":"application/json",
                                               "Authorization":"Bearer \(accessToken)"]
                request.httpMethod = "POST"
                request.httpBody = "{\"message\":{\"token\":\"\(recipientToken)\",\"notification\":{\"title\":\"\(sender)\",\"body\":\"\(body)\" ,\"badge\":\"1\",\"sound\":{\"critical\":\"1\",\"name\":\"criticalAlert.m4a\",\"volume\":\"1.0\",\"mutable-content\":\"1\"}}}}".data(using: .utf8)
                
                
//                request.httpBody = "{\"to\":\"\(recipientToken)\",\"notification\":{\"title\":\"\(sender)\",\"body\":\"\(body)\",\"sound\":\"default\",\"content-available\":\"1\",\"badge\":\"1\"}}".data(using: .utf8)

                
                URLSession.shared.dataTask(with: request) { (data, urlresponse, error) in
                    if error != nil {
                        print("error")
                    } else {
                        print("Successfully sent critical alert!.....")
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
                                    
                                    let storageReference = storage.reference()
                                    
       let imageMessagesReference  = storageReference.child("Messages/\(String(describing: currentUser))")
                                    
                                    imageMessagesReference.delete { error in
        let childsPicturesReference  = storageReference.child("ChildsPictures/\(currentUser)")
                                        childsPicturesReference.delete { error in
                                            completion()
                                            print("removed successfully")

                                        }
                                    }
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
        
        
        
        func getAccessToken() -> String {
            let secret = "  MIIEvAIBADANBgkqhkiG9w0BAQEFAASCBKYwggSiAgEAAoIBAQCjNS3qx+zA88Zf\nP0uXRQMi960cYFeGd5LSAPVh5mv77hL14ypSDvNkuoqo2s/D4V/37YLSQ8Ur9swY\n6T26KHwXbwN0oYGxgTM1yPsEG/YdVJ/6UBAGDMwQgtN9dg4GexZgp4+Nf/sMBBZN\nOrGDeXLb6OfwoaUynKjnpQ2fWbI/swN3Bjco9lJD1InPGSKhJNY3/CLjG0Nq9Df0\nSyMDuxsBy/y4iScppA+OB/1HVl07SNiTErTBpT99UNCC5eJhnJtmiTSTrhE70qwh\nl0VSwr5jFgjWJ4Yu0fRtAWg+S+3MLGTW+d32KnfDiLNf9uoNTEk3K3jqbi1Anhme\nByUokAKbAgMBAAECggEAHzxrWFcBMgC2A766ee4kZoneoOKzfbHe8MBsNluCaUos\naNEcZW4lGS82oJCYWRYGZw4XDqUX1I08jLv/K2TaMyX1FFpg1xcyNOYNXMD5Pq3W\nnHK8Tlwepj5TudxhXM4r/z2ylNNcufUCS6+jD9WrrPkLgxt84Y3oKcWGMOxa2CPd\nRzeHJ0WvgJPj+AU/nY65YliFLfFIvvJJl7H/TXcpiJCkYOPe4blUU7zz3Kg/MUWY\nx79depBan/5GpJ01BRu/D4iHXl/yivdO4Mph++8A7SpAfs+/HZ310XuZCK807WxI\n0I4oVyfHWoY2GJV7p5KWPoeRsU/8FkseYb6a6CRwmQKBgQDfNmWuwW/Eng1WviBd\nv7DIEeZq+fNLVr+mb+r78Bn3yE/cB+PFdZ1aV+weRujoUfmhSWaGcICpBhi1km3B\nPsHj86gRS7TWCFawKUMtK9dBuRRJoMDszMsbkZn2icCLdDGbnu9mWNRdMSgLbho/\n3t17n7o5tEf4Inawvl+kprVglwKBgQC7LmJ6wRuCMTrup4z+DW30NN0M05LSF3Mn\nfRPHfPms362fYhVqZ/Rg+pFbpvgftdcacRS3GtX8XVyqpZv0wkJ0w6Y8trXr4/NN\nljabVvb7BIVGR3/Tv1vycR8u1kbllg/YFJwsw/g6kXKVZX31XrJx41Rse5w/43OB\nBW7fNr0qnQKBgAzHaHrgyC1RfyIAMIotd0l8/NwTA0LE7KPytFlIHbR521iVewzK\n9v89GV+CX8MtLkV1llEMD9Gdb7y1bWMq3J7YTD7xPqEiSRQ8yIPFhsVUezzb3y+v\nadFiPJZIvKU/ObfXGY2aeE39inVdEFOnxrZVJqw3Dge+sVzdCUy73pZxAoGAT1zk\nXl3AFxxee0/JJPJ2u0MqskSGjNNqfMS4fS2NAvI3wEsq/1miMPgsZ2rM600DLe/i\nM5yKPB0trCDZlhZDbRSDSFzDl4en4i6dapGd2GJbS6gHF7Wb+5hg+0/Y8YEFqL1c\nVlKkzdhbd+J3XHDRQh577h8e6au7jmnKT5P68rUCgYAcKpLkD5lvcawUyr+//zvo\nEifIyyxb2fcMXdsu0zZ9y4zAn7R6t78HcBhDtJzPi2cB6QHMJaghYktwQYkyfpTb\nzqdzJbBTFTVfl9UWrcI/OAhDwkg/kxTt92dzY2GunUT28WF6rTPYTlSpK2RtA6+n\n9jTsNZKzF+DhT+fCQyBxWQ=="
            let privateKey = SymmetricKey(data: Data(secret.utf8))

            let headerJSONData = try! JSONEncoder().encode(Header())
            let headerBase64String = headerJSONData.urlSafeBase64EncodedString()

            let payloadJSONData = try! JSONEncoder().encode(Payload())
            let payloadBase64String = payloadJSONData.urlSafeBase64EncodedString()

            let toSign = Data((headerBase64String + "." + payloadBase64String).utf8)

            let signature = HMAC<SHA256>.authenticationCode(for: toSign, using: privateKey)
            let signatureBase64String = Data(signature).urlSafeBase64EncodedString()

            let token = [headerBase64String, payloadBase64String, signatureBase64String].joined(separator: ".")
            print(token)
            return token
        }

    }

extension Data {
    
    func urlSafeBase64EncodedString() -> String {
        return base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}

struct Header: Encodable {
    let alg = "HS256"
    let typ = "JWT"
}

struct Payload: Encodable {
    let sub = "1234567890"
    let name = "John Doe"
    let iat = 1516239022
}


