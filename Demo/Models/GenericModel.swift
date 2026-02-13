//
//  GenericModel.swift
//  Demo
//
//  Created by Alish Kumar on 02/06/25.
//


import Foundation

class GenericModel<U: Decodable>: Decodable {
    var status: String
    var statusCode: Int
    var message: String
    var response: U?
}
