import SwiftUI

// MARK: - Model

/// One library preset: a title and a chord progression the ChordParser can read.
/// Progressions only — titles and chord letters carry no lyrics, so every entry
/// plays offline with the app's own soft piano.
struct PresetSong: Identifiable, Hashable {
    let title: String
    let chords: String
    var id: String { title }

    init(_ title: String, _ chords: String) {
        self.title = title
        self.chords = chords
    }
}

enum SongCategory: String, CaseIterable, Identifiable {
    case psalms, hymns, country, oldTimey

    var id: String { rawValue }

    var name: String {
        switch self {
        case .psalms: return "Psalms"
        case .hymns: return "Hymns"
        case .country: return "Country"
        case .oldTimey: return "Old-Timey"
        }
    }

    var blurb: String {
        switch self {
        case .psalms: return "Songs of the shepherd king"
        case .hymns: return "The great old hymns of the faith"
        case .country: return "Boots, hearts & steel strings"
        case .oldTimey: return "Parlor songs & porch classics"
        }
    }

    var systemImage: String {
        switch self {
        case .psalms: return "book.closed.fill"
        case .hymns: return "music.note.list"
        case .country: return "guitars.fill"
        case .oldTimey: return "radio.fill"
        }
    }

    var songs: [PresetSong] {
        switch self {
        case .psalms: return SongLibrary.psalms
        case .hymns: return SongLibrary.hymns
        case .country: return SongLibrary.country
        case .oldTimey: return SongLibrary.oldTimey
        }
    }
}

// MARK: - Data

enum SongLibrary {
    /// 50 psalms — progressions mood-matched (minor keys for the laments).
    static let psalms: [PresetSong] = [
        PresetSong("Psalm 1 · Like a Tree Planted", "C F C Am F G C"),
        PresetSong("Psalm 4 · Evening Peace", "G C G Em C D G"),
        PresetSong("Psalm 5 · Morning Prayer", "D G D Bm G A D"),
        PresetSong("Psalm 8 · How Majestic Your Name", "D A Bm G D G A D"),
        PresetSong("Psalm 16 · Fullness of Joy", "E A E C#m A B E"),
        PresetSong("Psalm 19 · The Heavens Declare", "G D Em C G C D G"),
        PresetSong("Psalm 23 · The Lord Is My Shepherd", "C F C Am Dm G7 C"),
        PresetSong("Psalm 24 · The King of Glory", "D G A D Bm G A D"),
        PresetSong("Psalm 25 · I Lift Up My Soul", "Am F C G Am F G Am"),
        PresetSong("Psalm 27 · My Light and Salvation", "F Bb F Dm Bb C7 F"),
        PresetSong("Psalm 30 · Joy in the Morning", "G C D G Em C D7 G"),
        PresetSong("Psalm 32 · Sins Forgiven", "C Am F G C Am G7 C"),
        PresetSong("Psalm 33 · Sing a New Song", "A D A E F#m D E7 A"),
        PresetSong("Psalm 34 · Taste and See", "G C G Em Am D7 G"),
        PresetSong("Psalm 37 · Delight in the Lord", "F C Dm Bb F Bb C7 F"),
        PresetSong("Psalm 40 · A New Song in My Mouth", "E B C#m A E B7 E"),
        PresetSong("Psalm 42 · As the Deer Pants", "Em C G D Em C D Em"),
        PresetSong("Psalm 46 · A Very Present Help", "C G Am F C F G C"),
        PresetSong("Psalm 47 · Clap Your Hands", "D A D G D G A7 D"),
        PresetSong("Psalm 51 · A Clean Heart", "Am Dm Am E7 Am Dm E7 Am"),
        PresetSong("Psalm 57 · Awake, My Glory", "Bb Eb Bb Gm Eb F7 Bb"),
        PresetSong("Psalm 61 · Lead Me to the Rock", "G Em C D G Em D7 G"),
        PresetSong("Psalm 62 · My Soul Waits", "F Dm Bb C F Dm C7 F"),
        PresetSong("Psalm 63 · Thirsting for God", "Dm Bb F C Dm Bb C Dm"),
        PresetSong("Psalm 65 · Streams of Blessing", "G C G D Em C D G"),
        PresetSong("Psalm 66 · Shout for Joy", "D G D A D G A7 D"),
        PresetSong("Psalm 67 · Let the Peoples Praise", "C F G C Am F G7 C"),
        PresetSong("Psalm 71 · My Hope Since Youth", "F Bb F C Dm Bb C7 F"),
        PresetSong("Psalm 84 · How Lovely Your Dwelling", "D G D Bm Em A7 D"),
        PresetSong("Psalm 86 · Teach Me Your Way", "Am C F G Am F E7 Am"),
        PresetSong("Psalm 90 · Our Dwelling Place", "C G Am Em F C G7 C"),
        PresetSong("Psalm 91 · Shelter of the Most High", "G C G Em C G D7 G"),
        PresetSong("Psalm 93 · The Lord Reigns", "D A D G A D G A D"),
        PresetSong("Psalm 95 · Come, Let Us Sing", "A D A E A D E7 A"),
        PresetSong("Psalm 96 · Sing to the Lord", "G C D G Em C D7 G"),
        PresetSong("Psalm 98 · Make a Joyful Noise", "D G A D G D A7 D"),
        PresetSong("Psalm 100 · Enter with Thanksgiving", "C F C G C F G7 C"),
        PresetSong("Psalm 103 · Bless the Lord, My Soul", "G D Em C G C D G"),
        PresetSong("Psalm 104 · Clothed in Splendor", "F Bb C F Dm Bb C F"),
        PresetSong("Psalm 107 · His Steadfast Love", "C Am F G C Am F G C"),
        PresetSong("Psalm 113 · From the Rising Sun", "D Bm G A D Bm A7 D"),
        PresetSong("Psalm 116 · I Love the Lord", "G Em C D G Em C D G"),
        PresetSong("Psalm 118 · This Is the Day", "D G D A Bm G A7 D"),
        PresetSong("Psalm 119 · A Lamp to My Feet", "C F Am G C F G C"),
        PresetSong("Psalm 121 · I Lift My Eyes", "G C G D Em C D7 G"),
        PresetSong("Psalm 126 · Sowing in Tears, Reaping Joy", "Em G C D Em C D G"),
        PresetSong("Psalm 130 · Out of the Depths", "Am F C E7 Am F E7 Am"),
        PresetSong("Psalm 133 · How Good, How Pleasant", "F C Bb F Gm C7 F"),
        PresetSong("Psalm 139 · Wonderfully Made", "D A Bm F#m G D G A7 D"),
        PresetSong("Psalm 145 · Great Is the Lord", "C G F C Am F G7 C")
    ]

