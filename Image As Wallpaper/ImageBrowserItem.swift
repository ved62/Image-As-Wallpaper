//
//  ImageBrowserItem.swift
//  IAW10
//
//  Created by Владислав Эдуардович Дембский on 02.05.15.
//  Copyright (c) 2015 Vladislav Dembskiy. All rights reserved.
//

import Quartz

final class ImageBrowserItem: NSObject {
    private let url: NSURL

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
        var properties: String  // width, height and aspect ratio
        if let image = CIImage(contentsOfURL: url) {
            let size = image.extent().size
            properties = "\(Int(size.width))x\(Int(size.height)) "
            return properties.stringByAppendingFormat("%1.2f", size.width / size.height)
        }
        return "Undefined"
    }

    init(_ imageURL: NSURL) {
        url = imageURL
    }
}
