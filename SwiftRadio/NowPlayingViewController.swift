//
//  NowPlayingViewController.swift
//  Swift Radio
//
//  Created by Matthew Fecher on 7/22/15.
//  Copyright (c) 2015 MatthewFecher.com. All rights reserved.
//

import UIKit
import MediaPlayer // for volume control
import MessageUI
import AWSAppSync

//*****************************************************************
// NowPlayingViewController
//*****************************************************************

class NowPlayingViewController: UIViewController {

    @IBOutlet weak var coverImageView: UIImageView!
    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet weak var songLabel: UILabel!
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var slider: UISlider!
    
    // the hidden MPVolumeView's slider - we are going to link it to volumeSlider in viewDidLoad()
    private var mpVolumeSlider : UISlider!
    private let SYSTEM_VOLUME_NOTIFICATION = NSNotification.Name("AVSystemController_SystemVolumeDidChangeNotification")
    private let LOG = Logger.createOSLog(module: "NowPlayingViewController")

    // the media player
    private let player = StreamingService()
    
    // counter for ArtWork load retry
    private var retry = 0;
    
    // fade in / out animation time
    private let ANIMATION_TIME = 0.2
        
    //*****************************************************************
    // MARK: - GUI initialisation
    //*****************************************************************
    
    // make the status bar black
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent // .default
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let app = UIApplication.shared.delegate as! AppDelegate

