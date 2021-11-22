//
//  ChildsCollectionViewCell.swift
//  TracKids
//
//  Created by AHMED GAMAL  on 10/7/21.
//

import UIKit

class ChildsCollectionViewCell: UICollectionViewCell {
    var profileImageView : UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = 24
        imageView.contentMode = .scaleAspectFill
        imageView.image = #imageLiteral(resourceName: "mazengar")
        return imageView
    }()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.layer.cornerRadius = 20
        addSubview(profileImageView)
        profileImageView.heightAnchor.constraint(equalToConstant: 80).isActive = true
        profileImageView.widthAnchor.constraint(equalToConstant: 80).isActive = true
        profileImageView.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        profileImageView.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
    }
    
}
