    //
    //  updateCildProfileViewController.swift
    //  TracKids
    //
    //  Created by AHMED GAMAL  on 30/01/2022.
    //

    import UIKit
    import MobileCoreServices
    import Firebase
    protocol ChangedInfoDelegate : AnyObject  {
        func didChangedInfo(_ sender : EditChildProfileViewController ,newImage : UIImage, newName: String)
    }

 
    class EditChildProfileViewController: UIViewController {
        weak var fetchedImage : UIImage?
        weak var delegate : ChangedInfoDelegate?

        var childName : String = "child"
        var childId : String?
        var ProfileImage : UIImage? {
            get{
                return profileImageView.image ?? #imageLiteral(resourceName: "person") 
            }
            set {
                profileImageView.image = newValue ?? #imageLiteral(resourceName: "person")
                profileImageView.translatesAutoresizingMaskIntoConstraints = false
                profileImageView.layer.cornerRadius = profileImageView.frame.size.width/2.5
                profileImageView.layer.masksToBounds = true
                profileImageView.contentMode = .scaleAspectFill
            }
        }
        @IBOutlet weak var spinnner: UIActivityIndicatorView!
        @IBOutlet weak var nameTextField: UITextField!{
            didSet{
                nameTextField.delegate = self
            }
        }
        
        @IBOutlet weak var profileImageView: UIImageView!
        override func viewDidLoad() {
            super.viewDidLoad()
            ProfileImage = fetchedImage
            profileImageView.layer.borderColor = UIColor.lightGray.cgColor
            profileImageView.layer.masksToBounds = true
            profileImageView.layer.cornerRadius = profileImageView.frame.size.width / 2.5
            profileImageView.contentMode = .scaleToFill
            profileImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(setChildPhoto(_:))))
            nameTextField.text = childName
            
        }
        
        
        @objc func setChildPhoto(_ recognizer : UITapGestureRecognizer? =  nil ) {
            print("tappp")
            let alert = UIAlertController(title: "edit Profile Image", message: "How Would You Like To Select a Picture ", preferredStyle: .actionSheet)
            
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
        
        
        override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()
            profileImageView.layer.masksToBounds = true
            profileImageView.layer.cornerRadius = profileImageView.frame.size.width/2.5
        }
        
        
        @IBOutlet weak var saveButton: UIButton!
        
        @IBAction func saveButtonPressed(_ sender: UIButton) {
            updateInfo()
        }
        
        @IBAction func cancelButtonPressed(_ sender: UIButton) {
            self.dismiss(animated: true) {
                print("here outside cancel")
            }
        }
        
        func updateInfo(){
            spinnner?.startAnimating()
            guard let childId = childId,
           let newImage = ProfileImage,
           nameTextField.text != nil , let newName = nameTextField.text else {return}
            print("here before")
            DataHandler.shared.updateChildInfo(forId: childId, withImage: newImage, name: newName) {[weak self] in
                self?.navigationController?.popViewController(animated: true)
                self?.presentingViewController?.dismiss(animated: true, completion: {
                     print("here after")
                    self?.spinnner?.stopAnimating()
                    self?.delegate?.didChangedInfo(self!, newImage: newImage, newName: newName)
                 })
            }
        }
    }


    extension EditChildProfileViewController : UIImagePickerControllerDelegate, UINavigationControllerDelegate{
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
                self.profileImageView.image = image
            }
            picker.presentingViewController?.dismiss(animated: true)
        }
    }

    extension EditChildProfileViewController : UITextFieldDelegate{
        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            updateInfo()
            return true
        }
    }
