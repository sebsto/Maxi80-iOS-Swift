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

//*****************************************************************
// Protocol
// Updates the StationsViewController when the track changes
//*****************************************************************

protocol NowPlayingViewControllerDelegate: class {
    func songMetaDataDidUpdate(track: Track)
    func artworkDidUpdate(track: Track)
    func trackPlayingToggled(track: Track)
}

//*****************************************************************
// NowPlayingViewController
//*****************************************************************

class NowPlayingViewController: UIViewController {

    @IBOutlet weak var albumHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var albumImageView: SpringImageView!
    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet weak var pauseButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var songLabel: SpringLabel!
    @IBOutlet weak var stationDescLabel: UILabel!
    @IBOutlet weak var volumeParentView: UIView!
    @IBOutlet      var slider: UISlider! = UISlider()
    
    var currentStation: RadioStation!
    var downloadTask: URLSessionDownloadTask?
    var iPhone4 = false
    var justBecameActive = false
    var newStation = true
    var nowPlayingImageView: UIImageView!
    var radioPlayer = AVPlayer()
    var track: Track!
    var mpVolumeSlider = UISlider()
    
    weak var delegate: NowPlayingViewControllerDelegate?
    
    //*****************************************************************
    // MARK: - ViewDidLoad
    //*****************************************************************
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup handoff functionality - GH
        setupUserActivity()
        
        // Add your radio station information here:
        let theApp = UIApplication.shared.delegate as! AppDelegate
        currentStation =  theApp.station //query radio station details from App Delegae
            
        // Set AlbumArtwork Constraints
        optimizeForDeviceSize()

        // Set View Title
        self.title = currentStation.stationName
        
        // Create Now Playing BarItem
        createNowPlayingAnimation()
        
        // Setup AVPlayer
        setupPlayer()
        
        // Notification for when app becomes active
        NotificationCenter.default.addObserver(self,
            selector: #selector(NowPlayingViewController.didBecomeActiveNotificationReceived),
            name: Notification.Name("UIApplicationDidBecomeActiveNotification"),
            object: nil)
        
        // Notification for AVAudioSession Interruption (e.g. Phone call)
        NotificationCenter.default.addObserver(self,
            selector: #selector(NowPlayingViewController.sessionInterrupted),
            name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance())
        
        // Check for station change
        if newStation {
            track = Track()
            stationDidChange()
        } else {
            updateLabels()
            albumImageView.image = track.artworkImage
            
            if !track.isPlaying {
                pausePressed()
            } else {
                nowPlayingImageView.startAnimating()
            }
        }
        
