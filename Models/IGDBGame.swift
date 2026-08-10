//
//  IGDBGame.swift
//  GameBacklog
//
//  Created by Serhii Pershuta on 10.08.2026.
//

import Foundation

/// Search result shape returned by the IGDB `/v4/games` endpoint.
struct IGDBGame: Decodable, Identifiable {
    let id: Int
    let name: String
    let platforms: [IGDBPlatform]?
    let cover: IGDBCover?
}

struct IGDBPlatform: Decodable {
    let id: Int
    let name: String
}

struct IGDBCover: Decodable {
    let id: Int
    let imageId: String

    enum CodingKeys: String, CodingKey {
        case id
        case imageId = "image_id"
    }

    /// `t_cover_big` sizing per IGDB's image documentation.
    var url: URL? {
        URL(string: "https://images.igdb.com/igdb/image/upload/t_cover_big/\(imageId).jpg")
    }
}
