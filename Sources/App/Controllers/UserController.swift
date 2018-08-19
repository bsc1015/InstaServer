//
//  UserController.swift
//  App
//
//  Created by Brian Chon on 8/18/18.
//

import Foundation
import Vapor

final class UserController {
    
    // MARK: - Internal
    
    func loginUser(request: Request) throws -> Future<Future<Response>> {
        guard let basicAuthorization = request.http.headers.basicAuthorization else {
            throw Abort(HTTPResponseStatus.badRequest, reason: "Basic authroization headers invalid")
        }
        let userExistsFuture = self.user(
            username: basicAuthorization.username,
            password: basicAuthorization.password,
            request: request)
        return userExistsFuture.map { (userCredentials) in
            guard let userCredentials = userCredentials else {
                throw Abort(HTTPResponseStatus.conflict, reason: "Invalid credentials")
            }
            try request.authenticate(userCredentials)
            let user = User(username: userCredentials.username)
            return try user.encode(for: request)
        }
    }
    
    func registerUser(request: Request) throws -> Future<Future<Future<Response>>> {
        let decodedUser = try request.content.decode(UserCredentials.self)
        return decodedUser.flatMap { (userCredentials) in
            let userExistsFuture = self.doesUserExist(userCredentials, request: request)
            return userExistsFuture.map { (userExists) in
                guard !userExists else {
                    throw Abort(HTTPResponseStatus.conflict, reason: "User already registered")
                }
                return try self.saveAndAuthenticateUserCredentials(userCredentials, request: request)
            }
        }
    }
    
    func getAllUsers(request: Request) throws -> Future<Response> {
        return try UserCredentials.query(on: request).all().encode(for: request)
    }
    
    // MARK: - Private
    
    private func saveAndAuthenticateUserCredentials(
        _ userCredentials: UserCredentials,
        request: Request
        ) throws -> Future<Future<Response>> {
        
        return userCredentials.save(on: request).map { (registeredUserCredentials) in
            try request.authenticate(registeredUserCredentials)
            let user = User(username: registeredUserCredentials.username)
            return try user.encode(for: request)
        }
    }
    
    private func doesUserExist(
        _ userCredentials: UserCredentials,
        request: Request
        ) -> Future<Bool> {
        
        let userCredentialsQuery = UserCredentials.query(on: request)
        let usersWithUsername = userCredentialsQuery.filter(\.username, .equal, userCredentials.username)
        return usersWithUsername.count().map { (count) in
            return count != 0
        }
    }
    
    private func user(
        username: String,
        password: String,
        request: Request
        ) -> Future<UserCredentials?> {
        
        let userCredentialsQuery = UserCredentials.query(on: request)
        let usersWithUsername = userCredentialsQuery.filter(\.username, .equal, username).filter(\.passwordHash, .equal, password)
        return usersWithUsername.first()
    }
    
}
