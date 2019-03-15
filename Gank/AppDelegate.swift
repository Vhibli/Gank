//
//  AppDelegate.swift
//  Gank
//
//  Created by 叶帆 on 2016/10/12.
//  Copyright © 2016年 Suzhou Coryphaei Information&Technology Co., Ltd. All rights reserved.
//

import UIKit
import Reachability
import Alamofire
import AlamofireNetworkActivityIndicator
import IQKeyboardManagerSwift
import MonkeyKing
import Bugly
import LeanCloud

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    let reachability = Reachability()!
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        window?.backgroundColor = UIColor.white
        
        // Global Tint Color
        window?.tintColor = UIColor.gankTintColor()
        window?.tintAdjustmentMode = .normal
        
        // Network Status Minitor
        configureNetworkReachable()
        
        // Global Configure
        configureGankConfig()
        
        // Share Configure
        configureShare()
        
        // Background Fetch timer
        UIApplication.shared.setMinimumBackgroundFetchInterval(3600)
        
        // IQKeyboardManager Configure
        IQKeyboardManager.shared.enable = true
        IQKeyboardManager.shared.shouldResignOnTouchOutside = true
        
        // Bugly
        Bugly.start(withAppId: "66bade34d0")
        
        // LeanCloud
        LCApplication.default.set(
            id:  "xUyRzoEBJGdOFUDjQ5ADtxRi-gzGzoHsz",
            key: "ctMjwiEyOSXcWyKA6YlLT47p"
        )
        configureVersion()
        
        let storyboard = UIStoryboard.gank_main
        window?.rootViewController = storyboard.instantiateInitialViewController()
        
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
        
        reachability.stopNotifier()
    }
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        
        if MonkeyKing.handleOpenURL(url) {
            return true
        }
        
        return false
    }
    
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        gankLog.debug("APP Perform Fetch")
        
        if GankUserDefaults.isBackgroundEnable.value == false {
            completionHandler(.noData)
            return
        }
        
        GankBackgroundFetchService.shared.performFetchWithCompletionHandler { (result) in
            SafeDispatch.async {
                completionHandler(result)
            }
        }
    }
    
    fileprivate lazy var tabbarSoundEffect: GankSoundEffect = {
        
        guard let fileURL = Bundle.main.url(forResource: "tabbar", withExtension: "m4a") else {
            fatalError("YepSoundEffect: file no found!")
        }
        return GankSoundEffect(fileURL: fileURL)
    }()
    
    fileprivate lazy var heavyFeedbackEffect: GankFeedbackEffect = {
        return GankFeedbackEffect(style: .heavy)
    }()
    
    fileprivate func configureNetworkReachable() {
        
        NetworkActivityIndicatorManager.shared.isEnabled = true
        
        reachability.whenReachable = { reachability in
            if reachability.connection == .wifi {
                gankLog.debug("当前是 WiFi 网络连接")
            } else {
                gankLog.debug("当前 2G/3G/4G 网络连接")
            }
        }
        
        reachability.whenUnreachable = { reachability in
            gankLog.debug("当前无网络连接")
        }
        
        do {
            try reachability.startNotifier()
        } catch {
            gankLog.debug("Unable to start notifier")
        }
    }
    
    fileprivate func configureGankConfig() {
        
        GankConfig.tabbarSoundEffectAction = { [weak self] in
            self?.tabbarSoundEffect.play()
        }
        
        GankConfig.heavyFeedbackEffectAction = { [weak self] in
            self?.heavyFeedbackEffect.play()
        }
        
        GankNotificationService.shared.initAuthorization()
        
    }
    
    fileprivate func configureShare() {
        MonkeyKing.registerAccount(.weChat(appID: GankConfig.Wechat.appID, appKey: GankConfig.Wechat.appKey, miniAppID: nil))
        MonkeyKing.registerAccount(.weibo(appID: GankConfig.Weibo.appID, appKey: GankConfig.Weibo.appKey, redirectURL: GankConfig.Weibo.redirectURL))
        MonkeyKing.registerAccount(.qq(appID: GankConfig.QQ.appID))
        MonkeyKing.registerAccount(.pocket(appID: GankConfig.Pocket.appID))
    }
    
    fileprivate func configureVersion() {
        let tb_version = LCQuery(className: "Version")
        tb_version.get(GankConfig.versionObjectId) { result in
            switch result {
            case .success(let query):
                let version = query.get("version") as! LCString
                GankUserDefaults.version.value = version.value == Bundle.releaseVersionNumber
            case .failure(let error):
                gankLog.debug(error)
                GankUserDefaults.version.value = false
            }
        }
    }
}

