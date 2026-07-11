import Foundation

public enum FoodLibrary {
    private static let cache: [Food] = loadFoods()

    public static func load() -> [Food] {
        return cache
    }

    public static func match(_ raw: String) -> Food? {
        let needle = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if needle.isEmpty {
            return nil
        }
        if let exact = cache.first(where: { $0.name.lowercased() == needle }) {
            return exact
        }
        if let prefix = cache.first(where: { $0.name.lowercased().hasPrefix(needle) }) {
            return prefix
        }
        if let contains = cache.first(where: { $0.name.lowercased().contains(needle) }) {
            return contains
        }
        return tokenMatch(needle)
    }

    private static func tokenize(_ s: String) -> [String] {
        let separators: Set<Character> = [" ", "\t", "-", "/", ","]
        return s.split(whereSeparator: { separators.contains($0) })
            .map { $0.lowercased() }
            .filter { !$0.isEmpty }
    }

    private static func tokenMatch(_ needle: String) -> Food? {
        let needleTokens = Set(tokenize(needle))
        guard !needleTokens.isEmpty else {
            return nil
        }
        var best: Food? = nil
        var bestScore = 0
        for food in cache {
            let foodTokens = tokenize(food.name)
            guard !foodTokens.isEmpty else {
                continue
            }
            guard foodTokens.contains(where: { $0.contains(where: { $0.isLetter }) }) else {
                continue
            }
            guard Set(foodTokens).isSubset(of: needleTokens) else {
                continue
            }
            let score = foodTokens.count
            if score > bestScore {
                bestScore = score
                best = food
            } else if score == bestScore, let currentBest = best, food.name.count > currentBest.name.count {
                best = food
            }
        }
        return best
    }

    public static func groups() -> [String] {
        var seen = Set<String>()
        var ordered: [String] = []
        for food in cache {
            if !seen.contains(food.group) {
                seen.insert(food.group)
                ordered.append(food.group)
            }
        }
        return ordered
    }

    private static func loadFoods() -> [Food] {
        guard let url = Bundle.module.url(forResource: "foods", withExtension: "json") else {
            return []
        }
        guard let data = try? Data(contentsOf: url) else {
            return []
        }
        guard let foods = try? JSONDecoder().decode([Food].self, from: data) else {
            return []
        }
        return foods
    }
}
