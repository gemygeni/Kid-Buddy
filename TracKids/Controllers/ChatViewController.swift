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
    var messagesId : [String] = []
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
    var trackingVC = TrackingViewController()
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var messageTextfield: UITextField!{
        didSet{
            messageTextfield.delegate = self
        }
    }
    
    var messageReference = DatabaseReference()
    
    func configureMessageReference(childID : String? = nil, parentId : String? = nil ) ->  DatabaseReference{
        if let UId = Auth.auth().currentUser?.uid{
            var  messageReference = DatabaseReference()
            if accountType == .parent{
                if let trackedChildID = childID {
                    messageReference = MessagesReference.child(UId).child(trackedChildID)
                }
            }
            else if accountType == .child{
                if let childParentID = parentId{
                    messageReference =  MessagesReference.child(childParentID).child(UId)
                }
            }
            return messageReference
        }
        return messageReference
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        if Auth.auth().currentUser?.uid == nil{
            messages = []
            messagesId = []
            tableView.reloadData()
        }
        
        configureTableView()
        DataHandler.shared.fetchUserInfo { [weak self] user in
            self?.accountType = AccountType(rawValue: user.accountType)
            self?.parentID = user.parentID
            self?.userName = user.name
            self?.downloadMessages()
        }
        if let  trackedChildUId = TrackingViewController.trackedChildUId{
            self.uniqueID = trackedChildUId
            tableView.reloadData()
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
        configureTableView()
        DataHandler.shared.fetchUserInfo {[weak self] user in
            self?.accountType = AccountType(rawValue: user.accountType)
            self?.parentID = user.parentID
        }
        
        if let  trackedChildUId = TrackingViewController.trackedChildUId{
            uniqueID = trackedChildUId
        }
        navigationItem.title = childName
        resetBadgeCount()
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
        tableView.allowsMultipleSelectionDuringEditing = true
        messageTextfield.becomeFirstResponder()
    }
    
    @IBAction func sendMessagePressed(_ sender: UIButton) {
        handleSendingMessage()
        downloadMessages()
    }
    
    func downloadMessages(){
        self.messages = []
        self.messagesId = []
        messageReference = configureMessageReference(childID: uniqueID, parentId: parentID)
        messageReference.observe(.childAdded) { [weak self](snapshot) in
            let messageId = snapshot.key
            self?.messagesId.append(messageId)
            if let messageInfo = snapshot.value as? [String : Any] {
                let message = Message( messageInfo)
                self?.messages.append(message)
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                    if self!.messages.count > 1{
                        let indexPath = IndexPath(row: self!.messages.count - 1, section: 0)
                        self?.tableView.scrollToRow(at: indexPath, at: .top, animated: false)
                    }
                }
            }
        }
    }
    
    
    
    func handleSendingMessage(){
        guard let messageText = messageTextfield.text,let sender = self.userName, !messageText.isEmpty  else {return}
        
        if self.accountType == .parent{
            if let childID = self.uniqueID{
                DataHandler.shared.uploadMessageWithInfo(messageText, childID)
                DataHandler.shared.fetchDeviceID(for: childID) { deviceID in
                    DataHandler.shared.sendPushNotification(to: deviceID, sender: sender, body: messageText)
                }
            }
        }
        else if self.accountType == .child{
            if let parentID = self.parentID{
                DataHandler.shared.uploadMessageWithInfo(messageText, parentID)
                DataHandler.shared.fetchDeviceID(for: parentID) { deviceID in
                    DataHandler.shared.sendPushNotification(to: deviceID, sender: sender, body: messageText)
                }
            }
        }
        messageTextfield.text = ""
    }
    
    func resetBadgeCount() {
        UserDefaults.standard.setValue(0, forKey: "badgeCount")
        UIApplication.shared.applicationIconBadgeNumber = 0
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
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete{
            let messageId = messagesId[indexPath.row]
            let selectedReference =  self.messageReference.child(messageId)
            selectedReference.removeValue()
            messages.remove(at: indexPath.row)
            messagesId.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
}

extension ChatViewController : UITextFieldDelegate{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        handleSendingMessage()
        return true
    }
}

