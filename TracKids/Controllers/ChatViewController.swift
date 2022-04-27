//
//  ChatViewController.swift
//  TracKids
//
//  Created by AHMED GAMAL  on 9/7/21.
//

import UIKit
import Firebase
import MobileCoreServices
class ChatViewController: UIViewController{
    var trackedChildObserver : NSObjectProtocol?
    var messages : [Message] = []
    var messagesIds : [String] = []
    let leadingScreensForBatching:CGFloat = 2.0
    var fetchingMore = false
    var endReached = false
    var trackedChildChanged = false
    private var ImageURL : String?
    var childID : String?{
        didSet{
            self.uniqueID = childID
        }
    }
    var childName : String = "child"
    var uniqueID : String?
    var parentID : String?
    var userName : String?
    var profileImage : UIImage?
    var imageMessage : UIImage?
    var accountType : AccountType!
    var trackingVC = TrackingViewController()
    var sendPressed = false
    var counter1 = 0
    var counter2 = 0

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var messageTextfield: UITextField!{
        didSet{
            messageTextfield.delegate = self
        }
    }
    
    @IBOutlet weak var spinnerIndecator: UIActivityIndicatorView!
    @IBAction func pickPhotoPressed(_ sender: UIButton) {
        selectPhoto()
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
        self.trackedChildChanged = true
        print("hey will appear")
        if Auth.auth().currentUser?.uid == nil{
            messages = []
            messagesIds = []
            tableView.reloadData()
        }
        
        configureTableView()
        DataHandler.shared.fetchUserInfo { [weak self] user in
            self?.accountType = AccountType(rawValue: user.accountType)
            self?.parentID = user.parentID
            self?.userName = user.name
            self?.beginBatchFetch(completion: {
            self?.trackedChildChanged = false
                print("fetch Done ")
            })

            print("messages count \(String(describing: self?.messages.count))")
        }
        if let  trackedChildUId = TrackingViewController.trackedChildUId{
            self.uniqueID = trackedChildUId
            navigationItem.title = childName
        }
        
        
        if let  trackedChildUId = TrackingViewController.trackedChildUId{
            uniqueID = trackedChildUId
            DataHandler.shared.fetchChildAccount(with: uniqueID!) {[weak self] user in
                self?.navigationItem.title = user.name
                self?.tabBarItem.title = user.name + " Chat"
            }
        }
        resetBadgeCount()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(true)
        trackedChildChanged = false
        self.tabBarItem.title = "Chat"
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
        self.handleSendingMessage()
    }
    
    func downloadMessages(completion : @escaping (_  : [Message] , _  : [String])->()){
        let firstMessage = messages.first
        let firstMessageId = messagesIds.first
        var queryRef : DatabaseQuery
        messageReference = configureMessageReference(childID: uniqueID, parentId: parentID)
        if firstMessage != nil {
            print("last message not nil")
            let firstTimestamp = firstMessage?.timestamp
            
            queryRef = messageReference.queryOrdered(byChild: "timestamp").queryEnding(atValue: firstTimestamp ).queryLimited(toLast: 20)
        }
        else {
            print("last message is nil")
            queryRef = messageReference.queryOrderedByValue().queryLimited(toLast: 20)
        }
    queryRef.observe(.value) { (snapshot) in
                    var fetchedMessages = [Message]()
                    var fetchedMessagesIds = [String]()
                    let index = fetchedMessages.count
                    for child in snapshot.children {
                        if let childSnapshot = child as? DataSnapshot,
                            let messageInfo = childSnapshot.value as? [String:Any]
                             {
                            let messageId = childSnapshot.key
                            print("message ID \(messageId) ")
                            if messageId != firstMessageId {
                                print("Debug: not equal snapkey is \(messageId) and last post id is \(String(describing: firstMessageId)) and last massage is \(String(describing: firstMessage?.body))")
        
                                let message = Message( messageInfo)
                                print("fetched message is \(String(describing: message.body))")
                                 fetchedMessagesIds.insert(messageId, at: index )
                              fetchedMessages.insert(message, at: index)
                            }
                        }
                    }
                    print("Debug: first in fetched \(String(describing: fetchedMessages.first?.body)) and last in fetched \(String(describing: fetchedMessages.last?.body))" )
        
                    completion(fetchedMessages, fetchedMessagesIds)
        }
    }
    
