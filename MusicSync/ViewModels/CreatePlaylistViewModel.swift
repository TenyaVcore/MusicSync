//
//  CreatePlaylistViewModel.swift
//  MusicSync
//
//  Created by 田川展也 on R 5/05/22.
//

import SwiftUI
import MusicKit
import Firebase
import FirebaseFirestoreSwift

@MainActor
class CreatePlaylistViewModel: ObservableObject {
    var storeModel = FirestoreRepository()
    var appleMusicModel = AppleMusicLibraryModel()
    var musicSyncSongModel = MusicSyncSongModel()

    var songs: [MusicSyncSong] = []

    @Published var users: [UserData] = []
    @Published var isLoading = true
    @Published var isReturnHome = false
    @Published var isCreateError = false
    @Published var isDownloadError = false
    @Published var isSuccessCreate = false
    @Published var playlistName = "MusicSyncPlaylist"

    func downloadSongs(roomPin: String) {
        Task {
            do {
                users = try await storeModel.downloadRoomData(roomPin: roomPin)
                let downloadData: [[MusicSyncSong]]  = try await storeModel.downloadSongs(users: users)
                songs = downloadData[0]
                for i in 1..<downloadData.count {
                    songs = musicSyncSongModel.merge(item1: songs, item2: downloadData[i])
                }
                isLoading = false
            } catch {
                print("download error: \(error.localizedDescription)")
                isDownloadError = true
            }
        }
    }

    func createPlaylist() {
        Task {
            let musicItem = await songs.toMusicItemCollection()
            do {
                try appleMusicModel.createPlaylist(from: musicItem, playlistName: playlistName)
            } catch {
                print("create error: \(error.localizedDescription)")
                isCreateError = true
            }
        }
    }
}
