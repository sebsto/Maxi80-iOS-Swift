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

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var station: RadioStation!
    var appSyncClient: AWSAppSyncClient?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        //appsync offline database
        let databaseURL = URL(fileURLWithPath:NSTemporaryDirectory()).appendingPathComponent("maxi80")
        
        //initialize app sync
        do {
            //AppSync configuration & client initialization
            let appSyncConfig = try AWSAppSyncClientConfiguration(appSyncClientInfo: AWSAppSyncClientInfo(),databaseURL: databaseURL)
            appSyncClient = try AWSAppSyncClient(appSyncConfig: appSyncConfig)
        } catch {
            print("Error initializing appsync client. \(error)")
        }
        
        // MPNowPlayingInfoCenter
        UIApplication.shared.beginReceivingRemoteControlEvents()
        
        // Make status bar white
        UINavigationBar.appearance().barStyle = .black
        
        //initialize radio station data
        // these are the default
        station = RadioStation(
            name: "Maxi80",
            streamURL: "https://audio1.maxi80.com",
            imageURL: "station-maxi80.png",
            desc: "La radio de toute une génération",
            longDesc: "Le meilleur de la musique des années 80"
        )
        //fetch these data from an API call on api.maxi80.net
        print("Calling backend to get station details")
        appSyncClient?.fetch(query: StationQuery()) { (result, error) in
            if error != nil {
                print(error?.localizedDescription ?? "")
                return
            }
            self.station = RadioStation(
                name: result?.data?.station?.name ?? self.station.stationName,
                streamURL: result?.data?.station?.streamUrl ?? self.station.stationStreamURL,
                imageURL: result?.data?.station?.imageUrl  ?? self.station.stationImageURL,
                desc: result?.data?.station?.desc  ?? self.station.stationDesc,
                longDesc: result?.data?.station?.longDesc ?? self.station.stationLongDesc
            )
            print(result?.data?.station ?? "station is nil")
        }
        
        // Set AVFoundation category, required for background audio
        setupAudioService()
        
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
    // MARK: - Application Initialization Code
    //*****************************************************************

    func setupAudioService() {
        
        // Set AVFoundation category, required for background audio
        var error: NSError?
        var success: Bool
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSession.Category.playback, mode:AVAudioSession.Mode.default)
            success = true
        } catch let error1 as NSError {
            error = error1
            success = false
        }
        if !success {
            if kDebugLog { print("Failed to set audio session category.  Error: \(String(describing: error))") }
        }
        
        // Set audioSession as active
        do {
            try audioSession.setActive(true)
        } catch let error2 as NSError {
            if kDebugLog { print("audioSession setActive error \(error2)") }
        }
    }
    

   
}


// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromAVAudioSessionCategory(_ input: AVAudioSession.Category) -> String {
	return input.rawValue
}
