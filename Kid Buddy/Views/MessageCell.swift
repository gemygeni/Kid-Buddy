//
//  MessageCell.swift
//  Kid Buddy
//
//  Created by AHMED GAMAL  on 9/7/21.
//

import UIKit

class MessageCell: UITableViewCell {
    @IBOutlet weak var messageImageView: UIImageView!
    @IBOutlet weak var messageBodyView: UIView!
    @IBOutlet weak var messageBodyLabel: UILabel!

    @IBOutlet weak var timeLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        messageImageView.translatesAutoresizingMaskIntoConstraints = false
        messageImageView.layer.cornerRadius = messageImageView.frame.size.height / 5
        messageImageView.layer.masksToBounds = true
        messageImageView.contentMode = .scaleAspectFill
        messageBodyView.translatesAutoresizingMaskIntoConstraints = false
        messageBodyView.layer.cornerRadius = messageBodyView.frame.size.height / 5
        messageBodyView.layer.masksToBounds = true
        messageBodyView.contentMode = .scaleAspectFill
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        messageImageView?.image = nil
        messageImageView?.removeConstraints(messageImageView.constraints)
    }
}
