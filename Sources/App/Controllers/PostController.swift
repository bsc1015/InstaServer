//
//  PostController.swift
//  App
//
//  Created by Brian Chon on 8/18/18.
//

import Foundation
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
        let decodedPostParameters = try request.content.decode(PostParameters.self)
        return decodedPostParameters.flatMap { (postParameters) in
            
            let minimumTitleSize = 1
            guard postParameters.title.count >= minimumTitleSize else {
                throw Abort(HTTPResponseStatus.preconditionFailed, reason: "Title length has to be at least \(minimumTitleSize) characters long")
            }
            
            let imageFormat = ImageFormat(data: postParameters.mediaData)
            guard imageFormat != .unknown else {
                throw Abort(HTTPResponseStatus.unsupportedMediaType, reason: "Unsupported media type")
            }
            
            let maxMediaSize = 8000000
            guard postParameters.mediaData.count < maxMediaSize else {
                throw Abort(HTTPResponseStatus.payloadTooLarge, reason: "Media size has to be lower than \(maxMediaSize)")
            }
            
            let tempDirectory = URL(string: NSTemporaryDirectory())!
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension(imageFormat.fileExtension)
            try FileManager.default.createDirectory(atPath: tempDirectory.deletingLastPathComponent().path, withIntermediateDirectories: true, attributes: nil)
            try FileManager.default.createFile(atPath: tempDirectory.path, contents: postParameters.mediaData, attributes: nil)
            let user = User(username: userCredentials.username)
            let post = Post(
                id: nil,
                title: postParameters.title,
                description: postParameters.description,
                creationDate: Date(),
                user: user,
                mediaRenditions: PostMediaRenditions(original: tempDirectory))
            return post.save(on: request).map { (savedPost) in
                return try savedPost.encode(for: request)
            }
        }
    }
    
    // MARK: - Private
    
    private enum ImageFormat {
        case unknown
        case png
        case jpeg
        case gif
        case tiff_01
        case tiff_02
        
        init(data: Data) {
            switch Array(data) {
            case [0x89]: self = .png
            case [0xFF]: self = .jpeg
            case [0x47]: self = .gif
            case [0x49]: self = .tiff_01
            case [0x4D]: self = .tiff_02
            default: self = .unknown
            }
        }
        
        var fileExtension: String {
            switch self {
            case .png: return "png"
            case .jpeg: return "jpg"
            case .gif: return "gif"
            case .tiff_01: fallthrough
            case .tiff_02: return "tiff"
            case .unknown: return ""
            }
        }
    }
}

