import Foundation

public enum EasterEggs {
    private static let cache: [Egg] = loadEggs()

    public static func all() -> [Egg] {
        return cache
    }

    public static func match(sequence: String) -> Egg? {
        for egg in cache {
            if egg.triggers.contains(sequence) {
                return egg
            }
        }
        return nil
    }

    private static func loadEggs() -> [Egg] {
        guard let url = Bundle.module.url(forResource: "eggs", withExtension: "json") else {
            return []
        }
        guard let data = try? Data(contentsOf: url) else {
            return []
        }
        guard let eggs = try? JSONDecoder().decode([Egg].self, from: data) else {
            return []
        }
        return eggs
    }
}
