import SwiftUI

public enum PlayerDisplayState: Equatable {
    case hidden
    case miniplayer
    case expanded
    case fullscreen
}

@MainActor
public final class PlayerCoordinator: ObservableObject {
    public static let shared = PlayerCoordinator()

    @Published public var displayState: PlayerDisplayState = .hidden
    @Published public var currentVideo: Video?
    public let viewModel = PlayerViewModel()

    private init() {}

    public func play(video: Video) {
        self.currentVideo = video
        withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
            self.displayState = .expanded
        }
        Task {
            await viewModel.loadVideo(video: video)
        }
    }

    public func minimize() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
            self.displayState = .miniplayer
        }
    }

    public func expand() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
            self.displayState = .expanded
        }
    }

    public func enterFullscreen() {
        withAnimation(.easeInOut(duration: 0.25)) {
            self.displayState = .fullscreen
        }
    }

    public func exitFullscreen() {
        withAnimation(.easeInOut(duration: 0.25)) {
            self.displayState = .expanded
        }
    }

    public func close() {
        withAnimation(.easeOut(duration: 0.2)) {
            self.displayState = .hidden
            self.currentVideo = nil
        }
        viewModel.stop()
    }

    public func togglePlayPause() {
        viewModel.togglePlayPause()
    }
}
