//
//  TodoItemTableViewCell.swift
//  SwiftTodo
//
//  Created by Ben Lei on 29/3/15.
//  Copyright (c) 2015 Ben-181231. All rights reserved.
//

import UIKit

class TodoItemTableViewCell: UITableViewCell {

    @IBOutlet weak var doneLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
