//
//  SupportFunctions.swift
//  IAW 10
//
//  Created by Владислав Эдуардович Дембский on 31.05.15.
//  Copyright (c) 2015 Vladislav Dembskiy. All rights reserved.
//

import AppKit

func getDestinationPath() -> [NSURL] {
    let movePanel = NSOpenPanel()
    movePanel.message = "Select Destination"
    movePanel.prompt = "Choose"
    movePanel.canCreateDirectories = true
    movePanel.canChooseDirectories = true
    movePanel.canChooseFiles = false
    movePanel.allowsMultipleSelection=false
    if movePanel.runModal() == NSFileHandlingPanelOKButton {
        return movePanel.URLs as! [NSURL]
    }
    return []
}

func deleteFile (url: NSURL) -> Bool {
    let fileManager = NSFileManager.defaultManager()
    var deleteError: NSError?

    if !fileManager.trashItemAtURL(url, resultingItemURL: nil, error: &deleteError) {
        //        fileOperationFailureAlert(deleteError!)
        return false
    }
    return true
}

func moveFile(source: NSURL, destination: NSURL) -> Bool {
    let fileManager = NSFileManager.defaultManager()
    var moveError: NSError?
    if !fileManager.moveItemAtURL(source, toURL: destination, error: &moveError) {
        //    fileOperationFailureAlert(moveError!)
        return false
    }
    return true
}