        // add ourselves as observer to be notified when radio station is loaded
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(onDidReceiveRadioStationData),
                                               name: app.radioStationDataNotificationName,
                                               object: nil)
        
        // add ourselves as observer to be notified when stream meta data is changing
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(onDidReceiveMetaData),
                                               name: app.metaDataNotificationName,
                                               object: nil)

        // Setup slider
        prepareVolumeSlider()
        
        // set temporary radio name on labels
        self.updateLabels(artist: app.currentArtist, track: app.currentTrack)

        // play is triggered later, after we will receives the radio station details
        
    }
    
    deinit {
        // Be a good citizen and de-register ourself from Notification Center
        let app = UIApplication.shared.delegate as! AppDelegate

        NotificationCenter.default.removeObserver(self,
                                                  name: app.radioStationDataNotificationName,
                                                object: nil)
        
        NotificationCenter.default.removeObserver(self,
                                                  name: app.metaDataNotificationName,
                                                  object: nil)

        NotificationCenter.default.removeObserver(self,
            name: SYSTEM_VOLUME_NOTIFICATION,
            object: AVAudioSession.sharedInstance())
    }
    
    //*****************************************************************
    // MARK: - Player Controls (Play/Pause)
    //*****************************************************************
    
    func start() {
        player.start()
        
        // change image
        playPauseButton.setImage(UIImage(named: "btn-pause")!, for: .normal)
    }
    
    func stop() {
        let app = UIApplication.shared.delegate as! AppDelegate
        
        player.stop()

        // force a refresh of the cover art and track & artist name
        app.setTrack(artist: nil, track: nil)

        // change button image
        playPauseButton.setImage(UIImage(named: "btn-play")!, for: .normal)

    }
    
    @IBAction func pausePlayPressed() {

        let app = UIApplication.shared.delegate as! AppDelegate

        if (app.isPlaying) {
            self.stop()
        } else {
            self.start()
        }
    }

    //*****************************************************************
    // MARK: - Volume Slider management
    //*****************************************************************
    

    func prepareVolumeSlider() {
        // The volume slider only works in devices, not the simulator.
        // http://blog.wizages.com/Swift-Volume-Controls/
        // Note: This slider implementation uses a hidden MPVolumeView
        
        let volumeView = MPVolumeView(frame: slider.superview!.bounds)
        volumeView.isHidden = true
        for view in volumeView.subviews {
            if let slider = view as? UISlider {
                mpVolumeSlider = slider
            }
        }
        
        // be notified of system volume changes to give us a possibility to adjust our slider
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(systemVolumeDidChange),
                                               name: SYSTEM_VOLUME_NOTIFICATION ,
                                               object: nil)
    }

    @IBAction func volumeSliderChanged(_ sender:UISlider) {
        if let vs = self.mpVolumeSlider {
            vs.value = sender.value
        }
    }
    
    @objc func systemVolumeDidChange(notification: NSNotification) {
        let volume = notification.userInfo!["AVSystemController_AudioVolumeNotificationParameter"] as! Float
        slider.value = volume
    }
    
    //*****************************************************************
    // MARK: - Label management
    //*****************************************************************
    
    @objc func onDidReceiveRadioStationData(_ notification:Notification) {
        
        // do not use the notification object has it might be nil
        
        let app = UIApplication.shared.delegate as! AppDelegate
        
        // update UI on main thread
        DispatchQueue.main.async {
            
            // update labels and cover with Station Name
            self.updateLabels(artist: app.station.name, track: app.station.desc)
            self.updateAlbumArtwork()

            // play
            self.start()
        }
    }

    
    @objc func onDidReceiveMetaData(_ notification:Notification) {
        let app = UIApplication.shared.delegate as! AppDelegate
        
        DispatchQueue.main.async {
            self.updateLabels(artist: app.currentArtist, track: app.currentTrack)
            self.updateAlbumArtwork()
        }
    }
    
    func updateLabels(artist: String, track: String) {
        
        // fade out
        let animator = UIViewPropertyAnimator(duration: self.ANIMATION_TIME, curve: .easeOut, animations: {
            self.songLabel.alpha = 0.0
            self.artistLabel.alpha = 0.0
        })
            
        animator.addCompletion { _ in
                
                // change text
                self.songLabel.text = track
                self.artistLabel.text = artist
                
                // fade in again
                UIViewPropertyAnimator(duration: self.ANIMATION_TIME, curve: .easeOut, animations: {
                    self.songLabel.alpha = 1.0
                    self.artistLabel.alpha = 1.0
                }).startAnimation()

            }
        
        animator.startAnimation()

    }
    
    //*****************************************************************
    // MARK: - Album Art
    //*****************************************************************
    
    // update the image on the screen
    func loadAlbumImage(url : URL) {
        
        // schedule loading of the URL
        DispatchQueue.global().async {
                
            // rely on Data to load the URL
            if let data = try? Data(contentsOf: url) {
                
                // if it returns something
                if let image = UIImage(data: data) {
                    
                    // update the GUI
                    self.updateAlbumImage(image: image)
                }
            }
        }
    }
    
    // update the image on the screen 
    func updateAlbumImage(image : UIImage) {
        
        // update GUI on main thread
        DispatchQueue.main.async {
            
            // Turn off network activity indicator
            UIApplication.shared.isNetworkActivityIndicatorVisible = false

            // Update cover image struct with animation
            
            // fade out
            let animator = UIViewPropertyAnimator(duration: self.ANIMATION_TIME, curve: .easeOut, animations: {
                self.coverImageView.alpha = 0.0
            })
            
            animator.addCompletion { _ in
                // change image
                self.coverImageView.image = image
                
                // fade in again
                UIViewPropertyAnimator(duration: self.ANIMATION_TIME, curve: .easeOut, animations: {
                    self.coverImageView.alpha = 1.0
                }).startAnimation()
            }
            
            animator.startAnimation()

            
            // Update lockscreen
            self.updateLockScreen()
        }

    }

    // load the artwork from our backend API
    func updateAlbumArtwork() {

        // Turn on network activity indicator (will be turned off after downloading the image)
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
        }
        

        // get our AppSync client
        let app = UIApplication.shared.delegate as! AppDelegate
        let appSyncClient = app.appSyncClient
        
        os_log_debug(LOG, "Going to call backend artwork for \(app.currentArtist) and \(app.currentTrack)")
        appSyncClient?.fetch(query: ArtworkQuery(artist:app.currentArtist, track:app.currentTrack),
                             cachePolicy: .fetchIgnoringCacheData)  {
                                (result, error) in
                                
                if error != nil {
                
                let e = error! as! AWSAppSyncClientError
                let response = e.response
                os_log_error(self.LOG, "Error call ArtWork API \(response!)")
                                
            } else {
                
                self.retry = 0;
                guard let artwork = result?.data?.artwork else {
                    os_log_error(self.LOG, "artwork is nil")
                    return
                }
                os_log_debug(self.LOG, "Artwork is \(artwork)")
                
                // load the image from the URL we received
                if let url = URL(string: artwork.url!) {
                    self.loadAlbumImage(url: url)
                }
            }
        }
    }

    //*****************************************************************
    // MARK: - Segue and Navigation
    //*****************************************************************
        
    @IBAction func shareButtonPressed(_ sender: UIButton) {
        let app = UIApplication.shared.delegate as! AppDelegate

        let songToShare = "I'm listening to \(app.currentTrack) by \(app.currentArtist) on \(app.station.name) via Maxi80 for iOS.  Check it out at https://www.maxi80.com"
        let activityViewController = UIActivityViewController(activityItems: [songToShare, coverImageView.image!], applicationActivities: nil)
        present(activityViewController, animated: true, completion: nil)
    }
    
    @IBAction func emailButtonDidTouch(_ sender: UIButton) {
        
        // Use your own email address & subject
        let receipients = ["seb@maxi80.com"]
        let subject = "From Maxi80 iOS"
        let messageBody = ""
        
        let configuredMailComposeViewController = configureMailComposeViewController(recepients: receipients, subject: subject, messageBody: messageBody)
        
        if canSendMail() {
            self.present(configuredMailComposeViewController, animated: true, completion: nil)
        } else {
            showSendMailErrorAlert()
        }
    }
    
    //*****************************************************************
    // MARK: - MPNowPlayingInfoCenter (Lock screen)
    //*****************************************************************
    
    func updateLockScreen() {
        let app = UIApplication.shared.delegate as! AppDelegate

        // Update notification/lock screen
        let image = coverImageView.image!
        let albumArtwork = MPMediaItemArtwork.init(boundsSize: image.size, requestHandler: { (size) -> UIImage in
            return image
        })
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [
            MPMediaItemPropertyArtist: app.currentArtist,
            MPMediaItemPropertyTitle: app.currentTrack,
            MPMediaItemPropertyArtwork: albumArtwork
        ]
    }
    
    override func remoteControlReceived(with receivedEvent: UIEvent?) {
        super.remoteControlReceived(with: receivedEvent)
        
        if receivedEvent!.type == UIEvent.EventType.remoteControl {
            
            switch receivedEvent!.subtype {
            case .remoteControlPlay:
                pausePlayPressed()
            case .remoteControlPause:
                pausePlayPressed()
            default:
                break
            }
        }
    }
    
}

