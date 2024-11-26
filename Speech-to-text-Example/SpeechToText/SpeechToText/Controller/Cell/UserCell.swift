//
//  UserCell.swift
//
//  Created by Deepak Singh on 21/11/24.
//

import UIKit

class UserCell: UITableViewCell {

    @IBOutlet weak var labelMessage: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func populateCell(model: ChatModel) {
        labelMessage.text = model.message
    }
}
