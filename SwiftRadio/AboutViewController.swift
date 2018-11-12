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
    @IBOutlet weak var aboutLogo: UIImageView!
    
    //*****************************************************************
    // MARK: - ViewDidLoad
    //*****************************************************************
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let app = UIApplication.shared.delegate as! AppDelegate
        
        // Add gesture recognizer to dismiss view when touched
        let grClose = UITapGestureRecognizer(target: self, action: #selector(close))
        self.view.isUserInteractionEnabled = true
        self.view.addGestureRecognizer(grClose)
        
        // Add gesture recognizer to lin to web site when touched
        let grWebsite = UITapGestureRecognizer(target: self, action: #selector(website))
        self.aboutLogo.isUserInteractionEnabled = true
        self.aboutLogo.addGestureRecognizer(grWebsite)

        // Set version from bundle info
        versionLabel.text = "\(app.station.name) for iOS v\(Bundle.main.versionNumber ?? "") (\(Bundle.main.buildNumber ?? ""))"
    }
    
    //*****************************************************************
    // MARK: - IBActions
    //*****************************************************************

    @IBAction func close() {
        dismiss(animated: true, completion: nil)
    }
   
    @IBAction func website() {
        
        let app = UIApplication.shared.delegate as! AppDelegate
        
        // Use your own website here
        if let url = URL(string: app.station.websiteUrl) {
            UIApplication.shared.open(url,options: [:], completionHandler: nil)
        }
    }
        
    @IBAction func donateButtonDidTouch(_ sender: UIButton) {
        
        let app = UIApplication.shared.delegate as! AppDelegate

        // Use your own website here
        if let url = URL(string: app.station.donationUrl) {
            UIApplication.shared.open(url,options: [:], completionHandler: nil)
        }
    }
    
}
