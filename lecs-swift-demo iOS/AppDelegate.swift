//
//  AppDelegate.swift
//  lecs-swift-demo iOS
//
//  Created by David Kanenwisher on 7/22/23.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var core: AppCore?

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Insert code here to initialize your application
        let useRenderServiceErsatz = CommandLine.arguments.contains("-render-service-ersatz")
        let renderServiceType: RenderServiceType = useRenderServiceErsatz ? .ersatz : .metal

        let config = AppCoreConfig(
            game: AppCoreConfig.Game(
                world: AppCoreConfig.Game.World()
            ),
            platform: AppCoreConfig.Platform(
                maximumTimeStep: 1 / 20, // don't step bigger than this (minimum of 20 fps)
                worldTimeStep: 1 / 120 // 120 steps a second
            ),
            services: AppCoreConfig.Services(
                renderService: AppCoreConfig.Services.RenderService(
                    type: renderServiceType,
                    clearColor: (0.3, 0.0, 0.3, 1.0)
                ),
                fileService: AppCoreConfig.Services.FileService(
                    levelsFile: AppCoreConfig.Services.FileService.FileDescriptor(name: "levels", ext: "json")
                )
            )
        )
        core = AppCore(config)
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
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

