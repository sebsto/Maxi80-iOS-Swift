//
//  AppDelegate.swift
//  Swift Radio
//
//  Created by Matthew Fecher on 7/2/15.
//  Copyright (c) 2015 MatthewFecher.com. All rights reserved.
//

import UIKit
import MediaPlayer

import AWSAppSync

// https://aws.amazon.com/blogs/mobile/using-amazon-cognito-with-swift-sample-app-developer-guide-and-more/
import AWSCore
//import AWSCognito

protocol MetaDataDelegate {
    func onCurrentTrackChanged(artist: String, track: String)
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    public private(set) var station : StationQuery.Data.Station
    public private(set) var currentArtist : String
    public private(set) var currentTrack : String
    public var isPlaying = false

    public let radioStationDataNotificationName = Notification.Name("didReceiveRadioStationData")
    public let metaDataNotificationName = Notification.Name("didReceiveIcyMetaData")
    public var appSyncClient: AWSAppSyncClient?
    
    private let LOG = Logger.createOSLog(module: "App")
    public var window: UIWindow?

    // set default values
    override init() {
        self.station =  StationQuery.Data.Station(
            name: "Maxi80",
            streamUrl: "https://audio1.maxi80.com",
            imageUrl: "cover.png",
            desc: "La radio de toute une génération",
            longDesc: "Le meilleur de la musique des années 80",
            websiteUrl: "https://maxi80.com",
            donationUrl: "https://www.maxi80.com/paypal.htm"
        )
        self.currentArtist = self.station.name
        self.currentTrack = self.station.desc
        super.init()
    }
    
    //*****************************************************************
    // MARK: - App lifecycle
    //*****************************************************************

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // MPNowPlayingInfoCenter
        UIApplication.shared.beginReceivingRemoteControlEvents()
        
        // Make status the navigation bar is black
        UINavigationBar.appearance().barStyle = .black

        // Set AVFoundation category, required for background audio
        setupAudioService()
        
        // setup appsync
        setupAppSync()
        
        //fetch radio station data from an API call on api.maxi80.net
        queryRadioData()

        return true
        
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
       
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
  
        
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
        
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        
        UIApplication.shared.endReceivingRemoteControlEvents()
        
    }

    //*****************************************************************
    // MARK: - App initialization
    //*****************************************************************

    func setupAppSync() {
        
        
        //initialize app sync
        do {
            // Initialize the Amazon Cognito credentials provider
            let credentialsProvider = AWSCognitoCredentialsProvider(regionType:.EUWest1,
                                                                    identityPoolId:"eu-west-1:74b938b1-4a81-43ed-a4de-86b37001110a")

            //AppSync configuration & client initialization
            let appSyncServiceConfig = try AWSAppSyncServiceConfig()
            let appSyncConfig = try AWSAppSyncClientConfiguration(appSyncServiceConfig: appSyncServiceConfig,
                                                                  credentialsProvider: credentialsProvider
                                                                  )
            
            //AppSync configuration & client initialization
            appSyncClient = try AWSAppSyncClient(appSyncConfig: appSyncConfig)
        } catch {
            os_log_error(LOG, "Error initializing appsync client. \(String(describing: error))")
        }
    }
    
    func setupAudioService() {
        
        // Set AVFoundation category, required for background audio
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(AVAudioSession.Category.playback, mode:AVAudioSession.Mode.default)
            try audioSession.setActive(true)
        } catch let error as NSError {
            os_log_error(LOG, "Failed to set audio session category.  Error: \(String(describing: error))")
        }
    }
    
    //*****************************************************************
    // MARK: - Radio Management
    //*****************************************************************
    
    func queryRadioData() {
        os_log_debug(LOG, "Calling backend to get station details")
        self.appSyncClient?.fetch(query: StationQuery(),
                                  cachePolicy: .fetchIgnoringCacheData) {
                                    (result, error) in
                                    
            if error != nil {
                
                os_log_error(self.LOG, "Error when calling Radio Station Data API : \(error!.localizedDescription)")
                
                let alert = UIAlertController(title: "Error", message: "Can not connect to the network.\n\(error!.localizedDescription)\nBe sure Data or Wifi is enabled and try again.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .default, handler: { _ in
                }))
                self.window?.rootViewController?.present(alert, animated: true, completion: nil)
                
            } else {
                
                if let station = result?.data?.station  {
                    
                    os_log_debug(self.LOG, "Radio Station data received : \(station)")
                    self.station = station
                    
                } else {
                    os_log_error(self.LOG, "Received nil data for station, using default value")
                }
            
                // notify listeners radio data are available (only NowPlayingViewController at this stage)
                NotificationCenter.default.post(name: self.radioStationDataNotificationName,
                                                object: ["station": self.station])
            }
        }
    }
    
    //*****************************************************************
    // MARK: - Receive Meta Data
    //*****************************************************************
    func setTrack(artist: String?, track: String?) {
        let _artist = artist ?? self.station.name
        let _track = track ?? self.station.desc
        
        self.currentArtist = _artist
        self.currentTrack = _track
        
        // notify listeners data are available (only NowPlayingViewController at this stage)
        NotificationCenter.default.post(name: self.metaDataNotificationName,
                                        object: ["artist": self.currentArtist, "track": self.currentTrack])
    }
    
    // callback to receive metadata
    func handleiCyMetaData(metadata : String) {
        var data = metadata.components(separatedBy: " - ")
        os_log_debug(LOG, "Meta Data : \(data)")
        if (data.count == 2) {
            setTrack(artist: data[0].trimmingCharacters(in: .whitespacesAndNewlines),
                     track: data[1].trimmingCharacters(in: .whitespacesAndNewlines))
        } else {
            
            //let's try without space
            data = metadata.components(separatedBy: "-")
            if (data.count == 2) {
                setTrack(artist: data[0].trimmingCharacters(in: .whitespacesAndNewlines),
                         track: data[1].trimmingCharacters(in: .whitespacesAndNewlines))
            } else {
                setTrack(artist: nil, track: metadata)
            }

        }
    }
}