//*****************************************************************
// MARK: - MFMailComposeViewController Delegate
//*****************************************************************

extension NowPlayingViewController: MFMailComposeViewControllerDelegate {
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    func canSendMail() -> Bool {
        return MFMailComposeViewController.canSendMail()
    }
    
    func configureMailComposeViewController(recepients: [String], subject: String, messageBody: String) -> MFMailComposeViewController {
        
        let mailComposerVC = MFMailComposeViewController()
        mailComposerVC.mailComposeDelegate = self
        
        mailComposerVC.setToRecipients(recepients)
        mailComposerVC.setSubject(subject)
        mailComposerVC.setMessageBody(messageBody, isHTML: false)
        
        return mailComposerVC
    }
    
    func showSendMailErrorAlert() {
        //let sendMailErrorAlert = UIAlertView(title: "Could Not Send Email", message: "Your device could not send e-mail.  Please check e-mail configuration and try again.", delegate: self, cancelButtonTitle: "OK")
        //sendMailErrorAlert.show()
        
        let alert = UIAlertController(title: "Could Not Send Email", message: "Your device can not send e-mail.  Please check e-mail configuration and try again.", preferredStyle:UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK", style: .`default`, handler: { _ in
            os_log_debug(self.LOG, "The \"OK\" alert occured.")
        }))
    }
}

