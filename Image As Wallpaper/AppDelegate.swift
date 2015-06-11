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

    @IBOutlet weak var contentViewController: ContentViewController!

    @IBOutlet weak var screenDimensionsText: NSTextField!
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        showScreenSize()
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }

    func applicationShouldTerminateAfterLastWindowClosed(sender: NSApplication) -> Bool {
        return true
    }

    func showScreenSize() {
        let screenSize = getScreenSize(window)
        var handyString = "Screen: \(Int(screenSize.width)) x \(Int(screenSize.height))"
        handyString = handyString.stringByAppendingFormat("  Aspect ratio: %1.2f", screenSize.width / screenSize.height)
        screenDimensionsText.stringValue = handyString
    }

    func applicationDidChangeScreenParameters(notification: NSNotification) {
        showScreenSize()
    }

}

