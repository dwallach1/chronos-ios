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
        
    }

    @IBAction func CancelButtonTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
        
    }
    
    @IBAction func SaveButtonTapper(_ sender: Any) {
        
        userPreferences.sharedInstance.current_port = textField.text!
        dismiss(animated: true, completion: nil)
    }

}
