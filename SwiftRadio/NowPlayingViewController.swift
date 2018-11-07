//
//  NowPlayingViewController.swift
//  Swift Radio
//
//  Created by Matthew Fecher on 7/22/15.
//  Copyright (c) 2015 MatthewFecher.com. All rights reserved.
//

import UIKit
import MediaPlayer
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
//    @IBOutlet weak var mpVolumeViewParentView: UIView!
    @IBOutlet weak var slider: UISlider!
    
    // the hidden MPVolumeView's slider - we are going to link it to volumeSlider in viewDidLoad()
    var mpVolumeSlider : UISlider!
    let SYSTEM_VOLUME_NOTIFICATION = NSNotification.Name("AVSystemController_SystemVolumeDidChangeNotification")
    
    var radioPlayer = AVPlayer()
    var track: Track! = Track()
    var isPlaying : Bool = false
    
    var streamItem : CustomAVPlayerItem!
    
    // counter for ArtWork load retry
    var retry = 0;
        
    //*****************************************************************
    // MARK: - GUI initialisation
    //*****************************************************************
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent // .default
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let theApp = UIApplication.shared.delegate as! AppDelegate

        // add ourselves as observer to be notified when radio station is loaded
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(onDidReceiveRadioStationData),
                                               name: theApp.radioStationDataNotificationName,
                                               object: nil)
        
        // Notification for AVAudioSession Interruption (e.g. Phone call)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(sessionInterrupted),
                                               name: AVAudioSession.interruptionNotification,
                                               object: AVAudioSession.sharedInstance())
        
        // Setup slider
        prepareVolumeSlider()
        
//        let thumbImageNormal = UIImage(named: "slider-ball")
//        mpVolumeSlider?.setThumbImage(thumbImageNormal, for: .normal)
        
        
        // set initial image on cover