    /// 100 hymns — the classic public-domain harmonizations, simplified to the
    /// parser's chord vocabulary.
    static let hymns: [PresetSong] = [
        // 1–10
        PresetSong("Amazing Grace", "G G7 C G Em D D7 G"),
        PresetSong("Be Thou My Vision", "D G D A Bm G A D"),
        PresetSong("Holy, Holy, Holy", "D Bm A D G D A7 D"),
        PresetSong("It Is Well with My Soul", "C F C G7 C F G7 C"),
        PresetSong("Great Is Thy Faithfulness", "F Bb F C7 F Bb F C7 F"),
        PresetSong("Come Thou Fount of Every Blessing", "D G D A D G D A7 D"),
        PresetSong("Rock of Ages", "G C G D7 G C D7 G"),
        PresetSong("A Mighty Fortress Is Our God", "C F C G Am F G7 C"),
        PresetSong("Blessed Assurance", "D G D A D G A7 D"),
        PresetSong("What a Friend We Have in Jesus", "F Bb F C7 F Bb C7 F"),
        // 11–20
        PresetSong("Crown Him with Many Crowns", "D G D A Bm E7 A D"),
        PresetSong("All Hail the Power of Jesus' Name", "G C G D G C D7 G"),
        PresetSong("O for a Thousand Tongues to Sing", "G D G C G D7 G"),
        PresetSong("And Can It Be", "G C G D Em C D7 G"),
        PresetSong("Christ the Lord Is Risen Today", "C G C F C G7 C"),
        PresetSong("Joyful, Joyful, We Adore Thee", "G D G C G Em D7 G"),
        PresetSong("Praise to the Lord, the Almighty", "F C F Bb F Gm C7 F"),
        PresetSong("Immortal, Invisible, God Only Wise", "D G D A D Bm A7 D"),
        PresetSong("This Is My Father's World", "Eb Ab Eb Bb Eb Ab Bb7 Eb"),
        PresetSong("For the Beauty of the Earth", "G C G D Em C D7 G"),
        // 21–30
        PresetSong("Fairest Lord Jesus", "Eb Bb Eb Ab Eb Bb7 Eb"),
        PresetSong("I Surrender All", "C F C G7 C F C G7 C"),
        PresetSong("Just As I Am", "D G D A D G A7 D"),
        PresetSong("Softly and Tenderly", "G C G D7 G C D7 G"),
        PresetSong("Trust and Obey", "F Bb F C7 F Bb C7 F"),
        PresetSong("When I Survey the Wondrous Cross", "C F C Am Dm G7 C"),
        PresetSong("Nothing but the Blood", "G C G D G C D7 G"),
        PresetSong("There Is a Fountain", "C F C G C F G7 C"),
        PresetSong("At the Cross", "G C G D7 G C D7 G"),
        PresetSong("Jesus Paid It All", "D G D A7 D G A7 D"),
        // 31–40
        PresetSong("The Old Rugged Cross", "C F C G7 C F C G7 C"),
        PresetSong("In the Garden", "F Bb F C7 F Bb F C7 F"),
        PresetSong("He Leadeth Me", "D G D A7 D G D A7 D"),
        PresetSong("Sweet Hour of Prayer", "C F C G7 C F G7 C"),
        PresetSong("What Wondrous Love Is This", "Dm C Dm Am Dm C Dm"),
        PresetSong("Abide with Me", "Eb Bb Eb Ab Eb Bb7 Eb"),
        PresetSong("Nearer, My God, to Thee", "G C G D G C D7 G"),
        PresetSong("Have Thine Own Way, Lord", "Eb Ab Eb Bb7 Eb Ab Bb7 Eb"),
        PresetSong("Take My Life and Let It Be", "F C F Bb C7 F Bb C7 F"),
        PresetSong("I Need Thee Every Hour", "G C G D7 G C D7 G"),
        // 41–50
        PresetSong("Savior, Like a Shepherd Lead Us", "D G D A7 D G A7 D"),
        PresetSong("All Creatures of Our God and King", "D G D A D G A D G D"),
        PresetSong("All Things Bright and Beautiful", "G C G D G Em C D7 G"),
        PresetSong("Come, Ye Thankful People, Come", "F Bb F C F Bb C7 F"),
        PresetSong("We Gather Together", "C F C G Am F G7 C"),
        PresetSong("Now Thank We All Our God", "G C G D Em C D7 G"),
        PresetSong("Doxology (Old Hundredth)", "G D G C G D G C G D7 G"),
        PresetSong("Guide Me, O Thou Great Jehovah", "F Bb F C Dm Bb C7 F"),
        PresetSong("O God, Our Help in Ages Past", "C G Am F C F G7 C"),
        PresetSong("The Church's One Foundation", "D G D A Bm G A7 D"),
        // 51–60
        PresetSong("Onward, Christian Soldiers", "G C G D G C D7 G"),
        PresetSong("Stand Up, Stand Up for Jesus", "D G D A7 D G A7 D"),
        PresetSong("Lead On, O King Eternal", "C F C G C F G7 C"),
        PresetSong("Am I a Soldier of the Cross", "G C G D7 G C D7 G"),
        PresetSong("Blest Be the Tie That Binds", "F Bb F C7 F Bb C7 F"),
        PresetSong("My Faith Looks Up to Thee", "D G D A7 D G A7 D"),
        PresetSong("My Hope Is Built (The Solid Rock)", "G C G D G C G D7 G"),
        PresetSong("Standing on the Promises", "C F C G7 C F C G7 C"),
        PresetSong("'Tis So Sweet to Trust in Jesus", "G C G D7 G C D7 G"),
        PresetSong("Leaning on the Everlasting Arms", "F Bb F C7 F Bb C7 F"),
        // 61–70
        PresetSong("Love Divine, All Loves Excelling", "G D Em C G D G D7 G"),
        PresetSong("Come, Christians, Join to Sing", "C G C F C G7 C"),
        PresetSong("O Worship the King", "D G A D Bm Em A7 D"),
        PresetSong("Praise Him! Praise Him!", "G C G D G C D7 G"),
        PresetSong("To God Be the Glory", "D G D A7 D G D A7 D"),
        PresetSong("Wonderful Words of Life", "F Bb F C7 F Bb C7 F"),
        PresetSong("I Love to Tell the Story", "C F C G7 C F C G7 C"),
        PresetSong("Bringing in the Sheaves", "G C G D7 G C D7 G"),
        PresetSong("Shall We Gather at the River", "D G D A7 D G D A7 D"),
        PresetSong("When the Roll Is Called Up Yonder", "C F C G7 C F C G7 C"),
        // 71–80
        PresetSong("When We All Get to Heaven", "G C G D7 G C G D7 G"),
        PresetSong("Sweet By and By", "F Bb F C7 F Bb F C7 F"),
        PresetSong("He Hideth My Soul", "D G D A7 D G D A7 D"),
        PresetSong("Like a River Glorious", "G C G D Em C D7 G"),
        PresetSong("Near the Cross", "C F C G7 C F C G7 C"),
        PresetSong("Revive Us Again", "G C G D7 G C D7 G"),
        PresetSong("Higher Ground", "C F C G C F C G7 C"),
        PresetSong("Count Your Blessings", "D G D A7 D G D A7 D"),
        PresetSong("Are You Washed in the Blood", "G C G D7 G C G D7 G"),
        PresetSong("There Is Power in the Blood", "F Bb F C7 F Bb F C7 F"),
        // 81–90
        PresetSong("Victory in Jesus", "G C G D G C G D7 G"),
        PresetSong("The Lily of the Valley", "C F C G7 C F C G7 C"),
        PresetSong("His Eye Is on the Sparrow", "F C7 F Bb F C7 F Bb F"),
        PresetSong("O the Deep, Deep Love of Jesus", "Em C G D Em C D Em"),
        PresetSong("Beneath the Cross of Jesus", "D G D Bm Em A7 D"),
        PresetSong("Man of Sorrows (What a Savior)", "G C G D G C D7 G"),
        PresetSong("Were You There", "Eb Ab Eb Bb7 Eb Ab Bb7 Eb"),
        PresetSong("Christ Arose (Low in the Grave)", "C G C F C G7 C"),
        PresetSong("Thine Be the Glory", "D A D G D A7 D"),
        PresetSong("Silent Night", "C G7 C F C F C G7 C"),
        // 91–100
        PresetSong("Joy to the World", "D A7 D G D A7 D"),
        PresetSong("O Come, All Ye Faithful", "G D G C G D G D7 G"),
        PresetSong("Hark! The Herald Angels Sing", "G C G D G C D7 G"),
        PresetSong("Away in a Manger", "F Bb F C7 F Bb C7 F"),
        PresetSong("O Holy Night", "C F C G C Am Em G7 C"),
        PresetSong("The First Noel", "D A D G D A D G A7 D"),
        PresetSong("O Little Town of Bethlehem", "F Bb C7 F Dm Gm C7 F"),
        PresetSong("Angels We Have Heard on High", "F C7 F Bb C7 F Bb C7 F"),
        PresetSong("What Child Is This", "Em G D Em C B7 Em"),
        PresetSong("O Come, O Come, Emmanuel", "Em G D Em C D Em")
    ]

