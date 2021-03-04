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
    
    @IBAction func AddChildPressed(_ sender: UIButton) {
    }
    
    
    @IBAction func CancelPressed(_ sender: UIButton) {
        self.dismiss(animated: true) {
            print("canceled adding")
        }
    }
    
    
    
    
    
    
    
    
    
    
    
    
}
