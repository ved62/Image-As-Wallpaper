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
final class AppController: NSObject {
    
    private dynamic var screenDimensions = String()

    private func sortWithIndication() {
        progressIndicator.startAnimation(self)
        dataController.sortImagesInDataSources()
        progressIndicator.stopAnimation(self)
    }

    dynamic var conformityLevel: Double = 0.98 {
        didSet {
            sortWithIndication()
        }
    }

    dynamic var lookInSubDirs: Int = 1

    var screenSize: CGSize {
        get { return NSScreen.mainScreen()!.frame.size }
        set {
            updateScreenDimensions(newValue, string: &screenDimensions)
            sortWithIndication()
        }
    }
    
    @IBOutlet weak var dataController: DataController!
    @IBOutlet weak var progressIndicator: NSProgressIndicator!

    private func updateScreenDimensions(size: CGSize, inout string: String) {
        string = "Screen Dimensions: \(Int(size.width)) x \(Int(size.height)) "
        string = string.stringByAppendingFormat(" Aspect ratio: %1.2f", size.width / size.height)
    }
    
    @IBAction func selectFiles(sender: AnyObject) {
        dataController.selectFiles()
    }

    override init() {
        super.init()
        updateScreenDimensions(screenSize, string: &screenDimensions)
    }
}