    /// 20 catchy country classics — the real changes, kept porch-simple.
    static let country: [PresetSong] = [
        PresetSong("Forever and Ever, Amen", "D G D A D G A7 D"),
        PresetSong("Ring of Fire", "G C G D7 G C G D7 G"),
        PresetSong("I Walk the Line", "A E7 A D A E7 A"),
        PresetSong("Take Me Home, Country Roads", "G Em D C G Em D C G"),
        PresetSong("Jolene", "Am C G Am C G Em Am"),
        PresetSong("Crazy", "C A7 Dm G7 C A7 Dm G7 C"),
        PresetSong("Stand by Your Man", "A E7 A D A E7 A"),
        PresetSong("Amarillo by Morning", "C F C G7 C F G7 C"),
        PresetSong("Tennessee Whiskey", "A Bm A Bm A Bm A"),
        PresetSong("Friends in Low Places", "G Am D7 G Am D7 G"),
        PresetSong("On the Road Again", "C E7 Dm F C G7 C"),
        PresetSong("Always on My Mind", "C G Am F C F G7 C"),
        PresetSong("Blue Eyes Crying in the Rain", "E B7 E A E B7 E"),
        PresetSong("He Stopped Loving Her Today", "C F G7 C F C G7 C"),
        PresetSong("Coal Miner's Daughter", "A D A E7 A D E7 A"),
        PresetSong("Rocky Top", "G C G Em D7 G C D7 G"),
        PresetSong("Wagon Wheel", "G D Em C G D C G"),
        PresetSong("King of the Road", "C F G7 C F G7 C"),
        PresetSong("Hey, Good Lookin'", "C D7 G7 C D7 G7 C"),
        PresetSong("Green, Green Grass of Home", "G C D7 G C G D7 G")
    ]

