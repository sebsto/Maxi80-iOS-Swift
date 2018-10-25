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
import Spring
import AWSAppSync

//*****************************************************************
// NowPlayingViewController
//*****************************************************************

class NowPlayingViewController: UIViewController {

    @IBOutlet weak var albumHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var albumImageView: SpringImageView!
    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet weak var songLabel: SpringLabel!
    @IBOutlet weak var pauseButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var volumeParentView: UIView!
    @IBOutlet      var slider: UISlider! = UISlider()
    
    var currentStation: RadioStation!
    var nowPlayingImageView: UIImageView!
    var radioPlayer = AVPlayer()
    var track: Track! = Track()
    var mpVolumeSlider = UISlider()
    
    var streamItem : CustomAVPlayerItem!
    
    // counter for ArtWork load retry
    var retry = 0;
        
    //*****************************************************************
    // MARK: - ViewDidLoad
    //*****************************************************************
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let theApp = UIApplication.shared.delegate as! AppDelegate

        // Create Now Playing BarItem
        createNowPlayingAnimation()
        

        // add ourselves as observer to benotified when radio station is loaded
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(onDidReceiveRadioStationData(_:)),
                                               name: theApp.radioStationDataNotificationName,
                                               object: nil)
        
        // Notification for AVAudioSession Interruption (e.g. Phone call)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(NowPlayingViewController.sessionInterrupted),
                                               name: AVAudioSession.interruptionNotification,
                                               object: AVAudioSession.sharedInstance())
        
        // Setup slider
        setupVolumeSlider()

        // Set AlbumArtwork Constraints
        optimizeForDeviceSize()
        self.updateAlbumImage(image: UIImage(named: "station-maxi80")!)

        currentStation =  theApp.station //query radio station details from App Delegatelet
        guard currentStation != nil else {
            // current station is not initialized yet.
            if kDebugLog { print("Current Station is not initialized yet") }
            return
        }
        
        // default logic to handle radio station data
        onDidReceiveRadioStationData(Notification(name: theApp.radioStationDataNotificationName))
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
    }
    
    @objc func onDidReceiveRadioStationData(_ notification:Notification) {

        // do not use the notification object has it might be nil
        
        let theApp = UIApplication.shared.delegate as! AppDelegate
        currentStation = theApp.station;
        
        // update UI on main thread
        DispatchQueue.main.async {

            // update labels with station name
            self.updateLabels(artist: self.currentStation.stationName, track: self.currentStation.stationDesc)
            
            // Set View Title
            self.title = self.currentStation.stationName
            
            // Setup our stream
            let streamURL = URL(string: self.currentStation.stationStreamURL)
            self.streamItem = CustomAVPlayerItem(url: streamURL!, delegate: self)
            self.playPressed()
        }
    }
    
    //*****************************************************************
    // MARK: - Setup
    //*****************************************************************

  
    func setupVolumeSlider() {
        // Note: This slider implementation uses a MPVolumeView
        // The volume slider only works in devices, not the simulator.
        volumeParentView.backgroundColor = UIColor.clear
        let volumeView = MPVolumeView(frame: volumeParentView.bounds)
        for view in volumeView.subviews {
            let uiview: UIView = view as UIView
            if (uiview.description as NSString).range(of: "MPVolumeSlider").location != NSNotFound {
                mpVolumeSlider = (uiview as! UISlider)
            }
        }
        
        let thumbImageNormal = UIImage(named: "slider-ball")
        slider?.setThumbImage(thumbImageNormal, for: .normal)
        
    }
    
    //*****************************************************************
    // MARK: - Player Controls (Play/Pause/Volume)
    //*****************************************************************
    
    @IBAction func playPressed() {
        radioPlayer.replaceCurrentItem(with: self.streamItem)
        radioPlayer.play()

        playButtonEnable(enabled: false)

        // songLabel Animation
        songLabel.animation = "flash"
        songLabel.animate()
        
        // Start NowPlaying Animation
        nowPlayingImageView.startAnimating()
        
        // update label and artwork will be done automatically when we will receive meta data
        
    }
    
    @IBAction func pausePressed() {
        radioPlayer.pause()
        radioPlayer.replaceCurrentItem(with: nil)

        playButtonEnable()
        
        self.updateAlbumImage(image: UIImage(named: "station-maxi80")!)
        
        updateLabels(artist: currentStation.stationName, track:currentStation.stationDesc)
        nowPlayingImageView.stopAnimating()
    }
    
    @IBAction func volumeChanged(_ sender:UISlider) {
        mpVolumeSlider.value = sender.value
    }
    
    //*****************************************************************
    // MARK: - UI Helper Methods
    //*****************************************************************
    
    func optimizeForDeviceSize() {
        
        // Adjust album size to fit iPhone 4s, 6s & 6s+
        let deviceHeight = self.view.bounds.height
        
        if deviceHeight == 480 {
            albumHeightConstraint.constant = 106
            view.updateConstraints()
        } else if deviceHeight == 667 {
            albumHeightConstraint.constant = 230
            view.updateConstraints()
        } else if deviceHeight > 667 {
            albumHeightConstraint.constant = 260
            view.updateConstraints()
        }
    }
    
    func updateLabels(artist: String, track: String) {
        songLabel.text = artist
        artistLabel.text = track
    }
    
    func playButtonEnable(enabled: Bool = true) {
        if enabled {
            playButton.isEnabled = true
            pauseButton.isEnabled = false
        } else {
            playButton.isEnabled = false
            pauseButton.isEnabled = true
        }
    }
    
    func createNowPlayingAnimation() {
        
        // Setup ImageView
        nowPlayingImageView = UIImageView(image: UIImage(named: "NowPlayingBars-3"))
        nowPlayingImageView.autoresizingMask = []
        nowPlayingImageView.contentMode = UIView.ContentMode.center
        
        // Create Animation
        nowPlayingImageView.animationImages = AnimationFrames.createFrames()
        nowPlayingImageView.animationDuration = 0.7
        
        // Create Top BarButton
        let barButton = UIButton(type: UIButton.ButtonType.custom)
        barButton.frame = CGRect(x: 0,y: 0,width: 40,height: 40);
        barButton.addSubview(nowPlayingImageView)
        nowPlayingImageView.center = barButton.center
        
        let barItem = UIBarButtonItem(customView: barButton)
        self.navigationItem.rightBarButtonItem = barItem
        
    }
    
    func startNowPlayingAnimation() {
        nowPlayingImageView.startAnimating()
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
            self.albumImageView.image = image
            
            // Turn off network activity indicator
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            
            // Animate artwork
            self.albumImageView.animation = "wobble"
            self.albumImageView.duration = 2
            self.albumImageView.animate()
            
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
        appSyncClient?.fetch(query: ArtworkQuery(artist:self.track.artist, track:self.track.title), cachePolicy: .fetchIgnoringCacheData)  { (result, error) in
            if error != nil {
                
                let e = error! as! AWSAppSyncClientError
                let response = e.response
                print(response!)
                
                if ( self.retry <= 2 && (response?.statusCode == 401 || response?.statusCode == 403)) {
                
                    // when error is 'forbidden', try to refresh Cognito ID and try again
                    let theApp = UIApplication.shared.delegate as! AppDelegate
                    theApp.credentialsProvider!.getIdentityId().continueWith { (task: AWSTask!) -> AnyObject? in
                        
                        if (task.error != nil) {
                            print("Error getting CognitoID: " + task.error!.localizedDescription )
                            
                        } else {
                            appDelegate.cognitoID = task.result as String?
                            if kDebugLog { print("CognitoID = \(String(describing: appDelegate.cognitoID))") }
                            self.retry = self.retry + 1;
                            // exponential wait
                            sleep(UInt32(self.retry))
                            self.loadAlbumArtwork();
                        }
                        return nil
                    }
                } else {
                    print("load artwork returned non 400 error or retry exceeded")
                }
                
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
        let songToShare = "I'm listening to \(track.title) on \(currentStation.stationName) via Maxi80 for iOS"
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
                playPressed()
            case .remoteControlPause:
                pausePressed()
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
                } else{
                    print("interruption: ended")
                    // Add your code here
                }
            }
        }
    }
    
    
    //*****************************************************************
    // MARK: - Detect end of mp3 in case you're using a file instead of a stream
    //*****************************************************************
    
    @objc func playerItemDidReachEnd(){
        if kDebugLog {
            print("playerItemDidReachEnd")
        }
    }
    
}

//*****************************************************************
// MARK: - AVPlayerItem Delegate (for metadata)
//*****************************************************************
extension NowPlayingViewController: CustomAVPlayerItemDelegate {
    
    func onMetaData(_ metaData: [AVMetadataItem]?) {
    
        if let metaDatas = metaData {
            
            startNowPlayingAnimation()
            
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
                        self.updateLabels(artist: self.currentStation.stationName,
                                          track: self.currentStation.stationDesc)
                    } else {
                        self.updateLabels(artist: self.track.artist,
                                          track: self.track.title)
                    }
                
                    // songLabel animation
                    self.songLabel.animation = "zoomIn"
                    self.songLabel.duration = 1.5
                    self.songLabel.damping = 1
                    self.songLabel.animate()
                    
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

