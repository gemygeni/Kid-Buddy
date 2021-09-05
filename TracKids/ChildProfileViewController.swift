//
//  ChildProfileViewController.swift
//  TracKids
//
//  Created by AHMED GAMAL  on 8/30/21.
//

import UIKit

class ChildProfileViewController: UIViewController {
    
    
    @IBOutlet weak var profileImageView: UIImageView!
    
    @IBOutlet weak var childNameLabel: UILabel!
    
    
    weak var fetchedImage : UIImage?
     var name : String?
    var phone :String?
    
    var ProfileImage : UIImage? {
        get{
            return profileImageView.image
        }
        set {
            profileImageView.image = newValue
            profileImageView.translatesAutoresizingMaskIntoConstraints = false
            profileImageView.layer.masksToBounds = true
            profileImageView.layer.cornerRadius = 130
            profileImageView.contentMode = .scaleAspectFill
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ProfileImage = fetchedImage
        childNameLabel?.text = (name ?? "name")+"\n"+(phone ?? "phone")
    }
    
//
//    func setStringFontAttributes(for string : String, with fontSize : CGFloat) -> NSAttributedString{
//        var font = UIFont.preferredFont(forTextStyle: .subheadline).withSize(fontSize)
//        font = UIFontMetrics(forTextStyle: .subheadline).scaledFont(for: font)
//
//        return NSAttributedString(string: string, attributes: [.font : font])
//    }
//
//

}
