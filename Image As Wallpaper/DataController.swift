//
//  DataController.swift
//  Image As Wallpaper
//
//  Created by Владислав Эдуардович Дембский on 14.06.15.
//  Copyright (c) 2015 Vladislav Dembskiy. All rights reserved.
//

import Quartz

@IBDesignable
final class DataController: NSObject {

    @IBOutlet weak var appController: AppController!
    @IBOutlet weak var tabView: NSTabView!
    @IBOutlet weak var goodTabViewItem: NSTabViewItem!
    @IBOutlet weak var badTabViewItem: NSTabViewItem!
    @IBOutlet weak var goodImageView: IKImageBrowserView!
    @IBOutlet weak var badImageView: IKImageBrowserView!
    
    private lazy var goodDataSource = ImageBrowserDataSource()
    private lazy var badDataSource = ImageBrowserDataSource()

    private func checkImageAganstScreen(imageURL: NSURL) -> Bool {
        let imageSize: CGSize
        if let image = CIImage(contentsOfURL: imageURL) {
            imageSize = image.extent().size
        } else { return false }

        //first check if any of image dimensions are smaller when the screen dimensions
        let screenSize = appController.screenSize
        let conformityLevel = appController.conformityLevel
        if (Double(imageSize.width) < (Double(screenSize.width) * conformityLevel)) ||
            (Double(imageSize.height) < (Double(screenSize.height) * conformityLevel))
        { return false }
        // image is big enough. Lets check its aspect ratio
        let imageAspect = imageSize.width / imageSize.height
        let screenAspect = screenSize.width / screenSize.height
        let aspectDifference = imageAspect < screenAspect ? imageAspect / screenAspect : screenAspect / imageAspect // to be less or equal 1.0
        if  Double(aspectDifference) < conformityLevel { return false }
        return true // image is good to be a wallpaper
    }

    private lazy var allowedFileTypes = NSImage.imageTypes() as! [String]

    private func isImageFile(url: NSURL) -> Bool {
        let ext = url.pathExtension
        if ext != nil {
            let typeForExt = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension,
                ext, "public.image").takeRetainedValue() as String
            if (find(allowedFileTypes, typeForExt) != nil) {
                return true }
        }
        return false
    }

    private func fileOperationFailureAlert(error: NSError) {
        let failureAlert = NSAlert(error: error)
        failureAlert.alertStyle = NSAlertStyle.CriticalAlertStyle
        failureAlert.runModal()
    }

    private lazy var fileManager = NSFileManager.defaultManager()

    private func processDirectory(dirURL: NSURL) {
        var readDirError: NSError?
        var contentOfDir: [NSURL]?

        contentOfDir = fileManager.contentsOfDirectoryAtURL(dirURL,
            includingPropertiesForKeys: nil,
            options: .SkipsHiddenFiles, error: &readDirError)
            as? [NSURL]

        if (contentOfDir != nil) {
            if !contentOfDir!.isEmpty { // recursion!
                fillDataSources(contentOfDir!)
            }
        } else {
                fileOperationFailureAlert(readDirError!)
            }
    }

    private func processFile(imageURL: NSURL) {
        if isImageFile(imageURL) {
            if checkImageAganstScreen(imageURL)
            { goodDataSource.append(imageURL) }
            else { badDataSource.append(imageURL) }
        }
    }

    private func fillDataSources(imageURLs: [NSURL]) {
        var isDir: ObjCBool = false

        for imageURL in imageURLs {
            if fileManager.fileExistsAtPath(imageURL.path!, isDirectory: &isDir) {
                if isDir {
                    processDirectory(imageURL)
                } else {
                    processFile(imageURL)
                    }
                }
        }
    }

    private func updateCountsInLabels() {
        tabView.tabViewType = .NoTabsBezelBorder
        goodTabViewItem.label = "Good: \(goodDataSource.numberOfItemsInImageBrowser(goodImageView))"
        badTabViewItem.label = "Bad: \(badDataSource.numberOfItemsInImageBrowser(badImageView))"
        tabView.tabViewType = .TopTabsBezelBorder
    }

    private func displayImagesAndCounts() {
        updateCountsInLabels()
        goodImageView.reloadData()
        badImageView.reloadData()

    }

    func selectFiles() {
        var imageURLs: [NSURL] = []
        let fileDialog = NSOpenPanel()
        var title = "Select Image Files"
        if appController.lookInSubDirs == 1 {
            title += "  and Directories"
            fileDialog.canChooseDirectories=true
        }
        fileDialog.title = title
        fileDialog.allowedFileTypes = NSImage.imageTypes()
        fileDialog.allowsMultipleSelection=true
        fileDialog.canChooseFiles=true
        if fileDialog.runModal() == NSFileHandlingPanelOKButton {
            imageURLs = fileDialog.URLs as! [NSURL]
        }
        if imageURLs.isEmpty { return }
        goodDataSource.removeAll()
        badDataSource.removeAll()
        fillDataSources(imageURLs)
        goodImageView.setDataSource(goodDataSource)
        badImageView.setDataSource(badDataSource)
        displayImagesAndCounts()
    }

    private func checkAndUpdateDataSource(dataSource: ImageBrowserDataSource, imageView: IKImageBrowserView, keep: Bool, inout filteredArray: [ImageBrowserItem]) {
        let screenSize = appController.screenSize
        var item: ImageBrowserItem
        var index = dataSource.numberOfItemsInImageBrowser(imageView) - 1
        while index >= 0 {
            item = dataSource.imageBrowser(imageView,itemAtIndex: index) as! ImageBrowserItem
            if checkImageAganstScreen(item.imageRepresentation() as! NSURL) != keep {
                filteredArray.append(item)
                dataSource.removeObjectImageArrayAtIndex(index)
            }
            --index
        }
    }

    func sortImagesInDataSources() {
        if goodDataSource.numberOfItemsInImageBrowser(goodImageView) == 0 &&
            badDataSource.numberOfItemsInImageBrowser(badImageView) == 0 {
                return
        }
        
        var badTempArray: [ImageBrowserItem] = []
        var goodTempArray: [ImageBrowserItem] = []
        let aQueue = NSOperationQueue()

        // process existing data sources in parrallel
        aQueue.addOperationWithBlock({
            // save images to be moved to the Bad Data Source
            // and remove them from Good data source
            self.checkAndUpdateDataSource(self.goodDataSource, imageView: self.goodImageView, keep: true, filteredArray: &badTempArray)
        })

        aQueue.addOperationWithBlock({
            // save images to be moved to the Good Data Source
            // and remove them from Bad data source
            self.checkAndUpdateDataSource(self.badDataSource, imageView: self.badImageView, keep: false, filteredArray: &goodTempArray)
        })

        aQueue.waitUntilAllOperationsAreFinished()

        goodDataSource.addArray(goodTempArray)
        badDataSource.addArray(badTempArray)
        displayImagesAndCounts()
    }

}
