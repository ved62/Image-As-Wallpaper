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

func isImageFile(url: NSURL) -> Bool {
    let ext = url.pathExtension
    if ext != nil {
        let allowedFileTypes = NSImage.imageTypes() as! [String]
        let typeForExt = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, ext, "public.image").takeRetainedValue() as String

        if (find(allowedFileTypes, typeForExt) != nil) {
            return true
        }
    }
    return false
}

func fileOperationFailureAlert(error: NSError) {
    let failureAlert = NSAlert(error: error)
    failureAlert.alertStyle = NSAlertStyle.CriticalAlertStyle
    failureAlert.runModal()
}

func deleteFile (url: NSURL) -> Bool {
    let fileManager = NSFileManager.defaultManager()
    var deleteError: NSError?

    if !fileManager.trashItemAtURL(url, resultingItemURL: nil, error: &deleteError) {
        fileOperationFailureAlert(deleteError!)
        return false
    }
    return true
}

func moveFile(source: NSURL, destination: NSURL) -> Bool {
    let fileManager = NSFileManager.defaultManager()
    var moveError: NSError?
    if !fileManager.moveItemAtURL(source, toURL: destination, error: &moveError) {
        fileOperationFailureAlert(moveError!)
        return false
    }
    return true
}

func checkImageAganstScreen(imageURL: NSURL, screenSize: CGSize, deviation: CGFloat) -> Bool {
    let imageSize: CGSize
    if let image = CIImage(contentsOfURL: imageURL) {
        imageSize = image.extent().size
    } else {
        return false
    }
    //first check if any of image dimensions are smaller when the screen dimensions
    if (imageSize.width < (screenSize.width * deviation)) ||
        (imageSize.height < (screenSize.height * deviation)) {
        return false
    }
    // image is big enough. Lets check its aspect ratio
    let imageAspect = imageSize.width / imageSize.height
    let screenAspect = screenSize.width / screenSize.height
    let aspectDifference = imageAspect < screenAspect ? imageAspect / screenAspect : screenAspect / imageAspect // to be less or equal 1.0
    if  aspectDifference < deviation {
        return false
    }
    return true // image is good to be a wallpaper
}