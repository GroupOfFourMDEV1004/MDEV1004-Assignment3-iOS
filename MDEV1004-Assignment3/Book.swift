//
//  Books.swift
//  MDEV1004-Assignment3
//
//  Created by Indu Pandey on 15/11/23.
//

import Foundation

struct Book: Codable
{
    let _id: String
    let BooksName: String
    let ISBN: String
    let Rating: Float
    let Author: String
    let Genre: String
}
