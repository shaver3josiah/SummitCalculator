import Foundation

public enum StoreKey: String, CaseIterable, Sendable {
    case history = "summit_history"
    case favorites = "summit_favorites"
    case funds = "summit_funds"
    case theme = "summit_theme"
    case custom = "summit_custom"
    case soundmap = "summit_soundmap"
    case recipes = "summit_recipes"
    case shopLists = "summitShopLists"
    case memory = "summit_memory"
    case songs = "summit_songs"
    case budget2 = "summit_budget2"
    case tabLabels = "summit_tablabels"
    case motion = "summit_motion"
    case counterTop = "summit_countertop"
    case calcLog = "summit_calclog"
    case chordWheel = "summit_chordwheel"
    case stewardship = "summit_stewardship"
}

public final class JSONStore: @unchecked Sendable {
    public static let shared: JSONStore = JSONStore(directory: JSONStore.defaultDirectory())

    private let directory: URL
    private let queue = DispatchQueue(label: "com.shaver.summitcalculator.jsonstore")

    public init(directory: URL) {
        self.directory = directory
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    public func get<T: Decodable>(_ key: StoreKey, as type: T.Type) -> T? {
        return queue.sync {
            let url = fileURL(for: key)
            guard let data = try? Data(contentsOf: url) else {
                return nil
            }
            do {
                return try JSONDecoder().decode(T.self, from: data)
            } catch {
                // Preserve the unreadable file so the next save can't overwrite the evidence.
                let aside = url.appendingPathExtension("corrupt")
                try? FileManager.default.removeItem(at: aside)
                try? FileManager.default.moveItem(at: url, to: aside)
                return nil
            }
        }
    }

    public func set<T: Encodable>(_ key: StoreKey, _ value: T) {
        queue.sync {
            let url = fileURL(for: key)
            guard let data = try? JSONEncoder().encode(value) else {
                return
            }
            try? data.write(to: url, options: .atomic)
        }
    }

    public func remove(_ key: StoreKey) {
        queue.sync {
            let url = fileURL(for: key)
            try? FileManager.default.removeItem(at: url)
        }
    }

    private func fileURL(for key: StoreKey) -> URL {
        return directory.appendingPathComponent(key.rawValue).appendingPathExtension("json")
    }

    private static func defaultDirectory() -> URL {
        let fm = FileManager.default
        if let appSupport = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            let summitDir = appSupport.appendingPathComponent("Summit", isDirectory: true)
            if (try? fm.createDirectory(at: summitDir, withIntermediateDirectories: true)) != nil {
                return summitDir
            }
        }
        return fm.temporaryDirectory
    }
}