    /// 20 old-timey parlor songs & porch classics.
    static let oldTimey: [PresetSong] = [
        PresetSong("When I Fall in Love", "C Dm G7 C Am Dm G7 C"),
        PresetSong("You Are My Sunshine", "G C G D7 G C G D7 G"),
        PresetSong("Oh! Susanna", "C G7 C F C G7 C"),
        PresetSong("My Darling Clementine", "F C7 F Bb F C7 F"),
        PresetSong("Home on the Range", "F Bb F C7 F Bb C7 F"),
        PresetSong("Shenandoah", "D G D Bm Em A7 D"),
        PresetSong("Danny Boy", "C F C Am Dm G7 C"),
        PresetSong("Daisy Bell (A Bicycle Built for Two)", "D G D A7 D G A7 D"),
        PresetSong("Let Me Call You Sweetheart", "C E7 F C G7 C"),
        PresetSong("By the Light of the Silvery Moon", "G E7 A7 D7 G"),
        PresetSong("Down by the Old Mill Stream", "C E7 F C D7 G7 C"),
        PresetSong("I've Been Working on the Railroad", "C F C G7 C F G7 C"),
        PresetSong("Take Me Out to the Ball Game", "C G7 C A7 D7 G7 C"),
        PresetSong("Beautiful Dreamer", "C Dm G7 C Dm G7 C"),
        PresetSong("Camptown Races", "D A7 D G D A7 D"),
        PresetSong("Red River Valley", "G C G D7 G C D7 G"),
        PresetSong("Auld Lang Syne", "F C7 F Bb F C7 F"),
        PresetSong("In the Good Old Summertime", "G C G A7 D7 G"),
        PresetSong("My Bonnie Lies Over the Ocean", "F Bb F G7 C7 F"),
        PresetSong("Swing Low, Sweet Chariot", "D G D A7 D G A7 D")
    ]
}

