//
//  ShoppingListTableViewCell.swift
//  ShoppingList
//
//  Created by Spandana Batchu on 2/13/18.
//  Copyright © 2018 MutualMobile. All rights reserved.
//

import UIKit


class ShoppingListTableViewCell: UITableViewCell {
    
    @IBOutlet weak var statusImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    
    func configureCell(item: Item) {
        titleLabel.text = item.name?.capitalized
        let statusImage = item.purchased ? #imageLiteral(resourceName: "checkbox-active") : #imageLiteral(resourceName: "checkbox-inactive")
        let titleColor = item.purchased ? UIColor.red : UIColor.darkGray
        statusImageView.image = statusImage
        titleLabel.textColor = titleColor
    }
    
}
