//
//  ChatViewController.swift
//  TracKids
//
//  Created by AHMED GAMAL  on 9/7/21.
//

import UIKit
import Firebase
import MobileCoreServices
import Photos
import UniformTypeIdentifiers
class ChatViewController: UIViewController, UIGestureRecognizerDelegate{
    var trackedChildObserver : NSObjectProtocol?
    var messages : [Message] = []
    var messagesIds : [String] = []
    let leadingScreensForBatching:CGFloat = 2.0
    var fetchingMore = false
    var endReached = false
    var rowHeights:[Int:CGFloat] = [:]
    var trackedChildChanged = false
    private var ImageURL : String?
    var childID : String?{
        didSet{
            self.uniqueID = childID
        }
    }
    var messageReference = DatabaseReference()
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
    var counter3 = 0
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var messageTextfield: UITextField!{
        didSet{
            messageTextfield.delegate = self
        }
    }
    
    @IBAction func saveImagePressed(_ sender: UIButton) {
        UIImageWriteToSavedPhotosAlbum(self.imageView.image!, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    @IBOutlet weak var spinnerIndecator: UIActivityIndicatorView!
    @IBAction func pickPhotoPressed(_ sender: UIButton) {
        selectPhoto()
    }
    
    @IBOutlet weak var saveButton: UIButton!
    
    @IBOutlet weak var backgroundView: UIView!{
        didSet{
            backgroundView.isHidden = true
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleZoomOut(_:)))
            backgroundView.addGestureRecognizer(tapGesture)
        }
    }
    
    @IBAction func sendMessagePressed(_ sender: UIButton) {
        self.handleSendingMessage()
    }
    
    var  imageView =  UIImageView(){
        didSet{
            imageView.sizeToFit()
            imageView.layer.masksToBounds = true
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        if messageTextfield.text?.isEmpty == true{
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        self.trackedChildChanged = true
        print("Debug: hey will appear")
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
            self?.beginBatchFetch(completionHandler: {
                
                self?.trackedChildChanged = false
                print("Debug: fetch Done1 ")
            })
            
            print("Debug: messages count \(String(describing: self?.messages.count))")
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
        imageView.enableZoom()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        layoutImageView()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(true)
        trackedChildChanged = false
        self.tabBarItem.title = "Chat"
    }
    
    // MARK: - function to configure table view.
    func configureTableView(){
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "MessageCell", bundle: nil), forCellReuseIdentifier: "ReusableCell")
        tableView.backgroundColor = #colorLiteral(red: 0.8761226535, green: 0.8871519566, blue: 0.886958003, alpha: 1)
        tableView.allowsMultipleSelectionDuringEditing = true
    }
    
    // MARK: - function to configure Message Reference on database based onn type of account.
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
    
    // MARK: - function to download Messages from database.
    func downloadMessages(completionHandler : @escaping (_  : [Message] , _  : [String])->()){
        let firstMessage = messages.first
        let firstMessageId = messagesIds.first
        var queryRef : DatabaseQuery
        messageReference = configureMessageReference(childID: uniqueID, parentId: parentID)
        if firstMessage != nil {
            print("Debug: last message not nil")
            let firstTimestamp = firstMessage?.timestamp
            //configure reference to fetch only first 20 messages sorted by timestamp
            queryRef = messageReference.queryOrdered(byChild: "timestamp").queryEnding(atValue: firstTimestamp ).queryLimited(toLast: 20)
        }
        else {
            print("Debug: last message is nil")
            queryRef = messageReference.queryOrderedByValue().queryLimited(toLast: 20)
        }
        queryRef.observe(.value) { [weak self] (snapshot) in
            if self?.fetchingMore == false {
                self?.messages = []
                self?.messagesIds = []
                print("Debug: erased message)")
            }
            var fetchedMessages = [Message]()
            var fetchedMessagesIds = [String]()
            let index = fetchedMessages.count
            for child in snapshot.children {
                if let childSnapshot = child as? DataSnapshot,
                   let messageInfo = childSnapshot.value as? [String:Any]
                {
                    let messageId = childSnapshot.key
                    if messageId != firstMessageId {
                        print("Debug: not equal snapkey is \(messageId) and last post id is \(String(describing: firstMessageId)) and last massage is \(String(describing: firstMessage?.body))")
                        //order messages to display last message in the last row of tableview
                        let message = Message( messageInfo)
                        fetchedMessagesIds.insert(messageId, at: index )
                        fetchedMessages.insert(message, at: index)
                    }
                }
            }
            print("Debug: first in fetched \(String(describing: fetchedMessages.first?.body)) and last in fetched \(String(describing: fetchedMessages.last?.body))" )
            completionHandler(fetchedMessages, fetchedMessagesIds)
        }
    }
    
