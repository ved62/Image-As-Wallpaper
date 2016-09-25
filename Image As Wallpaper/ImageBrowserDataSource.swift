//
//  ImageBrowserDataSource.swift
//  IAW10
//
//  Created by Владислав Эдуардович Дембский on 02.05.15.
//  Copyright (c) 2015 Vladislav Dembskiy. All rights reserved.
//

import Quartz

final class ImageBrowserDataSource: NSObject {
    var imageArray: [ImageBrowserItem] = []

    override func numberOfItems(inImageBrowser aBrowser: IKImageBrowserView!) -> Int {
        return imageArray.count
    }

    override func imageBrowser(_ aBrowser: IKImageBrowserView!,
        itemAt index: Int) -> Any! {
        return imageArray[index]
    }
}
