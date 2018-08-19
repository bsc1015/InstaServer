//
//  PostController.swift
//  App
//
//  Created by Brian Chon on 8/18/18.
//

import AppKit
import Foundation
import CoreGraphics
import Multipart
import Vapor

final class PostController {
    
    // MARK: - Internal
    
    func getAllPosts(request: Request) throws -> Future<Response> {
        return try Post.query(on: request).all().encode(for: request)
    }
    
    func createPost(request: Request) throws -> Future<Future<Response>> {
        guard let userCredentials = try request.authenticated(UserCredentials.self) else {
            throw Abort(HTTPResponseStatus.unauthorized)
        }
        let decodedPostParameters = try request.content.decode(CreatePostParameters.self)
        return decodedPostParameters.flatMap { (postParameters) in
            
            let imageFormat = try self.validateImage(
                postParameters: postParameters, request: request)
            
            let tempDirectory: URL
            if #available(OSX 10.12, *) {
                tempDirectory = FileManager.default.temporaryDirectory
            } else {
                tempDirectory = URL(string: NSTemporaryDirectory())!
            }
            let mediaRenditions = try self.createImageRenditions(
                using: postParameters.mediaData, directory: tempDirectory, fileExtension: imageFormat.fileExtension)
            
            let user = User(username: userCredentials.username)
            let post = Post(
                id: nil,
                title: postParameters.title,
                description: postParameters.description,
                creationDate: Date(),
                user: user,
                mediaRenditions: mediaRenditions)
            return post.save(on: request).map { (savedPost) in
                return try savedPost.encode(for: request)
            }
        }
    }
    
    func deletePost(request: Request) throws -> Future<Future<Response>> {
        guard let userCredentials = try request.authenticated(UserCredentials.self) else {
            throw Abort(HTTPResponseStatus.unauthorized)
        }
        let decodedPostParameters = try request.content.decode(DeletePostParameters.self)
        return decodedPostParameters.flatMap { (postParameters) in
            return self.post(id: postParameters.id, request: request).map { (post) in
                guard let post = post else {
                    throw Abort(HTTPResponseStatus.notFound)
                }
                guard post.user.username == userCredentials.username else {
                    throw Abort(HTTPResponseStatus.unauthorized)
                }
                return post.delete(on: request).map {
                    return Response(http: HTTPResponse(status: HTTPResponseStatus.ok), using: request)
                }
            }
        }
    }
    
    // MARK: - Private
    
    private func validateImage(postParameters: CreatePostParameters, request: Request) throws -> ImageFormat {
        
        let minimumTitleSize = 1
        guard postParameters.title.count >= minimumTitleSize else {
            throw Abort(HTTPResponseStatus.preconditionFailed, reason: "Title length has to be at least \(minimumTitleSize) characters long")
        }
        
        let minMediaFileSize = 32
        guard postParameters.mediaData.count > minMediaFileSize else {
            throw Abort(HTTPResponseStatus.payloadTooLarge, reason: "Media size has to be greater than \(minMediaFileSize)")
        }
        
        let maxMediaFileSize = 8000000
        guard postParameters.mediaData.count < maxMediaFileSize else {
            throw Abort(HTTPResponseStatus.payloadTooLarge, reason: "Media size has to be lower than \(maxMediaFileSize)")
        }
        
        // get image format from Content-Type header
        let imageFormatFromContentType: ImageFormat
        if let contentType = request.http.headers.firstValue(name: .contentType) {
            imageFormatFromContentType = ImageFormat(contentTypeString: contentType)
        } else {
            imageFormatFromContentType = .unknown
        }
        
        // if unable to get image format from Content-Type header,
        // read the buffer data to see what type of media it is.
        let imageFormat: ImageFormat
        if imageFormatFromContentType == .unknown {
            imageFormat = ImageFormat(data: postParameters.mediaData)
        } else {
            imageFormat = imageFormatFromContentType
        }
        
        guard imageFormat != .unknown else {
            throw Abort(HTTPResponseStatus.unsupportedMediaType, reason: "Unsupported media type")
        }
        
        return imageFormat
    }
    
    private func createImageRenditions(using data: Data, directory: URL, fileExtension: String) throws -> PostMediaRenditions {
        
        let mutableOriginalMediaData = data
        guard let originalBitmapImageRep = NSBitmapImageRep(data: mutableOriginalMediaData),
            let originalCgImage = originalBitmapImageRep.cgImage else {
                throw Abort(.failedDependency)
        }
        
        let widths = [320, 640, 750, 1080, 1125]
        var widthToImage = [Int: CGImage]()
        
        for width in widths {
            let image = try self.createImage(using: data, targetWidth: width)
            widthToImage[width] = image
        }
        
        try FileManager.default.createDirectory(
            at: directory.appendingPathComponent("original"),
            withIntermediateDirectories: true,
            attributes: nil)
        
        let fileName = UUID().uuidString
        let originalFileDestinationUrl = directory
            .appendingPathComponent(fileName)
            .appendingPathExtension(fileExtension)
        guard let originalImageDestination = CGImageDestinationCreateWithURL(originalFileDestinationUrl as CFURL, kUTTypeJPEG, 1, nil) else {
            throw Abort(HTTPResponseStatus.failedDependency)
        }
        CGImageDestinationAddImage(originalImageDestination, originalCgImage, nil)
        CGImageDestinationFinalize(originalImageDestination)
        
        
        var widthToUrl = [Int: URL]()
        for (width, image) in widthToImage {
            let subdirectoryName = "w" + width.description
            let fileDestinationUrl = directory
                .appendingPathComponent(subdirectoryName)
                .appendingPathComponent(fileName)
                .appendingPathExtension(fileExtension)
            guard let destination = CGImageDestinationCreateWithURL(fileDestinationUrl as CFURL, kUTTypeJPEG, 1, nil) else {
                continue
            }
            CGImageDestinationAddImage(destination, image, nil)
            CGImageDestinationFinalize(destination)
            widthToUrl[width] = fileDestinationUrl
        }
        
        return PostMediaRenditions(
            w320: widthToUrl[320],
            w640: widthToUrl[640],
            w750: widthToUrl[750],
            w1080: widthToUrl[1080],
            w1125: widthToUrl[1125],
            original: originalFileDestinationUrl)
    }
    
    private func createImage(using data: Data, targetWidth: Int) throws -> CGImage? {
        var mutableMediaData = data
        guard let bitmapImageRep = NSBitmapImageRep(data: mutableMediaData),
            let cgImage = bitmapImageRep.cgImage,
            let colorSpace = cgImage.colorSpace else {
                throw Abort(.failedDependency)
        }
        
        guard cgImage.width >= targetWidth else {
            return nil
        }
        
        let inverseImageAspectRatio = CGFloat(cgImage.height)/CGFloat(cgImage.width)
        let targetHeight = Int(CGFloat(targetWidth) * inverseImageAspectRatio)
        
        guard let cgContext = CGContext(
            data: &mutableMediaData,
            width: targetWidth,
            height: targetHeight,
            bitsPerComponent: cgImage.bitsPerComponent,
            bytesPerRow: cgImage.bytesPerRow,
            space: colorSpace,
            bitmapInfo: cgImage.bitmapInfo.rawValue) else {
                throw Abort(.unprocessableEntity)
        }
        cgContext.draw(cgImage, in: CGRect(
            origin: .zero,
            size: CGSize(width: targetWidth, height: targetHeight)))
        cgContext.interpolationQuality = CGInterpolationQuality.default
        
        guard let imageRendition = cgContext.makeImage() else {
            throw Abort(HTTPResponseStatus.unprocessableEntity)
        }
        return imageRendition
    }
    
    private func post(id: Int, request: Request) -> Future<Post?> {
        let postQuery = Post.query(on: request)
        let postWithId = postQuery.filter(\.id, .equal, id)
        return postWithId.first()
    }
}

// MARK: - ImageFormat

private enum ImageFormat {
    case unknown
//    case png
    case jpeg
    //        case gif
    //        case tiff_01
    //        case tiff_02
    
    init(contentTypeString: String) {
        switch contentTypeString {
//        case "image/png": self = .png
        case "image/jpg": fallthrough
        case "image/jpeg": self = .jpeg
        default: self = .unknown
        }
    }
    
    init(data: Data) {
        switch Array(data).first! {
//        case 0x89: self = .png
        case 0xFF: self = .jpeg
//        case 0x47: self = .gif
//        case 0x49: self = .tiff_01
//        case 0x4D: self = .tiff_02
        default: self = .unknown
        }
    }
    
    var fileExtension: String {
        switch self {
//        case .png: return "png"
        case .jpeg: return "jpg"
//        case .gif: return "gif"
//        case .tiff_01: fallthrough
//        case .tiff_02: return "tiff"
        case .unknown: return ""
        }
    }
}