    // MARK: - function to handle sending message to database.
    func handleSendingMessage(){
        sendPressed = true
        guard messageTextfield.text?.isEmpty == false, let messageText = messageTextfield.text, let sender = self.userName  else {return}
        if self.accountType == .parent{
            if let childID = self.uniqueID{
                DataHandler.shared.uploadMessageWithInfo(messageText, childID, ImageURL: self.ImageURL) {[weak self] in
                    self?.spinnerIndecator.stopAnimating()
                    self?.sendPressed = false
                    self?.ImageURL = nil
                }
                //fetch second party device ID and send notification with message info
                DataHandler.shared.fetchDeviceID(for: childID) { deviceID in
                    print("Debug: device Id is \(deviceID)")
                    DataHandler.shared.sendPushNotification(to: deviceID, sender: sender, body: messageText)
                }
            }
        }
        else if self.accountType == .child{
            if let parentID = self.parentID{
                DataHandler.shared.uploadMessageWithInfo(messageText, parentID, ImageURL: ImageURL) {[weak self] in
                    self?.spinnerIndecator.stopAnimating()
                    self?.sendPressed = false
                    self?.ImageURL = nil
                }
                
                DataHandler.shared.fetchDeviceID(for: parentID) { deviceID in
                    DataHandler.shared.sendPushNotification(to: deviceID, sender: sender, body: messageText)
                }
            }
        }
        messageTextfield.text = ""
        messageTextfield.resignFirstResponder()
    }
    
    
    // MARK: - function to paging messages.
    func beginBatchFetch(completionHandler : @escaping () -> Void ) {
        fetchingMore = true
        self.counter2 += 1
        if trackedChildChanged == true{
            messages = []
            messagesIds = []
        }
        downloadMessages {[weak self] newMessages, newMessagesIds in
            self?.fetchingMore = false
            self?.endReached = newMessages.count == 0
            for messageId in  newMessagesIds{
                self?.messagesIds.insert(messageId, at: 0)
            }
            for message in  newMessages{
                self?.messages.insert(message, at: 0)
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
                    print("Debug: scrolled To Bottom Row")
                }
            }
            completionHandler()
        }
    }
    
    // MARK: - function to create Spinner Header.
    private func createSpinnerHeader() -> UIView{
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 100))
        let spinner = UIActivityIndicatorView()
        spinner.center = headerView.center
        headerView.addSubview(spinner)
        spinner.startAnimating()
        return headerView
    }
    
    // MARK: - function to give options to user how to choose image.
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
    
    // MARK: - function to handle uploading choosed image to database.
    func uploadImageData(){
        self.spinnerIndecator.startAnimating()
        let storageReference = storage.reference()
        guard let uid = Auth.auth().currentUser?.uid else {return}
        let imageName = NSUUID().uuidString
        let imageReference  = storageReference.child("Messages/\(String(describing: uid))/\(imageName).jpg")
        if let imageData =  self.imageMessage?.jpegData(compressionQuality: 0.3){
            imageReference.putData(imageData, metadata: nil) { (metadata, error) in
    if error != nil {print("Debug: error \(String(describing: error!.localizedDescription))")}
                imageReference.downloadURL { [weak self](url, error) in
    if error != nil {print("Debug: error \(String(describing: error!.localizedDescription))")}
                    if let downloadedURL = url{
                        self?.ImageURL = downloadedURL.absoluteString
                        print("Debug: url is \(String(describing: self?.ImageURL))")
                        self?.messageTextfield.text = "."
                        self?.handleSendingMessage()
                    }
                }
            }
        }
    }
    
    // MARK: - function to handle saving image to photo library.
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            // we got back an error!
            let ac = UIAlertController(title: "Saving error", message: error.localizedDescription, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        } else {
            let ac = UIAlertController(title: "Saved!", message: "Your image has been saved to your photos.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        }
    }
    
    // MARK: - functions to handle image zooming.
    @objc func handleZoom(_ recognizer : UITapGestureRecognizer? =  nil ) {
        if let tappedImageView = recognizer?.view as? UIImageView {
            backgroundView.addSubview(imageView)
            self.imageView.image = tappedImageView.image
            layoutImageView()
            performZoomingIn()
            print("Debug: tapped")
        }
    }
    
    func performZoomingIn (){
        UIView.animate(withDuration: 0.7, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
            self.backgroundView.isHidden = false
        })
    }
    
    @objc func handleZoomOut(_ recognizer : UITapGestureRecognizer? =  nil ) {
        performZoomingOut()
    }
    
    func performZoomingOut (){
        UIView.animate(withDuration: 0.7, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: { [weak self] in
            self?.backgroundView.isHidden = true
            self?.imageView.removeFromSuperview()
        })
    }
    
    func layoutImageView(){
        backgroundView.addSubview(imageView)
        backgroundView.contentMode = .scaleAspectFit
        backgroundView.layer.masksToBounds = true
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.bringSubviewToFront(saveButton)
        imageView.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.leftAnchor.constraint(equalTo: backgroundView.leftAnchor, constant: 0).isActive = true
        imageView.rightAnchor.constraint(equalTo: backgroundView.rightAnchor, constant: 0).isActive = true
        imageView.topAnchor.constraint(equalTo: backgroundView.topAnchor, constant: 0).isActive = true
        imageView.bottomAnchor.constraint(equalTo: backgroundView.bottomAnchor, constant: 0).isActive = true
    }
    // MARK: - function to reset badge count of app to zero
    func resetBadgeCount() {
        UserDefaults.standard.setValue(0, forKey: "badgeCount")
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate Methods.
extension ChatViewController : UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell  = tableView.dequeueReusableCell(withIdentifier: "ReusableCell", for: indexPath) as! MessageCell
        
        cell.backgroundColor = UIColor.clear
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleZoom(_:)))
        cell.MessageImageView.addGestureRecognizer(tapGesture)
        
        let message = messages[indexPath.row]
        
        if let ImageURl = message.imageURL {
            counter3 += 1
            if ImageURl.starts(with: "https") {
                cell.MessageImageView?.isHidden = false
                if cell.MessageImageView != nil {
                    cell.MessageImageView?.loadImageUsingCacheWithUrlString(ImageURl)
                    let resizeConstraints = [
                        cell.MessageImageView.heightAnchor.constraint(equalToConstant:  300),
                        cell.MessageImageView.widthAnchor.constraint(equalToConstant:  200)
                    ]
                    cell.MessageImageView?.addConstraints(resizeConstraints)
                }
            }
            else {
                cell.MessageImageView?.isHidden = true
                tableView.rowHeight = UITableView.automaticDimension
                self.tableView.estimatedRowHeight = 50
                cell.layoutIfNeeded()
            }
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
            self.messagesIds.remove(at: indexPath.row)
            self.messages.remove(at: indexPath.row)
            self.tableView.deleteRows(at: [indexPath], with: .fade)
            self.messages = []
            self.messagesIds = []
            selectedReference.removeValue { [weak self] error, reference in
                if error != nil{
                    print("Debug: error \(String(describing: error!.localizedDescription))")
                }
                self?.tableView.reloadDataAndKeepOffset()
            }
        }
    }
}