        // Setup slider
        setupVolumeSlider()
        
    }
    
    @objc func didBecomeActiveNotificationReceived() {
        // View became active
        updateLabels()
        justBecameActive = true
        updateAlbumArtwork()
    }
    
    deinit {
        // Be a good citizen
        NotificationCenter.default.removeObserver(self,
            name: Notification.Name("UIApplicationDidBecomeActiveNotification"),
            object: nil)
        NotificationCenter.default.removeObserver(self,
            name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance())
    }
    
    //*****************************************************************
    // MARK: - Setup
    //*****************************************************************
    
    func setupPlayer(){
        radioPlayer.rate = 1
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.playerItemDidReachEnd),
            name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
            object: self.radioPlayer.currentItem
        )
        
    }
    
    func resetPlayer(){
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: self.radioPlayer.currentItem)
    }
  
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
    
    func stationDidChange() {
        resetPlayer()
        
        guard let streamURL = URL(string: currentStation.stationStreamURL) else {
            if kDebugLog {
                print("Stream Error \(currentStation.stationStreamURL)")
            }
            return
        }
        
        let streamItem = CustomAVPlayerItem(url: streamURL)
        streamItem.delegate = self
        
        DispatchQueue.main.async {
            // prevent the player from "stalling"
            self.radioPlayer.replaceCurrentItem(with: streamItem)
            self.radioPlayer.play()
        }
        
        updateLabels(statusMessage: "Loading Station...")
        
        print("stationDidChange \(currentStation.stationStreamURL)")
        
        // songLabel animate
        songLabel.animation = "flash"
        songLabel.repeatCount = 3
        songLabel.animate()
        
        resetAlbumArtwork()
        track.isPlaying = true
    }
    
    //*****************************************************************
    // MARK: - Player Controls (Play/Pause/Volume)
    //*****************************************************************
    
    @IBAction func playPressed() {
        track.isPlaying = true
        playButtonEnable(enabled: false)
        radioPlayer.play()
        updateLabels()
        
        // songLabel Animation
        songLabel.animation = "flash"
        songLabel.animate()
        
        // Start NowPlaying Animation
        nowPlayingImageView.startAnimating()
        
        // Update StationsVC
        self.delegate?.trackPlayingToggled(track: self.track)
    }
    
    @IBAction func pausePressed() {
        track.isPlaying = false
        
        playButtonEnable()
        
        radioPlayer.pause()
        updateLabels(statusMessage: "Station Paused...")
        nowPlayingImageView.stopAnimating()
        
        // Update StationsVC
        self.delegate?.trackPlayingToggled(track: self.track)
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
            iPhone4 = true
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
    
    func updateLabels(statusMessage: String = "") {
        
        if statusMessage != "" {
            // There's a an interruption or pause in the audio queue
            songLabel.text = statusMessage
            artistLabel.text = currentStation.stationName
            
        } else {
            // Radio is (hopefully) streaming properly
            if track != nil {
                songLabel.text = track.title
                artistLabel.text = track.artist
            }
        }
        
        // Hide station description when album art is displayed or on iPhone 4
        if track.artworkLoaded || iPhone4 {
            stationDescLabel.isHidden = true
        } else {
            stationDescLabel.isHidden = false
            stationDescLabel.text = currentStation.stationDesc
        }
    }
    
    func playButtonEnable(enabled: Bool = true) {
        if enabled {
            playButton.isEnabled = true
            pauseButton.isEnabled = false
            track.isPlaying = false
        } else {
            playButton.isEnabled = false
            pauseButton.isEnabled = true
            track.isPlaying = true
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
    
    func resetAlbumArtwork() {
        
        DispatchQueue.main.async {
            self.track.artworkLoaded = false
            self.track.artworkURL = self.currentStation.stationImageURL
            self.updateAlbumArtwork()
            self.stationDescLabel.isHidden = false
        }
    }
    
    func updateAlbumArtwork() {
        track.artworkLoaded = false
        if track.artworkURL.range(of: "http") != nil {
            
            // Hide station description
            DispatchQueue.main.async(execute: {
                //self.albumImageView.image = nil
                self.stationDescLabel.isHidden = false
            })
            
            // Attempt to download album art from an API
            if let url = URL(string: track.artworkURL) {
                
                self.downloadTask = self.albumImageView.loadImageWithURL(url: url) { (image) in
                    
                    //we are now in the network (loadImageWithURL) thread, update GUI on main thread
                    DispatchQueue.main.async {
                        // Update track struct
                        self.track.artworkImage = image
                        self.track.artworkLoaded = true
                        
                        // Turn off network activity indicator
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        
                        // Animate artwork
                        self.albumImageView.animation = "wobble"
                        self.albumImageView.duration = 2
                        self.albumImageView.animate()
                        self.stationDescLabel.isHidden = true

                        // Update lockscreen
                        self.updateLockScreen()
                        
                        // Call delegate function that artwork updated
                        self.delegate?.artworkDidUpdate(track: self.track)
                    }
                }
            }
            
            // Hide the station description to make room for album art
            if track.artworkLoaded && !self.justBecameActive {
                self.stationDescLabel.isHidden = true
                self.justBecameActive = false
            }
            
        } else if track.artworkURL != "" {
            // Local artwork
            DispatchQueue.main.async {
                self.albumImageView.image = UIImage(named: self.track.artworkURL)
                self.track.artworkImage = self.albumImageView.image
                self.track.artworkLoaded = true
                
                // Call delegate function that artwork updated
                self.delegate?.artworkDidUpdate(track: self.track)
            }
        } else {
            DispatchQueue.main.async {
                // No Station or API art found, use default art
                self.albumImageView.image = UIImage(named: "albumArt")
                self.track.artworkImage = self.albumImageView.image
            }
            
        }
        
        // Force app to update display
        DispatchQueue.main.async {
            self.view.setNeedsDisplay()
        }
    }

    // Call LastFM or iTunes API to get album art url
    
    func queryAlbumArt() {
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        // Construct either LastFM or iTunes API call URL
        let queryURL: String
        if useLastFM {
            queryURL = String(format: "http://ws.audioscrobbler.com/2.0/?method=track.getInfo&api_key=%@&artist=%@&track=%@&format=json", apiKey, track.artist, track.title)
        } else {
            queryURL = String(format: "https://itunes.apple.com/search?term=%@+%@&entity=song", track.artist, track.title)
        }
        
        let escapedURL = queryURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        
        // Query API
        DataManager.getTrackDataWithSuccess(queryURL: escapedURL!) { (data) in
            
            if kDebugLog {
                print("API SUCCESSFUL RETURN")
                print("url: \(escapedURL!)")
            }
            
            let json = JSON(data: data! as Data)
            
            if useLastFM {
                // Get Largest Sized LastFM Image
                if let imageArray = json["track"]["album"]["image"].array {
                    
                    let arrayCount = imageArray.count
                    let lastImage = imageArray[arrayCount - 1]
                    
                    if let artURL = lastImage["#text"].string {
                        
                        // Check for Default Last FM Image
                        if artURL.range(of: "/noimage/") != nil {
                            self.resetAlbumArtwork()
                            
                        } else {
                            // LastFM image found!
                            self.track.artworkURL = artURL
                            self.track.artworkLoaded = true
                            self.updateAlbumArtwork()
                        }
                        
                    } else {
                        self.resetAlbumArtwork()
                    }
                } else {
                    self.resetAlbumArtwork()
                }
            
            } else {
                // Use iTunes API. Images are 100px by 100px
                if let artURL = json["results"][0]["artworkUrl100"].string {
                    
                    if kDebugLog { print("iTunes artURL: \(artURL)") }
                    
                    self.track.artworkURL = artURL
                    self.track.artworkLoaded = true
                    self.updateAlbumArtwork()
                } else {
                    self.resetAlbumArtwork()
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
    // MARK: - Handoff Functionality - GH
    //*****************************************************************
    
    func setupUserActivity() {
        let activity = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb ) //"com.graemeharrison.handoff.googlesearch" //NSUserActivityTypeBrowsingWeb
        userActivity = activity
        let url = "https://www.google.com/search?q=\(self.artistLabel.text!)+\(self.songLabel.text!)"
        let urlStr = url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        let searchURL : URL = URL(string: urlStr!)!
        activity.webpageURL = searchURL
        userActivity?.becomeCurrent()
    }
    
    override func updateUserActivityState(_ activity: NSUserActivity) {
        let url = "https://www.google.com/search?q=\(self.artistLabel.text!)+\(self.songLabel.text!)"
        let urlStr = url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        let searchURL : URL = URL(string: urlStr!)!
        activity.webpageURL = searchURL
        super.updateUserActivityState(activity)
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
            let currentSongName = track.title
            track.artist = stringParts[0].decodeAll()
            track.title = stringParts[0].decodeAll()
            
            if stringParts.count > 1 {
                track.title = stringParts[1].decodeAll()
            }
            
            if track.artist == "" && track.title == "" {
                track.artist = currentStation.stationDesc
                track.title = currentStation.stationName
            }
            
            DispatchQueue.main.async {
                if currentSongName != self.track.title {
                    if kDebugLog {
                        print("METADATA artist: \(self.track.artist) | title: \(self.track.title)")
                    }
                    // Update Labels
                    self.artistLabel.text = self.track.artist
                    self.songLabel.text = self.track.title
                    self.updateUserActivityState(self.userActivity!)
                    
                    // songLabel animation
                    self.songLabel.animation = "zoomIn"
                    self.songLabel.duration = 1.5
                    self.songLabel.damping = 1
                    self.songLabel.animate()
                    
                    // Update Stations Screen
                    self.delegate?.songMetaDataDidUpdate(track: self.track)
                    
                    // Query API for album art
                    self.resetAlbumArtwork()
                    self.queryAlbumArt()
                    
                }
                self.artistLabel.text = self.track.artist
                self.songLabel.text = self.track.title
                
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

