//
//  PostParameters.swift
//  App
//
//  Created by Brian Chon on 8/18/18.
//

import FluentSQLite
import Foundation
import Vapor

struct PostParameters: AnyModel {
    let title: String
    let description: String
    let mediaData: Data
}
