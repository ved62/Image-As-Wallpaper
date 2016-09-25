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

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let defaults = UserDefaults.standard
        let conformityLevel = defaults.double(forKey: "conformityLevel")
        if conformityLevel > 0.0 {
            appController.conformityLevel = conformityLevel
        } else { // The first run. Take value from GUI
            appController.conformityLevel = stepper.doubleValue
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        let defaults = UserDefaults.standard
        defaults.set(appController.conformityLevel, forKey: "conformityLevel")
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    func applicationDidChangeScreenParameters(_ notification: Notification) {
        appController.screenSize = window.screen!.frame.size
    }
}

