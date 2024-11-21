import Foundation
import ScriptingBridge

// Spotify track state
@objc public enum SpotifyPlayerState: AEKeyword {
    case playing = 0x706C6179 // 'play'
    case paused = 0x70617364  // 'pause'
    case stopped = 0x73746F70 // 'stop'
}

// Track protocol
@objc public protocol SpotifyBridgeTrack {
    @objc optional var artist: String { get }
    @objc optional var name: String { get }
    @objc optional var album: String { get }
    @objc optional var duration: Int { get }
}

// Application protocol
@objc public protocol SpotifyBridgeApplication {
    @objc optional var currentTrack: Any? { get }
    @objc optional var playerState: String? { get }
    @objc optional func play()
    @objc optional func pause()
    @objc optional func nextTrack()
    @objc optional func previousTrack()
}

// Extend SBApplication
extension SBApplication: SpotifyBridgeApplication {}