    func handleSendingMessage(){
        sendPressed = true
        guard let messageText = messageTextfield.text,let sender = self.userName  else {return}
        if self.accountType == .parent{
            if let childID = self.uniqueID{
                self.messages = []
                self.messagesIds = []

                DataHandler.shared.uploadMessageWithInfo(messageText, childID, ImageURL: ImageURL) {[weak self] in

                    self?.beginBatchFetch {
                        self?.spinnerIndecator.stopAnimating()
                        self?.sendPressed = false
                        print("fetch Done")
                    }
                }
                DataHandler.shared.fetchDeviceID(for: childID) { deviceID in
                    print("Debug: device Id is \(deviceID)")
                DataHandler.shared.sendPushNotification(to: deviceID, sender: sender, body: messageText)
                }
            }
        }
        else if self.accountType == .child{
            if let parentID = self.parentID{
                self.messages = []
               self.messagesIds = []
                DataHandler.shared.uploadMessageWithInfo(messageText, parentID, ImageURL: ImageURL) {[weak self] in
                  self?.beginBatchFetch {
                self?.spinnerIndecator.stopAnimating()
                   self?.sendPressed = false
                   print("Debug: fetch Done")
                   }
                }
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
    
     func selectPhoto() {
        let alert = UIAlertController(title: "Select Image", message: "How Would You Like To Select The Image ", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Take By Camera", style: .default, handler: {
            [weak self](actionn) in
            self?.PresentCamera()
        }))
                        
        alert.addAction(UIAlertAction(title: "Select From Photo Library", style: .default, handler: { [weak self](action) in
            self?.PresentPhotoPicker()
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        self.present(alert, animated: true, completion: nil)
     }
    
    
    func uploadImageData(){
        self.spinnerIndecator.startAnimating()
        let storageReference = storage.reference()
        let UId = Auth.auth().currentUser?.uid
        let imageName = NSUUID().uuidString
        let imageReference  = storageReference.child("Messages/\(String(describing: UId))/\(imageName).jpg")
        if let imageData =  self.imageMessage?.jpegData(compressionQuality: 0.3){
            imageReference.putData(imageData, metadata: nil) { (metadata, error) in
                if error != nil {print(error!.localizedDescription)}
                imageReference.downloadURL { [weak self](url, error) in
                    if error != nil {print(error!.localizedDescription)}
                    if let downloadedURL = url{
                        self?.ImageURL = downloadedURL.absoluteString
                        print("Debug: url is \(String(describing: self?.ImageURL))")
                        self?.messageTextfield.text = ""
                        self?.handleSendingMessage()
                    }
                }
             }
          }
       }
}

extension ChatViewController : UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell  = tableView.dequeueReusableCell(withIdentifier: "ReusableCell", for: indexPath) as! MessageCell
        cell.backgroundColor = UIColor.clear
        let message = messages[indexPath.row]
        
        if let ImageURl = message.imageURL {
            if ImageURl.starts(with: "https") {
                cell.MessageImageView.isHidden = false
                    if cell.MessageImageView != nil {
                        let resizeConstraints = [
                            cell.MessageImageView.heightAnchor.constraint(equalToConstant:  300 ),
                            cell.MessageImageView.widthAnchor.constraint(equalToConstant:  200)
                        ]

                        cell.MessageImageView.addConstraints(resizeConstraints)
                                print("image reset")
                    }

                    print("Debug: label hidden true")
                
            }
            else {
                                cell.MessageImageView.isHidden = true
                                print("Debug: image hidden true")

            }
            cell.MessageImageView.loadImageUsingCacheWithUrlString(ImageURl)
        }
        cell.MessageBodyLabel.text = message.body
        cell.timeLabel.numberOfLines = 0
        cell.timeLabel.text = message.timestamp?.convertDateFormatter()
        if message.sender == Auth.auth().currentUser?.uid {
            cell.MessageBodyView.backgroundColor = #colorLiteral(red: 0.721568644, green: 0.8862745166, blue: 0.5921568871, alpha: 1)
            cell.MessageBodyView.leftAnchor.constraint(equalTo: cell.MessageBodyView.superview!.leftAnchor , constant: 50).isActive = true
        }
        else{
            cell.MessageBodyView.backgroundColor = #colorLiteral(red: 0.4745098054, green: 0.8392156959, blue: 0.9764705896, alpha: 1)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete{
            let messageId = messagesIds[indexPath.row]
            let selectedReference =  self.messageReference.child(messageId)
            
            messages.remove(at: indexPath.row)
            messagesIds.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            selectedReference.removeValue { [weak self] error, reference in
                if error != nil{
                    print(error?.localizedDescription as Any)
                }
//                self?.beginBatchFetch {
//                    print("Debug: removed  massage successfully")
//                }
            }
        }
    }
    
    

//    var cellHeights: [IndexPath : CGFloat] = [:]

//    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
//        cellHeights[indexPath] = cell.frame.size.height
//    }
//
//    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
//        return cellHeights[indexPath] ?? 70.0
//    }

    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
         let contentOffSetY = scrollView.contentOffset.y
         let contentHeight = scrollView.contentSize.height
         let tableHeight = tableView.contentSize.height
         let scrollHeight =  scrollView.frame.size.height
         if  tableHeight + contentOffSetY - scrollHeight <=  contentHeight - 200   {
             if counter1 > 1 {
                 self.tableView.tableHeaderView = createSpinnerHeader()
             }
             if !fetchingMore && !endReached {
                 beginBatchFetch {
                     print("Debug: fetch Done")
                 }
             }
             else if endReached {
                 self.tableView.tableHeaderView  = nil
             }
         }
    }
    
                
    func beginBatchFetch(completion : @escaping () -> Void ) {
        fetchingMore = true
        self.counter2 += 1
        if trackedChildChanged == true{
            messages = []
            messagesIds = []
        }
        print("Debug: begun fetch triggered out \(self.counter2)")
        downloadMessages {[weak self] newMessages, newMessagesIds in
            self?.fetchingMore = false
            self?.endReached = newMessages.count == 0
                for messageId in  newMessagesIds{
                    self!.messagesIds.insert(messageId, at: 0)
                }
                for message in  newMessages{
                    self!.messages.insert(message, at: 0)
                }
            UIView.performWithoutAnimation {
                if self?.trackedChildChanged == true{
                    self?.tableView.reloadData()
                }
               else if self?.trackedChildChanged == false {
                   self?.tableView.reloadDataAndKeepOffset()
                              }
                if ((self?.messages.count)! > 1 && self?.counter2 == 1) || ((self?.messages.count)! > 1 && self?.trackedChildChanged == true || ((self?.messages.count)! > 1 && self?.sendPressed == true )) {
                    self?.tableView.scrollToBottomRow()
                 }
            }
            completion()
        }
    }
    
    private func createSpinnerHeader() -> UIView{
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 100))
        let spinner = UIActivityIndicatorView()
        spinner.center = headerView.center
        headerView.addSubview(spinner)
        spinner.startAnimating()
        return headerView
    }
    
    }

        extension ChatViewController : UITextFieldDelegate{
        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        handleSendingMessage()
        return true
        }
    }

extension ChatViewController : UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    //func to take a photo by device camera
    func PresentCamera() {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.mediaTypes = [kUTTypeImage as String]
        picker.allowsEditing = true
        picker.delegate = self
        present(picker, animated: true)
    }
    
    func PresentPhotoPicker(){
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.mediaTypes = [kUTTypeImage as String]
        picker.allowsEditing = true
        picker.delegate = self
        present(picker, animated: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.presentingViewController?.dismiss(animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = ((info[UIImagePickerController.InfoKey.editedImage] ?? info[UIImagePickerController.InfoKey.originalImage]) as? UIImage){
            self.imageMessage = image
            uploadImageData()
        }
        picker.presentingViewController?.dismiss(animated: true)
    }
}

