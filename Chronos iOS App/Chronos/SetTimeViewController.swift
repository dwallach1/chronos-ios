//
//  SetTimeViewController.swift
//  Chronos
//
//  Created by David Wallach on 5/16/17.
//  Copyright © 2017 David Wallach. All rights reserved.
//

import Foundation
import UIKit


class SetTimeViewController: UITableViewController {
    
    @IBOutlet weak var time_label: UILabel!
    @IBOutlet weak var datePicker: UIDatePicker!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        datePicker.datePickerMode = .time
        datePicker.locale = Locale(identifier: "da_DK")
        set_title()
    }
    
    func set_title() {
        switch userPreferences.sharedInstance.state {
        case "prefered_sleep_hrs":
            time_label.text = "Please Select your Prefered Number of Hours to Sleep"
            break
        case "max_wakeup_time":
            time_label.text = "Please Select the Latest Time You Want to Wake Up"
            break
        case "prefered_preptime":
            time_label.text = "Please Select your Prefered Amount of Time to Prepare Before your First Event"
            break
        case "min_prep_time":
            time_label.text = "Please Select the Minimum Amount of Time You Need to Prepare Before your First Event"
            break
        default:
            return
        }
        
    }
    
    @IBAction func CancelTapper(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        
//        switch segue.identifier! {
//        case "prefered_sleep_hrs":
//            userPreferences.sharedInstance.state = "prefered_sleep_hrs"
//            break
//        case "max_wakeup_time":
//            userPreferences.sharedInstance.state = "max_wakeup_time"
//            break
//        case "prefered_preptime":
//            userPreferences.sharedInstance.state =  "prefered_preptime"
//            break
//        case "min_prep_time":
//            userPreferences.sharedInstance.state = "min_prep_time"
//            break
//        default:
//            return
//        }
//    }
    
    func time2string(time: Date) -> String {
        let dateformatter = DateFormatter()
        dateformatter.timeStyle = .short
        return dateformatter.string(from: time)
    }
    
    @IBAction func done_pressed(_ sender: Any) {
        let curr_state = userPreferences.sharedInstance.state
        if curr_state == "none" { dismiss(animated: true, completion: nil) }
        let time = datePicker.date
        
        switch curr_state {
        case "prefered_sleep_hrs":
            userPreferences.sharedInstance.prefered_sleep_hrs = time2string(time: time)
            break
        case "max_wakeup_time":
            userPreferences.sharedInstance.max_wakeup_time = time2string(time: time)
            break
        case "prefered_preptime":
            userPreferences.sharedInstance.prefered_preptime = time2string(time: time)
            break
        case "min_prep_time":
            userPreferences.sharedInstance.min_preptime = time2string(time: time)
            break
        default:
            dismiss(animated: true, completion: nil)
            
        }
        dismiss(animated: true, completion: nil)
    }
    
}
