//
//  Images.swift
//  cmkdown
//
//  Copyright © 2025 Andrey Sobolev. All rights reserved.
//
//  Licensed under the Eclipse Public License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License. You may
//  obtain a copy of the License at https://www.eclipse.org/legal/epl-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//
//  See the License for the specific language governing permissions and
//  limitations under the License.

import Foundation

import Cocoa

public class CachedImage {
    var image: NSImage
    var size: CGSize
    
    init( image: NSImage, size: CGSize) {
        self.image = image
        self.size = size
    }
}

/**
 Cache images inside items with required processing.
 */
open class ImageProvider {
    let scaleFactor: CGFloat
    var images: [String:CachedImage] = [:]
    
    init(_ scaleFactor: CGFloat ) {
        self.scaleFactor = scaleFactor
    }
    
    public func resolveImage( name: String ) -> CachedImage? {
        // Not implemented by default
        return nil
    }
    
    // path is named and style combimned parsed from @(name|style)
    public func resolveImage(path: String ) -> (NSImage?, CGRect?) {
        // If image already cached.
        var image: CachedImage? = self.images[path]
        if image != nil {
            return (image!.image, CGRect(origin: CGPoint(x:0, y:0), size: image!.size))
        }
        var name = path
        var style = ""
        if let pos = path.firstIndex(of: "|") {
            name = String(path.prefix(upTo: pos))
            style = String(path.suffix(from: path.index(after: pos)))
        }
        
        if image == nil {
            // Retrieve image data from properties, if not cached
            image = self.resolveImage(name: name)
        }
        
        if let img = image {
            var width = img.size.width
            var height = img.size.height
            if style != "" {
                var widthStr = style
                var heightStr = ""
                // We need to apply style is applicable
                if let xPos = style.firstIndex(of: "x") {
                    widthStr = String(style.prefix(upTo: xPos)).trimmingCharacters(in: .whitespacesAndNewlines)
                    heightStr = String(style.suffix(from: style.index(after: xPos))).trimmingCharacters(in: .whitespacesAndNewlines)
                }
                
                // This is aspect scale.
                if !widthStr.isEmpty, let newWidth = Int(widthStr, radix: 10) {
                    width = CGFloat(newWidth)
                }
                if !heightStr.isEmpty, let newHeight = Int(heightStr, radix: 10) {
                    height = CGFloat(newHeight)
                }
                
                if widthStr.isEmpty || heightStr.isEmpty {
                    let r = getMaxRect(maxWidth: width, maxHeight: height, imageWidth: img.size.width, imageHeight: img.size.height)
                    width = r.width
                    height = r.height
                }
            }
            img.image = rescaleImage(img.image, width * self.scaleFactor, height * self.scaleFactor)
            img.size = CGSize(width: width, height: height)
            
            //            Swift.debugPrint("image size:\(image?.size) and \(width):\(height)")
            self.images[path] = image
            return (img.image, CGRect(x: 0, y: 0, width: width, height: height))
        }
        
        return (nil, nil)
    }
}

func rescaleImage(_ image: NSImage, _ width: CGFloat, _ height: CGFloat) -> NSImage {
    let newSize = CGSize(width: width, height: height)
    if let bitmapRep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: Int(newSize.width), pixelsHigh: Int(newSize.height),
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .calibratedRGB, bytesPerRow: 0, bitsPerPixel: 0
        ) {
        bitmapRep.size = newSize
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmapRep)
        image.draw(in: NSRect(x: 0, y: 0, width: newSize.width, height: newSize.height), from: .zero, operation: .copy, fraction: 1.0)
        NSGraphicsContext.restoreGraphicsState()
        
        let resizedImage = NSImage(size: newSize)
        resizedImage.addRepresentation(bitmapRep)
        return resizedImage
    }
    return image
}

public func getMaxRect( maxWidth: CGFloat, maxHeight: CGFloat, imageWidth: CGFloat, imageHeight: CGFloat) -> NSRect {
    // Get ratio (landscape or portrait)
    let ratiox = maxWidth / imageWidth
    let ratioy = maxHeight / imageHeight
    
    var ratio = min(ratiox, ratioy)
        
    // Calculate new size based on the ratio
    if ratio > 1 {
        ratio = 1
    }
    return NSRect(x: 0, y: 0, width: imageWidth*ratio, height: imageHeight*ratio)
}

