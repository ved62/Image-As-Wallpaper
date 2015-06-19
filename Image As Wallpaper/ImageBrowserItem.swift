//
//  ImageBrowserItem.swift
//  IAW10
//
//  Created by Владислав Эдуардович Дембский on 02.05.15.
//  Copyright (c) 2015 Vladislav Dembskiy. All rights reserved.
//

import Quartz

final class ImageBrowserItem: NSObject {
    let url: NSURL
    let size: CGSize

    override func imageUID() -> String! {
        return url.path
    }

    override func imageRepresentationType() -> String! {
        return IKImageBrowserNSURLRepresentationType
    }

    override func imageRepresentation() -> AnyObject! {
        return url
    }

    override func imageTitle() -> String! {
        return url.lastPathComponent
    }

    override func imageSubtitle() -> String! {
        var properties = "\(Int(size.width))x\(Int(size.height)) "
        return properties.stringByAppendingFormat("%1.2f", size.width / size.height)
    }

    init(_ imageURL: NSURL,_ imageSize: CGSize) {
        url = imageURL
        size = imageSize
    }
}
