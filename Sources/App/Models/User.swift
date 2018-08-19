//
//  User.swift
//  App
//
//  Created by Brian Chon on 8/18/18.
//

import FluentSQLite
import Foundation
import Vapor

struct User: AnyModel {
    var username: String
}

/// Allows `Todo` to be encoded to and decoded from HTTP messages.
extension User: Content { }
