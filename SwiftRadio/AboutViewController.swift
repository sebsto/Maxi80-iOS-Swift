//
//  AboutViewController.swift
//  Maxi80  Radio
//
//  Created bySebastien Stormacq
//  Copyright (c) 2018 stormacq.com All rights reserved.
//

import UIKit

class AboutViewController: UIViewController {

    @IBOutlet weak var versionLabel: UILabel!
    
    //*****************************************************************
    // MARK: - ViewDidLoad
    //*****************************************************************
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let app = UIApplication.shared.delegate as! AppDelegate
        
        // Add gesture recognizer to dismiss view when touched
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(close))
        self.view.isUserInteractionEnabled = true
        self.view.addGestureRecognizer(gestureRecognizer)
        
        // Set version from bundle info
        versionLabel.text = "\(app.station.name) for iOS v\(Bundle.main.versionNumber ?? "") (\(Bundle.main.buildNumber ?? ""))"
    }
    
    //*****************************************************************
    // MARK: - IBActions
    //*****************************************************************

    @IBAction func close() {
        dismiss(animated: true, completion: nil)
    }
   
    @IBAction func websiteButtonDidTouch(_ sender: UIButton) {
        
//        let app = UIApplication.shared.delegate as! AppDelegate
        
        // TODO : must use URL returned by web service
        
        // Use your own website here
        if let url = URL(string: "https://www.maxi80.com") {
            UIApplication.shared.open(url,options: [:], completionHandler: nil)
        }
    }
        
    @IBAction func donateButtonDidTouch(_ sender: UIButton) {
        
        // Use your own website here
        if let url = URL(string: "https://www.maxi80.com/paypal.htm") {
            UIApplication.shared.open(url,options: [:], completionHandler: nil)
        }
    }
    
}
