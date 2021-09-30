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
    

    let childInfoReference = Database.database().reference().child("TrackedChilds")
    let storage = Storage.storage()

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
    
    @IBOutlet weak var ChildImageView: UIImageView!{
        didSet{
            ChildImageView.layer.cornerRadius = ChildImageView.frame.height/2.0
            ChildImageView.layer.borderWidth = 2.0
            ChildImageView.layer.borderColor = UIColor.lightGray.cgColor
            ChildImageView.layer.masksToBounds = true
            ChildImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(setChildPhoto(_:))))

        }
    }
    
    private var ImageURL : String?
    
  

    
    @objc func setChildPhoto(_ recognizer : UITapGestureRecognizer? =  nil  ) {
        print("tappingdone")
        let alert = UIAlertController(title: "Profile Image", message: "How Would You Like To Select a Picture ", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Take By Camera", style: .default, handler: { (actionn) in
            self.PresentCamera()
        }))
                        
        
        alert.addAction(UIAlertAction(title: "Select From Library", style: .default, handler: { (action) in
            self.PresentPhotoPicker()
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        self.present(alert, animated: true, completion: nil)
     }


    
   
    @IBAction func AddChildPressed(_ sender: UIButton) {
        self.UploadData()
    }
    
    
    @IBAction func CancelPressed(_ sender: UIButton) {
        self.dismiss(animated: true) {
            print("Canceled adding")
        }
    }
    
    func UploadData(){
        spinnner?.startAnimating()
        let storageReference = storage.reference()
        let UID = Auth.auth().currentUser?.uid
        let childName = ChildNameTextField.text ?? ""
      
        let imageReference  = storageReference.child("ChildsPictures/\(UID!)/\(childName).jpg")
        if let imageData =   ChildImageView.image!.jpegData(compressionQuality: 0.3){
            imageReference.putData(imageData, metadata: nil) { (metadata, error) in
                if error != nil {print(error!.localizedDescription)}
                imageReference.downloadURL { (url, error) in
                    if error != nil {print(error!.localizedDescription)}
                    if let downloadedURL = url{
                        self.ImageURL = downloadedURL.absoluteString
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self.AddNewChild()
                            
                        }
                    }
                }
            }
          }
    }
    
    
    func AddNewChild(){
                guard let ChildName = ChildNameTextField.text, let ChildPhoneNumber = ChildPhoneTextField.text,
              !ChildName.isEmpty , !ChildPhoneNumber.isEmpty, let UID = Auth.auth().currentUser?.uid
        else {return}
        let childInfo : [String : Any] = ["ChildName" : ChildName,"ChildPhoneNumber" : ChildPhoneNumber, "ImageURL" : ImageURL ?? ""]
        childInfoReference.child(UID).childByAutoId().updateChildValues(childInfo){_,_ in
            if !ChildName.isEmpty && !ChildPhoneNumber.isEmpty {
                self.navigationController?.popViewController(animated: true)
                self.presentingViewController?.dismiss(animated: true, completion: {
                self.spinnner?.stopAnimating()
               })
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
        textField.resignFirstResponder()
        return true
    }
    
}


