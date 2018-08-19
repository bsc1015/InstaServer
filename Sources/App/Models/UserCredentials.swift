//
//  UserCredentials.swift
//  App
//
//  Created by Brian Chon on 8/17/18.
//

import Authentication
import FluentSQLite
import Foundation
import Vapor

struct UserCredentials: SQLiteModel {
    var id: Int?
    var username: String
    var email: String
    var passwordHash: String
    
    var tokens: Children<UserCredentials, UserToken> {
        return children(\.userID)
    }
}

/// Allows `Todo` to be used as a dynamic migration.
extension UserCredentials: Migration { }

/// Allows `Todo` to be encoded to and decoded from HTTP messages.
extension UserCredentials: Content { }

/// Allows `Todo` to be used as a dynamic parameter in route definitions.
extension UserCredentials: Parameter { }

extension UserCredentials: SessionAuthenticatable { }

extension UserCredentials: TokenAuthenticatable {
    /// See `TokenAuthenticatable`.
    typealias TokenType = UserToken
}

extension UserCredentials: PasswordAuthenticatable {
    /// See `PasswordAuthenticatable`.
    static var usernameKey: WritableKeyPath<UserCredentials, String> {
        return \.username
    }
    
    /// See `PasswordAuthenticatable`.
    static var passwordKey: WritableKeyPath<UserCredentials, String> {
        return \.passwordHash
    }
}

struct UserToken: SQLiteModel {
    var id: Int?
    var string: String
    var userID: UserCredentials.ID
    
    var user: Parent<UserToken, UserCredentials> {
        return parent(\.userID)
    }
}

extension UserToken: Token {
    /// See `Token`.
    typealias UserType = UserCredentials
    
    /// See `Token`.
    static var tokenKey: WritableKeyPath<UserToken, String> {
        return \.string
    }
    
    /// See `Token`.
    static var userIDKey: WritableKeyPath<UserToken, UserCredentials.ID> {
        return \.userID
    }
}
