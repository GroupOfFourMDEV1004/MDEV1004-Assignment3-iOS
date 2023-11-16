//
//  Movie.swift
//  MDEV1001-M2023-ICE10-iOS
//
//  Created by Indu Pandey on 27/07/23.
//

struct Movie: Codable
{
    let _id: String
    let movieID: String
    let title: String
    let studio: String
    let genres: [String]
    let directors: [String]
    let writers: [String]
    let actors: [String]
    let year: Int
    let length: Int
    let shortDescription: String
    let mpaRating: String
    let criticsRating: Double
}
