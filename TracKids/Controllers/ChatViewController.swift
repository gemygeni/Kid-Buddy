    //
    //  ChatViewController.swift
    //  TracKids
    //
    //  Created by AHMED GAMAL  on 9/7/21.
    //

    import UIKit
    import Firebase
    import Alamofire
    class ChatViewController: UIViewController{
        var messages : [Message] = []
        var childID : String?{
            didSet{
               self.uniqueID = childID
            }
        }
        var childName : String = "child"
        var trackedChildObserver : NSObjectProtocol?
        var uniqueID : String?
        var parentID : String?
        var userName : String?
        var profileImage : UIImage?
        var accountType : AccountType!
        let uid = Auth.auth().currentUser?.uid
        var trackingVC = TrackingViewController()
        @IBOutlet weak var tableView: UITableView!
        @IBOutlet weak var messageTextfield: UITextField!{
            didSet{
                messageTextfield.delegate = self
            }
        }
        
        var messageReference = DatabaseReference()
        
        func configureMessageReference(childID : String? = nil, parentId : String? = nil ) ->  DatabaseReference{
            if let UId = uid{
            var  messageReference = DatabaseReference()
            
            if accountType == .parent{
                if let trackedChildID = childID {
                    messageReference = Database.database().reference().child("Messages").child(UId).child(trackedChildID)
                }
            }
            else if accountType == .child{
                if let childParentID = parentId{
                    messageReference =  Database.database().reference().child("Messages").child(childParentID).child(UId)
                }
              }
                return messageReference
            }
            return messageReference
        }
        
        
        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(true)
            
            configureTableView()
            DataHandler.shared.fetchUserInfo { (user) in
                print("ddd \(user.accountType)")
                self.accountType = AccountType(rawValue: user.accountType)
                self.parentID = user.parentID
                self.userName = user.name
               self.downloadMessages()
               }
            if let  trackedChildUId = TrackingViewController.trackedChildUId{
                uniqueID = trackedChildUId
               }
            trackedChildObserver = NotificationCenter.default.addObserver(forName: .TrackedChildDidChange,
                                                                          object: TrackingViewController.trackedChildUId,
                                                                          queue: OperationQueue.main,
                                                                          using: { [weak self] (notification) in
                                                                            self?.uniqueID = TrackingViewController.trackedChildUId
                                                                            self?.downloadMessages()
                                                                          })
                                                                  }
                
        override func viewDidLoad() {
            super.viewDidLoad()
            print("chat downloaded")
            configureTableView()
            
            DataHandler.shared.fetchUserInfo { (user) in
                self.accountType = AccountType(rawValue: user.accountType)
                self.parentID = user.parentID
              }
            if let  trackedChildUId = TrackingViewController.trackedChildUId{
                uniqueID = trackedChildUId
             }
            navigationItem.title = childName
        }
        
        override func viewDidDisappear(_ animated: Bool) {
            super.viewDidDisappear(true)
            if let observer = trackedChildObserver {
                NotificationCenter.default.removeObserver(observer)
            }
        }
        
        func configureTableView(){
            tableView.delegate = self
            tableView.dataSource = self
            tableView.register(UINib(nibName: "MessageCell", bundle: nil), forCellReuseIdentifier: "ReusableCell")
            tableView.backgroundColor = #colorLiteral(red: 1, green: 0.5763723254, blue: 0, alpha: 0.7545114437)
            messageTextfield.becomeFirstResponder()
        }
        
        @IBAction func sendMessagePressed(_ sender: UIButton) {
            handleSendingMessage()
            downloadMessages()
        }

        func downloadMessages(){
        self.messages = []
        messageReference = configureMessageReference(childID: uniqueID, parentId: parentID)
        messageReference.observe(.childAdded) { (snapshot) in
                if let messageInfo = snapshot.value as? [String : Any]{
                let message = Message( messageInfo)
                self.messages.append(message)
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                    if self.messages.count > 1{
                    let indexPath = IndexPath(row: self.messages.count - 1, section: 0)
                    self.tableView.scrollToRow(at: indexPath, at: .top, animated: false)
                    }
                  }
                }
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
        
        func handleSendingMessage(){
            guard let messageText = messageTextfield.text,let sender = self.userName, !messageText.isEmpty  else {return}
            
            if self.accountType == .parent{
                if let childID = self.uniqueID{
                    DataHandler.shared.uploadMessageWithInfo(messageText, childID)
                    fetchDeviceID(for: childID) { deviceID in
                        self.sendPushNotification(to: deviceID, sender: sender, body: messageText)
                    }
                }
            }
            else if self.accountType == .child{
                if let parentID = self.parentID{
                    DataHandler.shared.uploadMessageWithInfo(messageText, parentID)
                    fetchDeviceID(for: parentID) { deviceID in
                        self.sendPushNotification(to: deviceID, sender: sender, body: messageText)
                    }
                }
            }
            messageTextfield.text = ""
        }
        
   func sendPushNotification(to recipientToken : String, sender : String, body : String) {
       if let url = URL(string: AppDelegate.NOTIFICATION_URL) {
         var request = URLRequest(url: url)
         request.allHTTPHeaderFields = ["Content-Type":"application/json", "Authorization":"key=\(AppDelegate.SERVERKEY)"]
         request.httpMethod = "POST"
         request.httpBody = "{\"to\":\"\(recipientToken)\",\"notification\":{\"title\":\"\(sender)\",\"body\":\"\(body)\",\"sound\":\"default\",\"badge\":\"1\"},\"data\": {\"customDataKey\": \"customDataValue\"}}".data(using: .utf8)
         URLSession.shared.dataTask(with: request) { (data, urlresponse, error) in
           if error != nil {
              print("error")
           } else {
              print("Successfully sent!.....")
           }
         }.resume()
         }
        }
    }
    extension ChatViewController : UITableViewDataSource, UITableViewDelegate{
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            messages.count
        }
        
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell  = tableView.dequeueReusableCell(withIdentifier: "ReusableCell", for: indexPath) as! MessageCell
            cell.backgroundColor = UIColor.clear
            let message = messages[indexPath.row]
            cell.MessageBodyLabel.text = message.body
            cell.timeLabel.numberOfLines = 0
            cell.timeLabel.text = message.timestamp?.convertDateFormatter()
            if message.sender == Auth.auth().currentUser?.uid{
                cell.MessageBodyLabel.backgroundColor = #colorLiteral(red: 0.721568644, green: 0.8862745166, blue: 0.5921568871, alpha: 1)
                cell.rightImageView.isHidden = true
              }
            else{
                cell.MessageBodyLabel.backgroundColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
                if let profileImage = self.profileImage{
                    cell.rightImageView.image = profileImage
                }        }
            return cell
        }
    }


    extension ChatViewController : UITextFieldDelegate{
        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            handleSendingMessage()
            return true
        }
    }
