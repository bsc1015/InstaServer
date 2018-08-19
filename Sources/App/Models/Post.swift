//
//  Post.swift
//  App
//
//  Created by Brian Chon on 8/18/18.
//

import FluentSQLite
import Foundation
import Vapor


struct Post: SQLiteModel {
    var id: Int?
    let title: String
    let description: String
    let creationDate: Date
    let user: User
    let mediaRenditions: PostMediaRenditions
}

struct PostMediaRenditions: AnyModel {
    let original: URL
}

/// Allows `Todo` to be used as a dynamic migration.
extension Post: Migration { }

/// Allows `Todo` to be encoded to and decoded from HTTP messages.
extension Post: Content { }

/// Allows `Todo` to be encoded to and decoded from HTTP messages.
extension PostMediaRenditions: Content { }