//        self.updateAlbumImage(image: UIImage(named: "cover")!)

        // default logic to handle radio station data
        // onDidReceiveRadioStationData(Notification(name: theApp.radioStationDataNotificationName))
    }
    
    deinit {
        // Be a good citizen
        let theApp = UIApplication.shared.delegate as! AppDelegate

        NotificationCenter.default.removeObserver(self,
            name: theApp.radioStationDataNotificationName,
            object: nil)
        
        NotificationCenter.default.removeObserver(self,
            name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance())
        
        NotificationCenter.default.removeObserver(self,
            name: SYSTEM_VOLUME_NOTIFICATION,
            object: AVAudioSession.sharedInstance())
    }
    
    @objc func onDidReceiveRadioStationData(_ notification:Notification) {

        // do not use the notification object has it might be nil
        
        let theApp = UIApplication.shared.delegate as! AppDelegate
        
        // update UI on main thread
        DispatchQueue.main.async {

            // update labels with station name
            self.updateLabels(artist: theApp.station.stationName, track: theApp.station.stationDesc)
            
            // Set View Title
            self.title = theApp.station.stationName
            
            // Setup our stream
            let streamURL = URL(string: theApp.station.stationStreamURL)
            self.streamItem = CustomAVPlayerItem(url: streamURL!, delegate: self)
            self.pausePlayPressed()
        }
    }
    
    //*****************************************************************
    // MARK: - Player Controls (Play/Pause/Volume)
    //*****************************************************************
    
    @IBAction func pausePlayPressed() {

        if (isPlaying) {
            radioPlayer.pause()
            radioPlayer.replaceCurrentItem(with: nil)
            isPlaying = false

            // TODO : change button image
            playPauseButton.setImage(UIImage(named: "btn-play")!, for: .normal)
            
            self.updateAlbumImage(image: UIImage(named: "cover")!)
            
            let theApp = UIApplication.shared.delegate as! AppDelegate
            updateLabels(artist: theApp.station.stationName, track:theApp.station.stationDesc)
        } else {
            radioPlayer.replaceCurrentItem(with: self.streamItem)
            radioPlayer.play()
            isPlaying = true
            
            // TODO : change image
            playPauseButton.setImage(UIImage(named: "btn-pause")!, for: .normal)
            
            // animate with fade-in / fade-out
            // TODO
            
            // update label and artwork will be done automatically when we will receive meta data
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
    
    func updateLabels(artist: String, track: String) {
        songLabel.text = track
        artistLabel.text = artist
    }
    
    //*****************************************************************
    // MARK: - Album Art
    //*****************************************************************
    
    // update the image on the screen
    func updateAlbumImage(url : URL) {
        
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
            
            // Update track struct
            self.track.artworkImage = image
            self.coverImageView.image = image
            
            // Turn off network activity indicator
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            
            // Animate artwork
            // TODO
            
            // Update lockscreen
            self.updateLockScreen()
        }

    }

    // load the artwork from our backend API
    func loadAlbumArtwork() {
        
        if (self.track.artist == "") && (self.track.artist == "") {
            print("no artist nor track name to fetch artwork")
            return
        }

        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
        }

        // get our AppSync client
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let appSyncClient = appDelegate.appSyncClient
        
        print("Going to call backend artwork for \(self.track.artist) and \(self.track.title)")
        appSyncClient?.fetch(query: ArtworkQuery(artist:self.track.artist, track:self.track.title),
                             cachePolicy: .fetchIgnoringCacheData)  {
                                (result, error) in
                                
            if error != nil {
                
                let e = error! as! AWSAppSyncClientError
                let response = e.response
                print(response!)
                                
            } else {
                
                self.retry = 0;
                guard let artwork = result?.data?.artwork else {
                    print("artwork is nil")
                    return
                }
                print(artwork)
                
                // if the API returns non error, it always return an URL
                self.track.artworkURL = artwork.url!

                // load the image from the URL we received
                if let url = URL(string: self.track.artworkURL) {
                    self.updateAlbumImage(url: url)
                }
            }
        }
    }

    //*****************************************************************
    // MARK: - Segue adn Navigation
    //*****************************************************************
        
    @IBAction func shareButtonPressed(_ sender: UIButton) {
        let theApp = UIApplication.shared.delegate as! AppDelegate

        let songToShare = "I'm listening to \(track.title) on \(theApp.station.stationName) via Maxi80 for iOS"
        let activityViewController = UIActivityViewController(activityItems: [songToShare, track.artworkImage!], applicationActivities: nil)
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
        
        // Update notification/lock screen
        let image = track.artworkImage!
        let albumArtwork = MPMediaItemArtwork.init(boundsSize: image.size, requestHandler: { (size) -> UIImage in
            return image
        })
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [
            MPMediaItemPropertyArtist: track.artist,
            MPMediaItemPropertyTitle: track.title,
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
    
    //*****************************************************************
    // MARK: - AVAudio Sesssion Interrupted
    //*****************************************************************
    
    // Example code on handling AVAudio interruptions (e.g. Phone calls)
    @objc func sessionInterrupted(notification: NSNotification) {
        if let typeValue = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? NSNumber{
            if let type = AVAudioSession.InterruptionType(rawValue: typeValue.uintValue){
                if type == .began {
                    print("interruption: began")
                    // Add your code here
                    
                    // TODO isPlaying = false ?
                } else{
                    print("interruption: ended")
                    // Add your code here
                }
            }
        }
    }
}

//*****************************************************************
// MARK: - AVPlayerItem Delegate (for metadata)
//*****************************************************************
extension NowPlayingViewController: CustomAVPlayerItemDelegate {
    
    func onMetaData(_ metaData: [AVMetadataItem]?) {
    
        if let metaDatas = metaData {
            
            let firstMeta: AVMetadataItem = metaDatas.first!
            let metaData = firstMeta.value as! String
            var stringParts = [String]()
            if metaData.range(of: " - ") != nil {
                stringParts = metaData.components(separatedBy: " - ")
            } else {
                stringParts = metaData.components(separatedBy: "-")
            }
            
            // Set artist & songvariables
            track.artist = stringParts[0]
            track.title = ""
            
            if stringParts.count > 1 {
                track.title = stringParts[1]
            }
            
            DispatchQueue.main.async {
                    if kDebugLog {
                        print("METADATA artist: \(self.track.artist) | title: \(self.track.title)")
                    }
                    // Update Labels
                
                    if self.track.artist == "" && self.track.title == "" {
                        // when no meta data received, use station name instead
                        let theApp = UIApplication.shared.delegate as! AppDelegate

                        self.updateLabels(artist: theApp.station.stationName,
                                          track: theApp.station.stationDesc)
                    } else {
                        self.updateLabels(artist: self.track.artist,
                                          track: self.track.title)
                    }
                
                    // songLabel animation
                    // TODO
                    
                    // Update Stations Screen
                    //self.delegate?.songMetaDataDidUpdate(track: self.track)
                    
                    // Query API for album art
                    self.retry = 0;
                    self.loadAlbumArtwork()
                
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
        
        let alert = UIAlertController(title: "Could Not Send Email", message: "Your device could not send e-mail.  Please check e-mail configuration and try again.", preferredStyle:UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK", style: .`default`, handler: { _ in
            NSLog("The \"OK\" alert occured.")
        }))
    }
}

