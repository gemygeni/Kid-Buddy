//
//  AddChildViewController.swift
//  TracKids
//
//  Created by AHMED GAMAL  on 2/20/21.
//
import UIKit
import MobileCoreServices
import  Firebase

class AddChildViewController: UIViewController {
    
    @IBOutlet weak var ChildNameTextField: UITextField!{
        didSet{
            ChildNameTextField.delegate = self
        }
    }

    @IBOutlet weak var spinnner: UIActivityIndicatorView!
    
    @IBOutlet weak var ChildPhoneTextField: UITextField!{
        didSet{
            ChildPhoneTextField.delegate = self
        }
    }
    
    
    @IBOutlet weak var childMailTextField: UITextField!
    
    @IBOutlet weak var childPasswordTextField: UITextField!
    
    @IBOutlet weak var ChildImageView: UIImageView!
    //{
      //  didSet{
           
         //   ChildImageView.translatesAutoresizingMaskIntoConstraints = false
            
          // ChildImageView.layer.cornerRadius = ((ChildImageView.frame.height) + (ChildImageView.frame.width)) / 5.0
         
//            ChildImageView.layer.borderColor = UIColor.lightGray.cgColor
//            ChildImageView.layer.masksToBounds = true
//            ChildImageView.layer.cornerRadius = ChildImageView.frame.size.width/2
//
//            ChildImageView.contentMode = .scaleToFill
//            ChildImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(setChildPhoto(_:))))
//        }
//    }
    override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
        ChildImageView.layer.masksToBounds = true
        ChildImageView.layer.cornerRadius = ChildImageView.frame.size.width/2.5
    }
    
    private var ImageURL : String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
           childMailTextField.becomeFirstResponder()
           ChildImageView.layer.borderColor = UIColor.lightGray.cgColor
           ChildImageView.layer.masksToBounds = true
           ChildImageView.layer.cornerRadius = ChildImageView.frame.size.width / 2.5
           ChildImageView.contentMode = .scaleToFill
           ChildImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(setChildPhoto(_:))))
         }
    
    @objc func setChildPhoto(_ recognizer : UITapGestureRecognizer? =  nil ) {
        let alert = UIAlertController(title: "Set Profile Image", message: "How Would You Like To Select a Picture ", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Take By Camera", style: .default, handler: {
            [weak self](actionn) in
            self?.PresentCamera()
        }))
                        
        alert.addAction(UIAlertAction(title: "Select From Library", style: .default, handler: { [weak self](action) in
            self?.PresentPhotoPicker()
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        self.present(alert, animated: true, completion: nil)
     }
   
    @IBAction func AddChildPressed(_ sender: UIButton) {
        uploadData()
    }
    
    @IBAction func CancelPressed(_ sender: UIButton) {
        self.dismiss(animated: true) {
            print("Canceled adding")
        }
    }
    
    func uploadData(){
        spinnner?.startAnimating()
        guard let ChildName = ChildNameTextField.text, let ChildPhoneNumber = ChildPhoneTextField.text, let email = childMailTextField.text, let password = childPasswordTextField.text,
        !ChildName.isEmpty , !ChildPhoneNumber.isEmpty, !password.isEmpty ,!email.isEmpty,
        let UID = Auth.auth().currentUser?.uid
        else {
            spinnner?.stopAnimating()
            return}
        let storageReference = storage.reference()
        let childName = ChildNameTextField.text ?? ""
        let imageReference  = storageReference.child("ChildsPictures/\(UID)/\(childName).jpg")
        if let imageData =   ChildImageView.image!.jpegData(compressionQuality: 0.3){
            imageReference.putData(imageData, metadata: nil) { (metadata, error) in
                if error != nil {print(error!.localizedDescription)}
                imageReference.downloadURL { [weak self](url, error) in
                    if error != nil {print(error!.localizedDescription)}
                    if let downloadedURL = url{
                        self?.ImageURL = downloadedURL.absoluteString
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self?.createNewChild()
                        }
                    }
                }
             }
          }
       }
    
    
    func createNewChild(){
        guard let ChildName = ChildNameTextField.text, let ChildPhoneNumber = ChildPhoneTextField.text, let email = childMailTextField.text, let password = childPasswordTextField.text,
        !ChildName.isEmpty , !ChildPhoneNumber.isEmpty, let UID = Auth.auth().currentUser?.uid
        else {return}
        let deviceID = ""
        Auth.auth().createUser(withEmail: email, password: password) {[weak self] (result, error) in
            if let error = error {
                let alert = UIAlertController(title: "Adding faild", message: error.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self?.present(alert, animated: true, completion: nil)
                self?.spinnner.stopAnimating()
                self?.childMailTextField.text = nil
                self?.childPasswordTextField.text = nil
                   }
            guard let childId = result?.user.uid else {return}
            let childInfo = ["name" : ChildName,
                             "email" : email,
                             "phoneNumber" : ChildPhoneNumber,
                             "password" : password,
                             "userType" : 1,
                             "parentID" : UID ,
                             "imageURL" : self?.ImageURL ?? "",
                             "deviceID" : deviceID] as [String : Any]
            
            UserReference.child(childId).updateChildValues(childInfo) { (error, reference) in
                if let error = error{print(error.localizedDescription)}
               TrackedChildsReference.child(UID).child(childId).updateChildValues(childInfo){_,_ in
                    if !ChildName.isEmpty && !ChildPhoneNumber.isEmpty {
                        self?.navigationController?.popViewController(animated: true)
                        self?.presentingViewController?.dismiss(animated: true, completion: {
                            self?.spinnner?.stopAnimating()
                       })
                    }
                }
            }
        }
   }
}


extension AddChildViewController : UIImagePickerControllerDelegate, UINavigationControllerDelegate{
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
            self.ChildImageView.image = image
        }
        picker.presentingViewController?.dismiss(animated: true)
    }
}
extension AddChildViewController : UITextFieldDelegate{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        uploadData()
        textField.resignFirstResponder()
        return true
    }
    
}


