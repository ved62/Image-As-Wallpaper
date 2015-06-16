//
//  AppDelegate.swift
//  Image As Wallpaper
//
//  Created by Владислав Эдуардович Дембский on 11.06.15.
//  Copyright (c) 2015 Vladislav Dembskiy. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!
    @IBOutlet weak var appController: AppController!    
    @IBOutlet weak var stepper: NSStepper!

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        let defaults = NSUserDefaults.standardUserDefaults()
        let conformityLevel = defaults.doubleForKey("conformityLevel")
        if conformityLevel > 0.0 {
            appController.conformityLevel = conformityLevel
        } else { // The first run. Take value from GUI
            appController.conformityLevel = stepper.doubleValue
        }
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setDouble(appController.conformityLevel, forKey: "conformityLevel")
    }

    func applicationShouldTerminateAfterLastWindowClosed(sender: NSApplication) -> Bool {
        return true
    }

    func applicationDidChangeScreenParameters(notification: NSNotification) {
        appController.screenSize = window.screen!.frame.size
    }
}

