//
//  ViewController.swift
//  ShoppingList
//
//  Created by Spandana Batchu on 2/9/18.
//  Copyright © 2018 MutualMobile. All rights reserved.
//

import UIKit

class ShoppingListDataProvider: NSObject {
    var items: [Item]?
    
    func listOfItems() -> [Item]? {
            items =  DatabaseManager.sharedDBManager.shoppingCart()
            return items
    }
}


class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    let dataProvider = ShoppingListDataProvider()
    @IBOutlet weak var messageView: UIView!
    
    var items: [Item]? = [Item]() {
        didSet {
            reloadTable()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        registerForNotifications()
        fetchItems()
    }
    
    fileprivate func fetchItems() {
        self.items = dataProvider.listOfItems()
    }
    
   // MARK: - Tableview Conformance
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "ShoppingListTableViewCell", for: indexPath) as? ShoppingListTableViewCell {
            if let _item = items?[indexPath.row] {
              cell.configureCell(item: _item)
            }
            return cell
        }
        
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if let _item = items?[indexPath.row] {
            if let _itemName = _item.name {
                askConfirmation(itemName: _itemName)
            }
        }
    }
    
    fileprivate func reloadTable() {
        tableView.reloadData()
        guard let count = items?.count else {
            showEmptyState()
            return
        }
        if count > 0 {
            hideEmptyState()
        } else {
            showEmptyState()
        }
    }
    
    fileprivate func hideEmptyState() {
        tableView.isHidden = false
        messageView.isHidden = true
    }
    
    fileprivate func showEmptyState() {
        tableView.isHidden = true
        messageView.isHidden = false
    }
    
    //MARK: - Action Methods
    
    func askConfirmation(itemName: String) {
        let alert = UIAlertController(title: "Hey there!", message: "What would you like to mark this \(itemName) as done?", preferredStyle: UIAlertControllerStyle.alert)
        let cancelAction = UIAlertAction(title: "NO", style: .cancel, handler: nil)
        let okAction = UIAlertAction(title: "YES!", style: .default) { (_) in
            DatabaseManager.sharedDBManager.purchaseItem(itemName: itemName)
            self.fetchItems()
        }
        alert.addAction(okAction)
        alert.addAction(cancelAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func addItemClicked(_ sender: Any) {
        let alert = UIAlertController(title: "Hey there!", message: "What would you like to add to your shopping cart?", preferredStyle: UIAlertControllerStyle.alert)
        alert.addTextField(configurationHandler: configurationTextField)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler:{ (UIAlertAction)in
             let itemField = alert.textFields![0] as UITextField
            if let texInput = itemField.text {
                if texInput.count > 0 {
                    self.addItem(text: texInput)
                }
            }
        }))
        
        self.present(alert, animated: true, completion: {
            print("completion block")
        })
    }
    
    func configurationTextField(textField: UITextField!){
        textField.placeholder = "Apples"
    }
    
    private func addItem(text: String) {
        let item = Item(name: text.lowercased(), purchased: false)
        DatabaseManager.sharedDBManager.add(item)
        fetchItems()
    }
    
    // MARK: - Private
    private func registerForNotifications() {
        unregiserForNotifications()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.handleForegroundNotification(_:)),
            name: Notification.Name.UIApplicationWillEnterForeground,
            object: nil
        )
    }
    
    private func unregiserForNotifications() {
        NotificationCenter.default.removeObserver(
            self,
            name: Notification.Name.UIApplicationWillEnterForeground,
            object: nil
        )
    }
    
    @objc private func handleForegroundNotification(_ note: Notification) {
        fetchItems()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        unregiserForNotifications()
    }

}

