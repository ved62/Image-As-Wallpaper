//
//  ImageBrowserDataSource.swift
//  IAW10
//
//  Created by Владислав Эдуардович Дембский on 02.05.15.
//  Copyright (c) 2015 Vladislav Dembskiy. All rights reserved.
//

import Quartz

final class ImageBrowserDataSource: NSObject {
    private var imageArray: [ImageBrowserItem] = []

    override func numberOfItemsInImageBrowser(aBrowser: IKImageBrowserView!) -> Int {
        return imageArray.count
    }

    override func imageBrowser(aBrowser: IKImageBrowserView!,
        itemAtIndex index: Int) -> AnyObject! {
        return imageArray[index]
    }

    func append(imageURL: NSURL) {
        imageArray.append(ImageBrowserItem(imageURL))
    }

    func removeObjectImageArrayAtIndex(index: Int) {
        imageArray.removeAtIndex(index)
    }

    func removeAll() {
        imageArray.removeAll(keepCapacity: false)
    }

    func addArray(array: [ImageBrowserItem]) {
        imageArray += array
    }
}
