//
//  MessageCell.swift
//  TracKids
//
//  Created by AHMED GAMAL  on 9/7/21.
//

import UIKit

class MessageCell: UITableViewCell {
    
    @IBOutlet weak var MessageBodyView: UIView!
    @IBOutlet weak var MessageBodyLabel: UILabel!
    
    @IBOutlet weak var rightImageView: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
        MessageBodyView.translatesAutoresizingMaskIntoConstraints = false
        rightImageView.translatesAutoresizingMaskIntoConstraints = false
        rightImageView.layer.masksToBounds = true
        rightImageView.layer.cornerRadius = 24
        rightImageView.contentMode = .scaleAspectFill
       //MessageBodyLabel.translatesAutoresizingMaskIntoConstraints = false

        MessageBodyView.layer.cornerRadius = MessageBodyView.frame.size.height / 5
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
