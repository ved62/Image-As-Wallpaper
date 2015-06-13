//
//  AppController.swift
//  Image As Wallpaper
//
//  This class support cocoa bindings
//
//  Created by Владислав Эдуардович Дембский on 13.06.15.
//  Copyright (c) 2015 Vladislav Dembskiy. All rights reserved.
//

import Cocoa

@IBDesignable
class AppController: NSObject {
    
    @IBOutlet weak var  dataLoad: DataLoad!

    private dynamic var screenDimensions: String = ""
    dynamic var conformityLevel: Double = 0.98
    dynamic var lookInSubDirs: Int = 1

    var screenSize: CGSize {
        get { return NSScreen.mainScreen()!.frame.size }
        set { updateScreenDimensions(newValue, string: &screenDimensions) }
    }

    private func updateScreenDimensions(screenSize: CGSize, inout string: String) {
        string = "Screen Dimensions: \(Int(screenSize.width)) x \(Int(screenSize.height))"
        string = string.stringByAppendingFormat("  Aspect ratio: %1.2f", screenSize.width / screenSize.height)
    }

    @IBAction func selectFiles(sender: AnyObject) {
        dataLoad!.selectAndLoadFIlesToDataSources()
    }

    override init() {
        super.init()
        updateScreenDimensions(screenSize, string: &screenDimensions)
    }
}
