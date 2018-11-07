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
import AWSCognito

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    //default value for radio Station
    var station = RadioStation(
        name: "Maxi80",
        streamURL: "https://audio1.maxi80.com",
        imageURL: "cover.png",
        desc: "La radio de toute une génération",
        longDesc: "Le meilleur de la musique des années 80"
    )
    
    var appSyncClient: AWSAppSyncClient?
    
    let radioStationDataNotificationName = Notification.Name("didReceiveRadioStationData")

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

    func setupAppSync() {
        
        // Initialize the Amazon Cognito credentials provider
        let credentialsProvider = AWSCognitoCredentialsProvider(regionType:.EUWest1,
                                                                 identityPoolId:"eu-west-1:74b938b1-4a81-43ed-a4de-86b37001110a")
        
        //appsync offline database
        let databaseURL = URL(fileURLWithPath:NSTemporaryDirectory()).appendingPathComponent("maxi80")
        
        //initialize app sync
        do {
            //AppSync configuration & client initialization
            let appSyncConfig = try AWSAppSyncClientConfiguration(appSyncClientInfo: AWSAppSyncClientInfo(),
                                                                  credentialsProvider : credentialsProvider,
                                                                  databaseURL: databaseURL)
            self.appSyncClient = try AWSAppSyncClient(appSyncConfig: appSyncConfig)
        } catch {
            print("Error initializing appsync client. \(error)")
        }
    }
    
    func setupAudioService() {
        
        // Set AVFoundation category, required for background audio
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(AVAudioSession.Category.playback, mode:AVAudioSession.Mode.default)
            try audioSession.setActive(true)
        } catch let error as NSError {
            print("Failed to set audio session category.  Error: \(String(describing: error))")
        }
    }
    
    //*****************************************************************
    // MARK: - Radio Management
    //*****************************************************************
    
    func queryRadioData() {
        if kDebugLog { print("Calling backend to get station details") }
        self.appSyncClient?.fetch(query: StationQuery(),
                                  cachePolicy: .fetchIgnoringCacheData) {
                                    (result, error) in
                                    
            if error != nil {
                print("Error when calling Radio Station Data API")
                print(error?.localizedDescription ?? "")
            } else {
                guard let station = result?.data?.station else {
                    print("Received nil data for station, using default value")
                    return
                }
                
                if kDebugLog { print("Radio Station data received : \(station)") }
                self.station = RadioStation(
                    name: station.name,
                    streamURL: station.streamUrl,
                    imageURL: station.imageUrl,
                    desc: station.desc,
                    longDesc: station.longDesc
                )
                
                // notify listeners data are available (only NowPlayingViewController at this stage)
                NotificationCenter.default.post(name: self.radioStationDataNotificationName,
                                                object: self.station)
            }
        }
    }
}
