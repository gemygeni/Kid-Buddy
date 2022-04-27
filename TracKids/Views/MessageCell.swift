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
    @IBOutlet weak var MessageImageView: UIImageView!
    @IBOutlet weak var timeLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        MessageImageView.translatesAutoresizingMaskIntoConstraints = false
        MessageImageView.layer.cornerRadius = MessageImageView.frame.size.height / 5
        MessageImageView.layer.masksToBounds = true
        MessageImageView.contentMode = .scaleAspectFill
        MessageBodyView.translatesAutoresizingMaskIntoConstraints = false
        MessageBodyView.layer.cornerRadius = MessageBodyView.frame.size.height / 5
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }
}
