//
//  CreatePlaylistViewModel.swift
//  Hamorel
//
//  Created by 田川展也 on R 5/05/22.
//

import SwiftUICore

@MainActor
class CreatePlaylistViewModel<Repo: RoomDBProtocol & SongDBProtocol>: ObservableObject {

    init (ad: AdProtocol) {
        self.adMob = ad
    }
    var adMob: AdProtocol
    var appleMusicCreatePlaylistUseCase = AppleMusicCreatePlaylistUseCase()
    var hamorelSongUseCase = HamorelSongUseCase()

    var songs: [HamorelSong] = []

    @Published var users: [UserData] = []
    @Published var isLoading = true
    @Published var isReturnHome = false
    @Published var isCreateError = false
    @Published var isDownloadError = false
    @Published var isSuccessCreate = false
    @Published var playlistName = "HamorelPlaylist"

    func onAppear(roomPin: String) {
        adMob.loadAd()
        downloadSongs(roomPin: roomPin)
    }

    func onTappedAddAppleMusicButton() {
        createPlaylist()
        adMob.presentAd()
    }

    func onTappedReturnHomeButton() {
        isReturnHome = true
    }

    func downloadSongs(roomPin: String) {
        Task {
            do {
                users = try await Repo.downloadRoomData(roomPin: roomPin)
                let downloadData: [[HamorelSong]]  = try await Repo.downloadSongs(users: users)
                songs = downloadData[0]
                for i in 1..<downloadData.count {
                    songs = hamorelSongUseCase.merge(item1: songs, item2: downloadData[i])
                }
                isLoading = false
            } catch {
                print("download error: \(error.localizedDescription)")
                isDownloadError = true
            }
        }
    }

    private func createPlaylist() {
        Task {
            do {
                try appleMusicCreatePlaylistUseCase.createPlaylist(from: songs, playlistName: playlistName)
            } catch {
                print("create error: \(error.localizedDescription)")
                isCreateError = true
            }
        }
    }
}
