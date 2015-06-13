//
//  DataLoad.swift
//  Image As Wallpaper
//
//  Created by Владислав Эдуардович Дембский on 13.06.15.
//  Copyright (c) 2015 Vladislav Dembskiy. All rights reserved.
//

import AppKit

class DataLoad: NSObject {

    func selectAndLoadFIlesToDataSources() {

        var imageURLs: [NSURL] = []
        let fileDialog = NSOpenPanel()
        fileDialog.title = "Select Image Files and Directories"
        fileDialog.allowedFileTypes = NSImage.imageTypes()
        fileDialog.allowsMultipleSelection=true
        fileDialog.canChooseDirectories=true
        fileDialog.canChooseFiles=true
        if fileDialog.runModal() == NSFileHandlingPanelOKButton {
            imageURLs = fileDialog.URLs as! [NSURL]
            }
        if imageURLs.isEmpty {
            return
        }
        
    }

}
