//
//  AppDelegate.swift
//  MovieousDemo
//
//  Created by Chris Wang on 2019/4/9.
//  Copyright © 2019 Movieous Team. All rights reserved.
//

import UIKit
import MovieousShortVideo
import MovieousPlayer
import SVProgressHUD

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        #warning("此 License 仅用于试用，正式上线请先联系 UCloud/Movieous 销售获取正式上线的 License")
        MSVAuthentication.register(withLicense: "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJhcHBpZCI6InZpZGVvLm1vdmllb3VzLk1vdmllb3VzRGVtbyJ9.r2JE2BO7UYllkOmAEjx6PyyyvE12OdgSFFkn6GtrD-k")
        SVProgressHUD.setDefaultMaskType(.black)
        self.window = UIWindow()
        self.window?.makeKeyAndVisible()
        window?.rootViewController = UINavigationController(rootViewController: MDAudienceViewController())
//        window?.rootViewController = UINavigationController(rootViewController: MDRecorderViewController())
//        let clip = try! MSVMainTrackClip(type: .AV, path: Bundle.main.path(forResource: "20190810195728357", ofType: "mp4")!)
//
//        let vc = MDVideoEditorViewController()
//        vc.draft = MSVDraft()
//        try! vc.draft.update(mainTrackClips: [clip])
//        self.window?.rootViewController = UINavigationController(rootViewController: vc)
//        let clip = try! MSVMainTrackClip(type: .AV, url: Bundle.main.url(forResource: "20190810195728357", withExtension: "mp4")!)
//        let vc = MDEditorViewController()
//        vc.draft = MSVDraft()
//        try! vc.draft.update(mainTrackClips: [clip, clip.copy() as! MSVMainTrackClip])
//        window?.rootViewController = UINavigationController(rootViewController: vc)
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

