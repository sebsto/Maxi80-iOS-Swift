//
//  PopUpMenuViewController.swift
//  Swift Radio
//
//  Created by Matthew Fecher on 7/9/15.
//  Copyright (c) 2015 MatthewFecher.com. All rights reserved.
//

import UIKit

class PopUpMenuViewController: UIViewController {

    @IBOutlet weak var popupView: UIView!
    @IBOutlet weak var backgroundView: UIImageView!
    @IBOutlet weak var versionLabel : UILabel!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        modalPresentationStyle = .custom
    }
    
    //*****************************************************************
    // MARK: - ViewDidLoad
    //*****************************************************************
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Round corners
        popupView.layer.cornerRadius = 10
        
        // Set background color to clear
        view.backgroundColor = UIColor.clear
        
        // Add gesture recognizer to dismiss view when touched
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(PopUpMenuViewController.closeButtonPressed))
        backgroundView.isUserInteractionEnabled = true
        backgroundView.addGestureRecognizer(gestureRecognizer)
        
        // Set version from bundle info
        versionLabel.text = "Maxi 80 for iOS v\(Bundle.main.versionNumber ?? "") (\(Bundle.main.buildNumber ?? ""))"
    }
    
    //*****************************************************************
    // MARK: - IBActions
    //*****************************************************************

    @IBAction func closeButtonPressed() {
        print("Close button pressed")
        dismiss(animated: true, completion: nil)
    }
   
    @IBAction func websiteButtonDidTouch(_ sender: UIButton) {
        
        // Use your own website here
        if let url = URL(string: "https://www.maxi80.com") {
            UIApplication.shared.open(url,options: [:], completionHandler: nil)
        }
    }
        
    @IBAction func lastFMButtonDidTouch(_ sender: UIButton) {
        
        // Use your own website here
        if let url = URL(string: "https://www.last.fm") {
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
