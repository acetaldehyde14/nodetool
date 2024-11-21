import Foundation
import ScriptingBridge
import SwiftUI

@objc protocol SpotifyApplication {
    @objc optional var playerState: String { get }
    @objc optional var currentTrack: SpotifyTrack { get }
    @objc optional func playpause()
    @objc optional func nextTrack()
    @objc optional func previousTrack()
    @objc optional func setPlayerPosition(_ position: Double)
}

@objc protocol SpotifyTrack {
    @objc optional var artist: String { get }
    @objc optional var name: String { get }
    @objc optional var album: String { get }
    @objc optional var artworkUrl: String { get }
    @objc optional var duration: Double { get }
    @objc optional var id: String { get }
}

class SpotifyController: ObservableObject {
    @Published var isPlaying = false
    @Published var currentTrack: String = "No track"
    @Published var currentArtist: String = "No artist"
    @Published var currentAlbum: String = ""
    @Published var progressPercentage: Double = 0.0
    @Published var isSpotifyRunning = false
    @Published var albumArtworkImage: NSImage?
    
    private var spotify: SpotifyApplication?
    private var timer: Timer?
    private var trackDuration: Double = 0
    private var trackPosition: Double = 0
    
    init() {
        setupSpotify()
        startPolling()
    }
    
    private func setupSpotify() {
        spotify = SBApplication(bundleIdentifier: "com.spotify.client") as? SpotifyApplication
        checkIfSpotifyIsRunning()
    }
    
    private func checkIfSpotifyIsRunning() {
        let runningApps = NSWorkspace.shared.runningApplications
        isSpotifyRunning = runningApps.contains { $0.bundleIdentifier == "com.spotify.client" }
    }
    
    private func startPolling() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.updatePlayerState()
        }
    }
    
    private func updatePlayerState() {
        guard let spotify = spotify else {
            checkIfSpotifyIsRunning()
            return
        }
        
        DispatchQueue.main.async {
            self.isPlaying = spotify.playerState == "playing"
            
            // Get current track information
            if let track = spotify.currentTrack {
                let artist = track.artist ?? "Unknown Artist"
                let name = track.name ?? "Unknown Track"
                let album = track.album ?? ""
                
                // Only update if there's a change
                if self.currentTrack != name || self.currentArtist != artist {
                    self.currentTrack = name
                    self.currentArtist = artist
                    self.currentAlbum = album
                    
                    // Fetch album artwork through AppleScript (simplified for demo)
                    self.fetchAlbumArtwork()
                }
                
                // Calculate progress (simplified)
                if let duration = track.duration {
                    self.trackDuration = duration
                    
                    // Update progress with AppleScript
                    self.updateTrackProgress()
                }
            } else {
                self.currentTrack = "No track"
                self.currentArtist = "No artist"
                self.currentAlbum = ""
                self.albumArtworkImage = nil
                self.progressPercentage = 0
            }
        }
    }
    
    // Fetch progress using AppleScript
    private func updateTrackProgress() {
        if let script = NSAppleScript(source: """
            tell application "Spotify"
                if player state is playing or player state is paused then
                    return player position
                else
                    return 0
                end if
            end tell
            """) {
            var error: NSDictionary?
            if let result = script.executeAndReturnError(&error).stringValue,
               let position = Double(result) {
                self.trackPosition = position
                
                if self.trackDuration > 0 {
                    self.progressPercentage = position / self.trackDuration
                }
            }
        }
    }
    
    // Simplified artwork fetch (in a real app, you might use the Spotify API)
    private func fetchAlbumArtwork() {
        // This is a simplified version - in production you would use the Spotify API
        // or a more robust method to fetch artwork
        self.albumArtworkImage = NSImage(named: "music.note")
    }
    
    func playPause() {
        spotify?.playpause?()
    }
    
    func nextTrack() {
        spotify?.nextTrack?()
    }
    
    func previousTrack() {
        spotify?.previousTrack?()
    }
    
    func seekToPosition(_ percentage: Double) {
        if trackDuration > 0 {
            let newPosition = trackDuration * percentage
            spotify?.setPlayerPosition?(newPosition)
        }
    }
    
    deinit {
        timer?.invalidate()
    }
}
