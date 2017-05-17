//
//  ServerViewController.swift
//  Chronos
//
//  Created by David Wallach on 5/16/17.
//  Copyright © 2017 David Wallach. All rights reserved.
//

import UIKit

class ServerViewController: UITableViewController {
    @IBOutlet weak var textField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.addDoneButtonOnKeyboard()
    
    }

    @IBAction func CancelButtonTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
        
    }
    
    @IBAction func SaveButtonTapper(_ sender: Any) {
        
        userPreferences.sharedInstance.current_port = textField.text!
        dismiss(animated: true, completion: nil)
    }
    
    func addDoneButtonOnKeyboard() {
        let doneToolbar: UIToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 320, height: 50))
        doneToolbar.barStyle       = UIBarStyle.default
        let flexSpace              = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
        let done: UIBarButtonItem  = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.done, target: self, action: #selector(ServerViewController.doneButtonAction))
        
        var items = [UIBarButtonItem]()
        items.append(flexSpace)
        items.append(done)
        
        doneToolbar.items = items
        doneToolbar.sizeToFit()
        
        self.textField.inputAccessoryView = doneToolbar
    }
    
    func doneButtonAction() {
        self.textField.resignFirstResponder()
    }

}