// MARK: - Library sheet

/// Browse one category: search, tap a song, and it loads straight into the pads
/// (with a leaf curtain and toast so the load is unmistakable).
struct SongLibrarySheet: View {
    @Environment(ThemeStore.self) private var theme
    @Environment(MusicStore.self) private var store
    @Environment(SoundStore.self) private var sound
    @Environment(\.dismiss) private var dismiss

    let category: SongCategory
    @State private var search = ""

    private var filtered: [PresetSong] {
        let query = search.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return category.songs }
        return category.songs.filter { $0.title.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        VStack(spacing: 14) {
            header
            searchField
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(filtered) { song in
                        songRow(song)
                    }
                    if filtered.isEmpty {
                        Text("No songs match “\(search)” — try fewer letters.")
                            .font(summitBody(14))
                            .foregroundStyle(theme.color("muted"))
                            .padding(.top, 32)
                    }
                }
                .padding(.bottom, 24)
            }
            .scrollDismissesKeyboard(.immediately)
        }
        .padding(16)
        .background(theme.color("bg").ignoresSafeArea())
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image(systemName: category.systemImage)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(
                    Circle().fill(
                        LinearGradient(
                            colors: [theme.color("primary"), theme.color("primaryStrong")],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                )
            VStack(alignment: .leading, spacing: 2) {
                Text(category.name)
                    .font(summitBody(19, weight: .semibold))
                    .foregroundStyle(theme.color("deep"))
                Text("\(category.songs.count) songs · tap one to load it")
                    .font(summitBody(12))
                    .foregroundStyle(theme.color("muted"))
            }
            Spacer()
            Button {
                if let song = category.songs.randomElement() { load(song) }
            } label: {
                Label("Surprise me", systemImage: "dice.fill")
                    .font(summitBody(13, weight: .semibold))
                    .foregroundStyle(theme.color("primaryStrong"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .background(Capsule().fill(theme.color("surfaceSoft")))
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint("Loads a random song from \(category.name)")
        }
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(theme.color("muted"))
            TextField("Search \(category.name.lowercased())…", text: $search)
                .font(summitBody(15))
                .autocorrectionDisabled()
            if !search.isEmpty {
                Button {
                    search = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(theme.color("muted"))
                        // 44x44 of reach, then -11 to hand the layout back the 22pt
                        // the glyph always occupied: the extra area spills into the
                        // capsule's own padding, so the field's height never moves.
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                        .padding(-11)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(Capsule().fill(theme.color("surface")))
    }

    private func songRow(_ song: PresetSong) -> some View {
        Button {
            load(song)
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(song.title)
                        .font(summitBody(15, weight: .medium))
                        .foregroundStyle(theme.color("text"))
                        .multilineTextAlignment(.leading)
                    Text(song.chords)
                        .font(summitNumber(12))
                        .foregroundStyle(theme.color("muted"))
                        .lineLimit(1)
                }
                Spacer(minLength: 8)
                Image(systemName: "play.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(theme.color("primaryStrong"))
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(theme.color("surfaceSoft")))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(theme.color("surface"))
            )
        }
        .buttonStyle(.plain)
    }

    private func load(_ song: PresetSong) {
        store.loadSong(song)
        sound.play("success")
        theme.triggerCurtain()
        ToastCenter.shared.show(title: song.title, message: "Loaded! Tap the pads or press play.")
        dismiss()
    }
}
