//
//  AddChildViewController.swift
//  TracKids
//
//  Created by AHMED GAMAL  on 2/20/21.
//
import UIKit

class AddChildViewController: UIViewController {

   
    @IBOutlet weak var ChildNameTextField: UITextField!
    
    @IBOutlet weak var ChildPhoneTextField: UITextField!
    @IBAction func AddImagePressed(_ sender: UIButton) {
    }
    
    
    func AddNewChild(){
        if let name = ChildNameTextField.text, let phoneNumber = ChildPhoneTextField.text{
            var newChild = Child(name: name, phoneNumber: phoneNumber)
        }
   }
    
    @IBAction func AddChildPressed(_ sender: UIButton) {
        AddNewChild()
    }
    
    
    @IBAction func CancelPressed(_ sender: UIButton) {
        self.dismiss(animated: true) {
            print("canceled adding")
        }
        
        
        
    }
    
    
    
    
    
    
    
    
    
    
    
    
}
