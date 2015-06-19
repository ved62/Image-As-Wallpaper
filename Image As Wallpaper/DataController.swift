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

    private func checkImageAganstScreen(imageURL: NSURL, _ size: CGSize?) -> (Bool, CGSize) {
        var imageSize: CGSize
        if (size != nil) {
            imageSize = size!
        } else {
            if let image = CIImage(contentsOfURL: imageURL) {
                imageSize = image.extent().size
            } else { fatalError("Unable to obtain image from \(imageURL.path)") }
        }

        //first check if any of image dimensions are smaller when the screen dimensions
        let screenSize = appController.screenSize
        let conformityLevel = appController.conformityLevel
        if (Double(imageSize.width) < (Double(screenSize.width) * conformityLevel)) ||
            (Double(imageSize.height) < (Double(screenSize.height) * conformityLevel))
        { return (false, imageSize) }
        // image is big enough. Lets check its aspect ratio
        let imageAspect = imageSize.width / imageSize.height
        let screenAspect = screenSize.width / screenSize.height
        let aspectDifference = imageAspect < screenAspect ? imageAspect / screenAspect
            : screenAspect / imageAspect // to be less or equal 1.0
        if  Double(aspectDifference) < conformityLevel { return (false, imageSize) }
        return (true, imageSize) // image is good to be a wallpaper
    }

    private func isImageFile(url: NSURL) -> Bool {
        let allowedFileTypes = NSImage.imageTypes() as! [String]
        if let ext = url.pathExtension {
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

    private func checkFileExistsAndIsDirectory (url: NSURL) -> (Bool, Bool) {
        var isDir: ObjCBool = false
        let fileManager = NSFileManager.defaultManager()
        let existence = fileManager.fileExistsAtPath(url.path!, isDirectory: &isDir)
        return (existence, Bool(isDir))
    }

    private func processDir(dirURL: NSURL) {
        let fileManager = NSFileManager.defaultManager()
        let options: NSDirectoryEnumerationOptions =
            .SkipsHiddenFiles | .SkipsPackageDescendants
        let handler = {
            (url:NSURL!,error:NSError!) -> Bool in
            self.fileOperationFailureAlert(error)
            return true
        }
        let fileEnumerator = fileManager.enumeratorAtURL(dirURL, includingPropertiesForKeys: nil,
            options: options,
            errorHandler: handler)
        while let url = fileEnumerator?.nextObject() as? NSURL {
            let (fileExists, isDir) = checkFileExistsAndIsDirectory(url)
            if fileExists && !isDir {
                processFile(url)
            }
        }
    }

    private func processFile(url: NSURL) {
        if !isImageFile(url) {
            return }
        let (good,size) = checkImageAganstScreen(url, nil)
        if good {
            goodDataSource.imageArray.append(ImageBrowserItem(url, size))
        } else {
            badDataSource.imageArray.append(ImageBrowserItem(url, size))
        }
    }

    private func fillDataSources(imageURLs: [NSURL]) {
        var urlList = imageURLs
        while !urlList.isEmpty {
            let url = urlList.removeLast()
            let (fileExists, isDir) = checkFileExistsAndIsDirectory(url)
            if fileExists {
                if isDir {
                        processDir(url)
                } else {
                        processFile(url)
                }
            }
        }
    }

    private func updateCountsInLabels() {
        tabView.tabViewType = .NoTabsBezelBorder
        goodTabViewItem.label = "Good: \(goodDataSource.imageArray.count)"
        badTabViewItem.label = "Bad: \(badDataSource.imageArray.count)"
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
        appController.progressIndicator.startAnimation(self)
        goodDataSource.imageArray = []
        badDataSource.imageArray = []
        fillDataSources(imageURLs)
        goodImageView.setDataSource(goodDataSource)
        badImageView.setDataSource(badDataSource)
        displayImagesAndCounts()
        appController.progressIndicator.stopAnimation(self)
    }

    private func checkAndUpdateDataSource(dataSource: ImageBrowserDataSource,  keep: Bool, inout filteredArray: [ImageBrowserItem]) {
        var item: ImageBrowserItem
        var index = dataSource.imageArray.count - 1
        while index >= 0 {
            item = dataSource.imageArray[index]
            let (result, _) = checkImageAganstScreen(item.url, item.size)
            if result != keep {
                filteredArray.append(item)
                dataSource.imageArray.removeAtIndex(index)
            }
            --index
        }
    }

    func sortImagesInDataSources() {
        if goodDataSource.imageArray.isEmpty &&
            badDataSource.imageArray.isEmpty { return }
        var badTempArray: [ImageBrowserItem] = []
        var goodTempArray: [ImageBrowserItem] = []
        let aQueue = NSOperationQueue()
        // process existing data sources in paralel
        aQueue.addOperationWithBlock({
            // save images to be moved to the Bad Data Source
            // and remove them from Good data source
            self.checkAndUpdateDataSource(self.goodDataSource, keep: true, filteredArray: &badTempArray)
        })
        aQueue.addOperationWithBlock({
            // save images to be moved to the Good Data Source
            // and remove them from Bad data source
            self.checkAndUpdateDataSource(self.badDataSource, keep: false, filteredArray: &goodTempArray)
        })
        aQueue.waitUntilAllOperationsAreFinished()
        goodDataSource.imageArray += goodTempArray
        badDataSource.imageArray += badTempArray
        displayImagesAndCounts()
    }
}
