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
    @IBOutlet weak var zoomLabel: NSTextField!
    @IBOutlet weak var zoomSlider: NSSlider!
    @IBOutlet weak var moveButton: NSButton!
    @IBOutlet weak var deleteButton: NSButton!

    private dynamic var zoomValue = 0.49 {
        didSet {
            goodImageView.setZoomValue(zoomSlider.floatValue)
            badImageView.setZoomValue(zoomSlider.floatValue)
        }
    }
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

    private func processFile(url: NSURL) {
        if isImageFile(url) {
            let (good,size) = checkImageAganstScreen(url, nil)
            if good {
                goodDataSource.imageArray.append(ImageBrowserItem(url,size))
            } else {
                badDataSource.imageArray.append(ImageBrowserItem(url,size))
            }
        }
    }

    private lazy var aQueue: NSOperationQueue = {
        let queue = NSOperationQueue()
        queue.name = "File Processing Queue"
        queue.maxConcurrentOperationCount = 1
        return queue
    }()

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
                aQueue.addOperationWithBlock({self.processFile(url)})
            }
        }
    }

    private func fillDataSources(imageURLs: [NSURL]) {
        for url in imageURLs {
            let (fileExists, isDir) = checkFileExistsAndIsDirectory(url)
            if fileExists {
                if isDir {
                    aQueue.addOperationWithBlock({self.processDir(url)})
                } else {
                    aQueue.addOperationWithBlock({self.processFile(url)})
                }
            }
        }
        aQueue.waitUntilAllOperationsAreFinished()
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
        goodDataSource.imageArray = []
        badDataSource.imageArray = []
        appController.progressIndicator.startAnimation(self)
        fillDataSources(imageURLs)
        appController.progressIndicator.stopAnimation(self)
        goodImageView.setDataSource(goodDataSource)
        badImageView.setDataSource(badDataSource)
        displayImagesAndCounts()
        zoomLabel.hidden = false
        zoomSlider.hidden = false
        deleteButton.hidden = false
        moveButton.hidden = false
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

    private func getSelectedBrowser() -> (IKImageBrowserView,  NSIndexSet) {
        let browser = tabView.selectedTabViewItem == goodTabViewItem ? goodImageView : badImageView
        return (browser,browser.selectionIndexes())
    }
    
    private func getDestinationPath() -> [NSURL] {
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

    private func moveFile(source: NSURL, _ destination: NSURL) -> Bool {
        let fileManager = NSFileManager.defaultManager()
        var moveError: NSError?
        if !fileManager.moveItemAtURL(source, toURL: destination, error: &moveError) {
            fileOperationFailureAlert(moveError!)
            return false
        }
        return true
    }

    @IBAction func moveSelectedFiles(sender: NSButton) {
        let (browserView, indexes) = getSelectedBrowser()
        if indexes.count == 0 { return }
        let destinationPath = getDestinationPath()
        if destinationPath.isEmpty {return}
        let dataSource = browserView.dataSource() as! ImageBrowserDataSource
        // indexes are in accending order so we should remove from the end
        for var index = indexes.lastIndex;
            index != NSNotFound;
            index = indexes.indexLessThanIndex(index) {
                let sourceURL = dataSource.imageArray[index].url
                let fileName = sourceURL.path!.lastPathComponent.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!
                let destinationURL = NSURL(string: fileName,relativeToURL: destinationPath[0])!
                if sourceURL != destinationURL {
                    if moveFile(sourceURL, destinationURL) {
                        dataSource.imageArray.removeAtIndex(index)
                    }
                }
        }
        browserView.reloadData()
        updateCountsInLabels()
    }

    private func deleteFile (url: NSURL) -> Bool {
        let fileManager = NSFileManager.defaultManager()
        var deleteError: NSError?
        if !fileManager.trashItemAtURL(url, resultingItemURL: nil,
            error: &deleteError) {
            fileOperationFailureAlert(deleteError!)
            return false
        }
        return true
    }

    @IBAction func deleteSelectedFiles(sender: NSButton) {
        let (browserView, indexes) = getSelectedBrowser()
        if indexes.count == 0 { return }

        let warningAlert = NSAlert()
        warningAlert.alertStyle = NSAlertStyle.WarningAlertStyle
        var messageText = "\(indexes.count) file"
        if indexes.count > 1 { messageText += "s" }
        messageText += " will be moved to Trash!"
        warningAlert.messageText = messageText
        warningAlert.runModal()

        let dataSource = browserView.dataSource() as! ImageBrowserDataSource
        // indexes are in accending order so we should remove from the end
        for var index = indexes.lastIndex;
            index != NSNotFound;
            index = indexes.indexLessThanIndex(index) {
                if deleteFile(dataSource.imageArray[index].url) {
                    dataSource.imageArray.removeAtIndex(index)
                }
        }
        browserView.reloadData()
        updateCountsInLabels()
    }

}
