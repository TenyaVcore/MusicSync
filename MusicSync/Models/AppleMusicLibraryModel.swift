//
//  AppleMusicLibraryModel.swift
//  MusicSync
//
//  Created by 田川展也 on R 5/05/22.
//

import Foundation
import MusicKit

struct AppleMusicLibraryModel {
    func merge(item1: MusicItemCollection<Song>, item2: MusicItemCollection<Song>) -> MusicItemCollection<Song> {
        var mergedItem: MusicItemCollection<Song> = MusicItemCollection<Song>()

        let longerItem: MusicItemCollection<Song> = item1.count > item2.count ? item1 : item2
        let smallerItem: MusicItemCollection<Song> = item1.count <= item2.count ? item1 : item2

        for i in 0 ..< smallerItem.count {
            for j in 0 ..< longerItem.count {
                if longerItem[j].title == smallerItem[i].title && longerItem[j].artists == smallerItem[i].artists {
                    mergedItem += MusicItemCollection(arrayLiteral: smallerItem[i])
                    break
                }
            }
        }
        return mergedItem
    }

    func loadLibrary(limit: Int) async throws -> MusicItemCollection<Song> {
        var request = MusicLibraryRequest<Song>()
        request.limit = limit
        let response = try await request.response()

        let songs = response.items

        return MusicItemCollection(songs)
    }

    func createPlaylist(from songs: MusicItemCollection<Song>, playlistName: String = "Music Sync Playlist") throws {
        Task {
            try await MusicLibrary.shared.createPlaylist(name: playlistName, items: songs)
        }
    }

    func getCatalogID(from song: Song) throws -> String {
        // 一度JSONにパースしてから、CatalogIDを取得する
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
                let jsonData = try encoder.encode(song)
                let musicMetaData = try JSONDecoder().decode(MusicMetaData.self, from: jsonData)
                let catalogID = musicMetaData.meta.musicKit_identifierSet.catalogID
                return catalogID.value
    }

    func getSong(from catalogID: String) async throws -> Song {
        var request = MusicCatalogResourceRequest<Song>(matching: \.id, equalTo: MusicItemID(catalogID))
        request.limit = 1
        let response = try await request.response()
        return response.items[0]
    }

    func getSong(artist: String, title: String) async throws -> Song {
        var request = MusicCatalogSearchRequest(term: "\(artist) \(title)", types: [Song.self])
        request.limit = 1
        let response = try await request.response()

        guard let song = response.songs.first else {
            throw FetchError.songNotFound
        }

        // アーティスト名と曲名が完全に一致するか確認
        guard song.title.lowercased() == title.lowercased() &&
                song.artistName.lowercased() == artist.lowercased() else {
            throw FetchError.songMismatch
        }

        return song
    }
}

enum FetchError: Error {
    case songNotFound
    case songMismatch
}

// Songのメタデータをパースするモデル
private struct MusicMetaData: Codable {
    let meta: Meta
}

private struct Meta: Codable {
    let musicKit_identifierSet: MusicKitIdentifierSet
}

private struct MusicKitIdentifierSet: Codable {
    let catalogID: CatalogID
}

private struct CatalogID: Codable {
    let kind: String
    let value: String
}
