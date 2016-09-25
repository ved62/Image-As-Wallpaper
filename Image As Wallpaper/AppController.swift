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
    
    fileprivate dynamic var screenDimensions = String()

    fileprivate func sortWithIndication() {
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
        get { return NSScreen.main()!.frame.size }
        set {
            updateScreenDimensions(newValue, string: &screenDimensions)
            sortWithIndication()
        }
    }
    
    @IBOutlet weak var dataController: DataController!
    @IBOutlet weak var progressIndicator: NSProgressIndicator!

    fileprivate func updateScreenDimensions(_ size: CGSize, string: inout String) {
        string = "Screen Dimensions: \(Int(size.width)) x \(Int(size.height)) "
        string = string.appendingFormat(" Aspect ratio: %1.2f", size.width / size.height)
    }
    
    @IBAction func selectFiles(_ sender: AnyObject) {
        dataController.selectFiles()
    }

    override init() {
        super.init()
        updateScreenDimensions(screenSize, string: &screenDimensions)
    }
}
