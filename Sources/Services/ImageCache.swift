import UIKit
import SwiftUI

public final class ImageCache {
    public static let shared = ImageCache()

    private let memoryCache = NSCache<NSURL, UIImage>()
    private let fileManager = FileManager.default
    private let diskCacheURL: URL

    private init() {
        // Set memory limits: 60MB max, max 150 images to avoid memory pressure on iPad Air 2 (2GB RAM)
        memoryCache.totalCostLimit = 60 * 1024 * 1024
        memoryCache.countLimit = 150

        // Disk cache directory
        let paths = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        diskCacheURL = paths[0].appendingPathComponent("ImageCache", isDirectory: true)
        try? fileManager.createDirectory(at: diskCacheURL, withIntermediateDirectories: true)

        // Clear memory cache when low on RAM
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(clearMemory),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }

    @objc private func clearMemory() {
        memoryCache.removeAllObjects()
    }

    public func image(for url: URL) -> UIImage? {
        // 1. Check Memory Cache
        if let memoryImage = memoryCache.object(forKey: url as NSURL) {
            return memoryImage
        }

        // 2. Check Disk Cache
        let fileURL = diskURL(for: url)
        if let data = try? Data(contentsOf: fileURL), let diskImage = UIImage(data: data) {
            let cost = data.count
            memoryCache.setObject(diskImage, forKey: url as NSURL, cost: cost)
            return diskImage
        }

        return nil
    }

    public func insertImage(_ image: UIImage, for url: URL, data: Data? = nil) {
        let cost = data?.count ?? (Int(image.size.width * image.size.height) * 4)
        memoryCache.setObject(image, forKey: url as NSURL, cost: cost)

        // Persist to disk asynchronously
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            let fileURL = self.diskURL(for: url)
            if let rawData = data ?? image.jpegData(compressionQuality: 0.85) {
                try? rawData.write(to: fileURL, options: .atomic)
            }
        }
    }

    private func diskURL(for url: URL) -> URL {
        let safeName = url.absoluteString.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? UUID().uuidString
        return diskCacheURL.appendingPathComponent(safeName)
    }
}

public struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    private let url: URL?
    private let content: (Image) -> Content
    private let placeholder: () -> Placeholder

    @State private var uiImage: UIImage?
    @State private var isLoading: Bool = false

    public init(
        url: URL?,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.content = content
        self.placeholder = placeholder
    }

    public var body: some View {
        Group {
            if let image = uiImage {
                content(Image(uiImage: image))
            } else {
                placeholder()
                    .task(id: url) {
                        await loadImage()
                    }
            }
        }
    }

    private func loadImage() async {
        guard let url = url else { return }
        if let cached = ImageCache.shared.image(for: url) {
            self.uiImage = cached
            return
        }

        isLoading = true
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200,
                  let downloadedImage = UIImage(data: data) else {
                isLoading = false
                return
            }
            ImageCache.shared.insertImage(downloadedImage, for: url, data: data)
            await MainActor.run {
                self.uiImage = downloadedImage
                self.isLoading = false
            }
        } catch {
            isLoading = false
        }
    }
}
