import SwiftUI

/// Name → hand-drawn ingredient art. Resolves a parsed ingredient (or matched
/// `Food`) name to one of the 30 `*Art` View structs in IngredientArtPack1–3.
///
/// Matching order: lowercase/trim the input, try the curated `exact` dictionary,
/// then `contains` keyword fallbacks scanned LONGEST-KEYWORD-FIRST so a specific
/// phrase always beats a general one ("brown sugar" beats "sugar", "cream cheese"
/// beats "cheese"/"cream", "olive oil" beats "oil"). Returns nil when nothing
/// fits, so the caller can fall through to PNG art / glyph / 🥣.
enum IngredientArt {

    static func view(for rawName: String) -> AnyView? {
        let name = rawName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return nil }

        if let make = exact[name] { return make() }

        for (keyword, make) in keywords {
            // "egg" must not swallow "eggplant" (a vegetable with no art).
            if keyword == "egg" {
                if name.contains("egg") && !name.contains("eggplant") { return make() }
            } else if name.contains(keyword) {
                return make()
            }
        }
        return nil
    }

    // MARK: - Exact, curated names (checked first)

    private static let exact: [String: () -> AnyView] = [
        "egg": { AnyView(EggArt()) },
        "eggs": { AnyView(EggArt()) },

        "flour": { AnyView(FlourArt()) },
        "all-purpose flour": { AnyView(FlourArt()) },
        "all purpose flour": { AnyView(FlourArt()) },
        "ap flour": { AnyView(FlourArt()) },
        "plain flour": { AnyView(FlourArt()) },

        "sugar": { AnyView(SugarArt()) },
        "granulated sugar": { AnyView(SugarArt()) },
        "white sugar": { AnyView(SugarArt()) },
        "caster sugar": { AnyView(SugarArt()) },
        "powdered sugar": { AnyView(SugarArt()) },
        "confectioners sugar": { AnyView(SugarArt()) },
        "confectioner's sugar": { AnyView(SugarArt()) },
        "icing sugar": { AnyView(SugarArt()) },
        "cane sugar": { AnyView(SugarArt()) },

        "brown sugar": { AnyView(BrownSugarArt()) },
        "light brown sugar": { AnyView(BrownSugarArt()) },
        "dark brown sugar": { AnyView(BrownSugarArt()) },

        "rice": { AnyView(RiceArt()) },
        "white rice": { AnyView(RiceArt()) },
        "brown rice": { AnyView(RiceArt()) },

        "pasta": { AnyView(PastaArt()) },
        "spaghetti": { AnyView(PastaArt()) },
        "macaroni": { AnyView(PastaArt()) },
        "noodles": { AnyView(PastaArt()) },
        "penne": { AnyView(PastaArt()) },

        "oat": { AnyView(OatsArt()) },
        "oats": { AnyView(OatsArt()) },
        "oatmeal": { AnyView(OatsArt()) },
        "rolled oats": { AnyView(OatsArt()) },

        "chocolate chips": { AnyView(ChocChipsArt()) },
        "chocolate chip": { AnyView(ChocChipsArt()) },
        "choc chips": { AnyView(ChocChipsArt()) },

        "baking soda": { AnyView(BakingSodaArt()) },
        "baking powder": { AnyView(BakingPowderArt()) },

        "yeast": { AnyView(YeastArt()) },
        "active dry yeast": { AnyView(YeastArt()) },
        "instant yeast": { AnyView(YeastArt()) },

        "milk": { AnyView(MilkArt()) },
        "whole milk": { AnyView(MilkArt()) },
        "buttermilk": { AnyView(MilkArt()) },

        "vanilla": { AnyView(VanillaArt()) },
        "vanilla extract": { AnyView(VanillaArt()) },

        "olive oil": { AnyView(OliveOilArt()) },
        "extra virgin olive oil": { AnyView(OliveOilArt()) },

        "vegetable oil": { AnyView(VegOilArt()) },
        "canola oil": { AnyView(VegOilArt()) },
        "oil": { AnyView(VegOilArt()) },

        "butter": { AnyView(ButterArt()) },
        "unsalted butter": { AnyView(ButterArt()) },
        "salted butter": { AnyView(ButterArt()) },

        "cheese": { AnyView(CheeseArt()) },
        "cheddar": { AnyView(CheeseArt()) },
        "mozzarella": { AnyView(CheeseArt()) },
        "parmesan": { AnyView(CheeseArt()) },

        "cream cheese": { AnyView(CreamCheeseArt()) },
        "sour cream": { AnyView(SourCreamArt()) },

        "heavy cream": { AnyView(HeavyCreamArt()) },
        "whipping cream": { AnyView(HeavyCreamArt()) },
        "heavy whipping cream": { AnyView(HeavyCreamArt()) },

        "salt": { AnyView(SaltArt()) },
        "sea salt": { AnyView(SaltArt()) },
        "kosher salt": { AnyView(SaltArt()) },
        "table salt": { AnyView(SaltArt()) },

        "pepper": { AnyView(PepperArt()) },
        "black pepper": { AnyView(PepperArt()) },
        "white pepper": { AnyView(PepperArt()) },
        "ground black pepper": { AnyView(PepperArt()) },

        "cocoa": { AnyView(CocoaArt()) },
        "cocoa powder": { AnyView(CocoaArt()) },
        "chocolate": { AnyView(CocoaArt()) },

        "cinnamon": { AnyView(CinnamonArt()) },
        "ground cinnamon": { AnyView(CinnamonArt()) },

        "chicken": { AnyView(ChickenArt()) },
        "chicken breast": { AnyView(ChickenArt()) },

        "beef": { AnyView(BeefArt()) },
        "ground beef": { AnyView(BeefArt()) },

        "tomato": { AnyView(TomatoArt()) },
        "tomatoes": { AnyView(TomatoArt()) },

        "onion": { AnyView(OnionArt()) },
        "onions": { AnyView(OnionArt()) },

        "garlic": { AnyView(GarlicArt()) },
        "garlic clove": { AnyView(GarlicArt()) },

        "lemon": { AnyView(LemonArt()) },
        "lemons": { AnyView(LemonArt()) },
    ]

    // MARK: - Keyword fallbacks (LONGEST FIRST — do not reorder casually)

    /// Scanned in order; the first `contains` hit wins. Kept strictly
    /// non-increasing in keyword length so the specific phrase is always tested
    /// before any shorter keyword it contains. `_selfCheck()` asserts the order.
    private static let keywords: [(String, () -> AnyView)] = [
        ("heavy whipping cream", { AnyView(HeavyCreamArt()) }),
        ("chocolate chips", { AnyView(ChocChipsArt()) }),
        ("chocolate chip", { AnyView(ChocChipsArt()) }),
        ("whipping cream", { AnyView(HeavyCreamArt()) }),
        ("baking powder", { AnyView(BakingPowderArt()) }),
        ("vegetable oil", { AnyView(VegOilArt()) }),
        ("ground pepper", { AnyView(PepperArt()) }),
        ("cream cheese", { AnyView(CreamCheeseArt()) }),
        ("black pepper", { AnyView(PepperArt()) }),
        ("white pepper", { AnyView(PepperArt()) }),
        ("baking soda", { AnyView(BakingSodaArt()) }),
        ("brown sugar", { AnyView(BrownSugarArt()) }),
        ("heavy cream", { AnyView(HeavyCreamArt()) }),
        ("buttermilk", { AnyView(MilkArt()) }),
        ("sour cream", { AnyView(SourCreamArt()) }),
        ("peppercorn", { AnyView(PepperArt()) }),
        ("mozzarella", { AnyView(CheeseArt()) }),
        ("olive oil", { AnyView(OliveOilArt()) }),
        ("chocolate", { AnyView(CocoaArt()) }),
        ("spaghetti", { AnyView(PastaArt()) }),
        ("parmesan", { AnyView(CheeseArt()) }),
        ("macaroni", { AnyView(PastaArt()) }),
        ("cinnamon", { AnyView(CinnamonArt()) }),
        ("cheddar", { AnyView(CheeseArt()) }),
        ("vanilla", { AnyView(VanillaArt()) }),
        ("chicken", { AnyView(ChickenArt()) }),
        ("cheese", { AnyView(CheeseArt()) }),
        ("butter", { AnyView(ButterArt()) }),
        ("tomato", { AnyView(TomatoArt()) }),
        ("garlic", { AnyView(GarlicArt()) }),
        ("noodle", { AnyView(PastaArt()) }),
        ("flour", { AnyView(FlourArt()) }),
        ("sugar", { AnyView(SugarArt()) }),
        ("onion", { AnyView(OnionArt()) }),
        ("lemon", { AnyView(LemonArt()) }),
        ("yeast", { AnyView(YeastArt()) }),
        ("pasta", { AnyView(PastaArt()) }),
        ("cocoa", { AnyView(CocoaArt()) }),
        ("beef", { AnyView(BeefArt()) }),
        ("rice", { AnyView(RiceArt()) }),
        ("milk", { AnyView(MilkArt()) }),
        ("salt", { AnyView(SaltArt()) }),
        ("oat", { AnyView(OatsArt()) }),
        ("oil", { AnyView(VegOilArt()) }),
        ("egg", { AnyView(EggArt()) }),
    ]

    #if DEBUG
    /// Runnable invariant check (no toolchain here, but exercised if one appears).
    static func _selfCheck() {
        let lens = keywords.map { $0.0.count }
        assert(lens == lens.sorted(by: >),
               "IngredientArt.keywords must stay ordered longest-keyword-first")
        for s in ["brown sugar", "cream cheese", "sour cream", "heavy cream",
                  "olive oil", "vegetable oil", "chocolate chips", "baking soda",
                  "2 eggs", "unsalted butter"] {
            assert(view(for: s) != nil, "expected art for \(s)")
        }
        // Vegetable, not an egg — must fall through to the glyph.
        assert(view(for: "eggplant") == nil, "eggplant must not match egg art")
    }
    #endif
}