// MARK: - UIScrollViewDelegate Methods.
extension ChatViewController :  UIScrollViewDelegate{
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        let contentOffSetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let tableHeight = tableView.contentSize.height
        let scrollHeight =  scrollView.frame.size.height
        if  tableHeight + contentOffSetY - scrollHeight <=  contentHeight - 260   {
            if counter1 > 1 {
                self.tableView.tableHeaderView = createSpinnerHeader()
            }
            if !fetchingMore && !endReached {
                beginBatchFetch {
                    print("Debug: fetch Done4")
                }
            }
            else if endReached {
                self.tableView.tableHeaderView  = nil
            }
        }
    }
}

// MARK: - UITextFieldDelegate Methods.
extension ChatViewController : UITextFieldDelegate{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        handleSendingMessage()
        return true
    }
}
// MARK: - UIImagePickerControllerDelegate and UINavigationControllerDelegate Methods.
extension ChatViewController : UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    //MARK: func gives option to take a photo by device camera.
    func PresentCamera() {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.mediaTypes = [UTType.image.identifier as String]
        picker.allowsEditing = true
        picker.delegate = self
        present(picker, animated: true)
    }
    
    //MARK: func gives option to pick a photo from photo library.
    func PresentPhotoPicker(){
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.mediaTypes = [UTType.image.identifier as String]
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

