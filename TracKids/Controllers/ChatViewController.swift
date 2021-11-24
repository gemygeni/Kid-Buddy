    //
    //  ChatViewController.swift
    //  TracKids
    //
    //  Created by AHMED GAMAL  on 9/7/21.
    //

    import UIKit
    import Firebase

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
                self.accountType = AccountType(rawValue: user.accountType)
                self.parentID = user.parentID
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
                self.downloadMessages()
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
        
        @IBAction func sendMessagePressed(_ sender: UIButton) {
            handleSendingMessage()
        }
        
        func handleSendingMessage(){
            guard let messageText = messageTextfield.text, !messageText.isEmpty  else {return}
            
            if self.accountType == .parent{
                if let childID = self.uniqueID{
                    DataHandler.shared.uploadMessageWithInfo(messageText, childID)
                }
            }
            else if self.accountType == .child{
                if let parentID = self.parentID{
                    DataHandler.shared.uploadMessageWithInfo(messageText, parentID)
                }
            }
            messageTextfield.text = ""
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
            if let timeBySeconds = message.timestamp?.doubleValue {
                let messageDate = Date(timeIntervalSince1970: timeBySeconds)
                let formatter = DateFormatter()
                formatter.timeZone = TimeZone.current
                formatter.dateFormat = "yy-MM-dd HH:mm a"
                   // "hh:mm a"
//    let s = String(format: "%@,%f,%f,%@\n", dateString, locValue.latitude, locValue.longitude, self.currentDevice)

                  
                
                cell.timeLabel.numberOfLines = 0
                cell.timeLabel.text = formatter.string(from: messageDate)
               }
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
            textField.resignFirstResponder()
            return true
        }
    }
