//
//  DataController.swift
//  Image As Wallpaper
//
//  Created by Владислав Эдуардович Дембский on 14.06.15.
//  Copyright (c) 2015 Vladislav Dembskiy. All rights reserved.
//

import Quartz
import Foundation

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

    fileprivate dynamic var zoomValue = 0.49 {
        didSet {
            goodImageView.setZoomValue(zoomSlider.floatValue)
            badImageView.setZoomValue(zoomSlider.floatValue)
        }
    }
    fileprivate lazy var goodDataSource = ImageBrowserDataSource()
    fileprivate lazy var badDataSource = ImageBrowserDataSource()

    fileprivate func checkImageAganstScreen(_ imageURL: URL, _ size: CGSize?) -> (Bool, CGSize) {
        var imageSize: CGSize
        if (size != nil) {
            imageSize = size!
        } else {
            if let image = CIImage(contentsOf: imageURL) {
                imageSize = image.extent.size
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

    fileprivate func isImageFile(_ url: URL) -> Bool {
        let allowedFileTypes = NSImage.imageTypes()
        let ext: CFString? = url.pathExtension as CFString?
        if ext != nil {
            //            let cfExt: CFString = ext!
            let typeForExt = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension,
                ext!, "public.image" as CFString?)!.takeRetainedValue() as String
            if (allowedFileTypes.index(of: typeForExt) != nil) {
                return true }
        }

        return false
    }

    fileprivate func fileOperationFailureAlert(_ error: NSError) {
        let failureAlert = NSAlert(error: error)
        failureAlert.alertStyle = NSAlertStyle.critical
        failureAlert.runModal()
    }

    fileprivate func checkFileExistsAndIsDirectory (_ url: URL) -> (Bool, Bool) {
        var isDir: ObjCBool = ObjCBool(false)
        let fileManager = FileManager.default
        let existence = fileManager.fileExists(atPath: url.path, isDirectory: &isDir)
        var dir: Bool = false
        if isDir.boolValue {
            dir = true
        }
        return (existence, dir)
    }

    fileprivate func processFile(_ url: URL) {
        if isImageFile(url) {
            let (good,size) = checkImageAganstScreen(url, nil)
            if good {
                goodDataSource.imageArray.append(ImageBrowserItem(url,size))
            } else {
                badDataSource.imageArray.append(ImageBrowserItem(url,size))
            }
        }
    }

    fileprivate lazy var aQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "File Processing Queue"
        queue.maxConcurrentOperationCount = 1
        return queue
    }()

    fileprivate func processDir(_ dirURL: URL) {
        let fileManager = FileManager.default
        let options: FileManager.DirectoryEnumerationOptions =
            [.skipsHiddenFiles, .skipsPackageDescendants]
        let handler = {
            (url:URL!,error:Error!) -> Bool in
            self.fileOperationFailureAlert(error as NSError)
            return true
        }
        let fileEnumerator = fileManager.enumerator(at: dirURL, includingPropertiesForKeys: nil,
            options: options,
            errorHandler: handler)
        while let url = fileEnumerator?.nextObject() as? URL {
            let (fileExists, isDir) = checkFileExistsAndIsDirectory(url)
            if fileExists && (isDir == false) {
                aQueue.addOperation({self.processFile(url)})
            }
        }
    }

    fileprivate func fillDataSources(_ imageURLs: [URL]) {
        for url in imageURLs {
            let (fileExists, isDir) = checkFileExistsAndIsDirectory(url)
            if fileExists {
                if isDir {
                    aQueue.addOperation({self.processDir(url)})
                } else {
                    aQueue.addOperation({self.processFile(url)})
                }
            }
        }
        aQueue.waitUntilAllOperationsAreFinished()
    }

    fileprivate func updateCountsInLabels() {
        goodTabViewItem.label = "Good: \(goodDataSource.imageArray.count)"
        badTabViewItem.label = "Bad: \(badDataSource.imageArray.count)"
        tabView.needsDisplay = true
    }

    fileprivate func displayImagesAndCounts() {
        updateCountsInLabels()
        goodImageView.reloadData()
        badImageView.reloadData()
    }

    func selectFiles() {
        var imageURLs: [URL] = []
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
            imageURLs = fileDialog.urls 
        }
        if imageURLs.isEmpty { return }
        goodDataSource.imageArray = []
        badDataSource.imageArray = []
        appController.progressIndicator.startAnimation(self)
        fillDataSources(imageURLs)
        appController.progressIndicator.stopAnimation(self)
        goodImageView.dataSource = goodDataSource
        badImageView.dataSource = badDataSource
        displayImagesAndCounts()
        zoomLabel.isHidden = false
        zoomSlider.isHidden = false
        deleteButton.isHidden = false
        moveButton.isHidden = false
    }

    fileprivate func checkAndUpdateDataSource(_ dataSource: ImageBrowserDataSource,  keep: Bool, filteredArray: inout [ImageBrowserItem]) {
        var item: ImageBrowserItem
        var index = dataSource.imageArray.count - 1
        while index >= 0 {
            item = dataSource.imageArray[index]
            let (result, _) = checkImageAganstScreen(item.url as URL, item.size)
            if result != keep {
                filteredArray.append(item)
                dataSource.imageArray.remove(at: index)
            }
            index -= 1
        }
    }

    func sortImagesInDataSources() {
        if goodDataSource.imageArray.isEmpty &&
            badDataSource.imageArray.isEmpty { return }
        var badTempArray: [ImageBrowserItem] = []
        var goodTempArray: [ImageBrowserItem] = []
        let aQueue = OperationQueue()
        // process existing data sources in paralel
        aQueue.addOperation({
            // save images to be moved to the Bad Data Source
            // and remove them from Good data source
            self.checkAndUpdateDataSource(self.goodDataSource, keep: true, filteredArray: &badTempArray)
        })
        aQueue.addOperation({
            // save images to be moved to the Good Data Source
            // and remove them from Bad data source
            self.checkAndUpdateDataSource(self.badDataSource, keep: false, filteredArray: &goodTempArray)
        })
        aQueue.waitUntilAllOperationsAreFinished()
        goodDataSource.imageArray += goodTempArray
        badDataSource.imageArray += badTempArray
        displayImagesAndCounts()
    }

    fileprivate func getSelectedBrowser() -> (IKImageBrowserView,  IndexSet) {
        let browser = tabView.selectedTabViewItem == goodTabViewItem ? goodImageView : badImageView
        return (browser!,browser!.selectionIndexes())
    }
    
    fileprivate func getDestinationPath() -> [URL] {
        let movePanel = NSOpenPanel()
        movePanel.message = "Select Destination"
        movePanel.prompt = "Choose"
        movePanel.canCreateDirectories = true
        movePanel.canChooseDirectories = true
        movePanel.canChooseFiles = false
        movePanel.allowsMultipleSelection=false
        if movePanel.runModal() == NSFileHandlingPanelOKButton {
            return movePanel.urls 
        }
        return []
    }

    fileprivate func moveFile(_ source: URL, _ destination: URL) -> Bool {
        let fileManager = FileManager.default
        var moveError: NSError?
        do {
            try fileManager.moveItem(at: source, to: destination)
        } catch let error as NSError {
            moveError = error
            fileOperationFailureAlert(moveError!)
            return false
        }
        return true
    }

    @IBAction func moveSelectedFiles(_ sender: AnyObject) {
        let (browserView, indexes) = getSelectedBrowser()
        if indexes.count == 0 { return }
        let destinationPath = getDestinationPath()
        if destinationPath.isEmpty {return}
        let dataSource = browserView.dataSource as! ImageBrowserDataSource
        // indexes are in accending order so we should remove from the end
        for index in indexes.reversed()
/*        for var index = indexes.lastIndex;
            index != NSNotFound;
            index = indexes.indexLessThanIndex(index) */ {
                let sourceURL = dataSource.imageArray[index].url
                let fileName = sourceURL.lastPathComponent.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlPathAllowed)!
                let destinationURL = URL(string: fileName,relativeTo: destinationPath[0])!
                if sourceURL as URL != destinationURL {
                    if moveFile(sourceURL as URL, destinationURL) {
                        dataSource.imageArray.remove(at: index)
                    }
                }
        }
        browserView.reloadData()
        updateCountsInLabels()
    }

    fileprivate func deleteFile (_ url: URL) -> Bool {
        let fileManager = FileManager.default
        var deleteError: NSError?
        do {
            try fileManager.trashItem(at: url, resultingItemURL: nil)
        } catch let error as NSError {
            deleteError = error
            fileOperationFailureAlert(deleteError!)
            return false
        }
        return true
    }

    @IBAction func deleteSelectedFiles(_ sender: AnyObject) {
        let (browserView, indexes) = getSelectedBrowser()
        if indexes.count == 0 { return }

        let warningAlert = NSAlert()
        warningAlert.alertStyle = NSAlertStyle.warning
        var messageText = "\(indexes.count) file"
        if indexes.count > 1 { messageText += "s" }
        messageText += " will be moved to Trash!"
        warningAlert.messageText = messageText
        warningAlert.runModal()

        let dataSource = browserView.dataSource as! ImageBrowserDataSource
        // indexes are in accending order so we should remove from the end
        for index in indexes.reversed()
        /*        for var index = indexes.lastIndex;
            index != NSNotFound;
            index = indexes.indexLessThanIndex(index) */ {
                if deleteFile(dataSource.imageArray[index].url as URL) {
                    dataSource.imageArray.remove(at: index)
                }
        }
        browserView.reloadData()
        updateCountsInLabels()
    }

}
