//
//  CreatePostParameters.swift
//  App
//
//  Created by Brian Chon on 8/18/18.
//

import FluentSQLite
import Foundation
import Vapor

struct CreatePostParameters: AnyModel {
    let title: String
    let description: String
    let mediaData: Data
}

struct DeletePostParameters: AnyModel {
    let id: Int
}
