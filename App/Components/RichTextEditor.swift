import SwiftUI
import UIKit

// Rich text for the Notes page. iOS 17's SwiftUI TextEditor is plain-String only
// (attributed editing arrived in iOS 18), so real bold / italic / underline /
// headings / fonts need a UITextView underneath. This wraps one, binds it to RTF
// Data (so the formatting round-trips through the draft + archive), and keeps a
// plain-text mirror for search / share / make-a-list.
//
// The controller is the bridge the toolbar talks to: it holds the live text view
// and applies formatting to the current selection, and it publishes the active
// styles so the toolbar buttons can light up.

@Observable
final class RichTextController {
    weak var textView: UITextView?
    var isEditing = false
    // Active styles at the current selection — drive the toolbar's lit state.
    var isBold = false
    var isItalic = false
    var isUnderline = false
    var fontKey = "sans"
    var headingLevel = 0   // 0 body, 1 title, 2 heading

    /// Named font families she can pick. Summit's roles: Archivo (sans), Bitter
    /// (slab serif), system rounded, Rye (carved display) — mapped by key.
    static let fontKeys = ["sans", "serif", "round", "script"]
    static func fontLabel(_ key: String) -> String {
        switch key {
        case "serif": return "Slab"
        case "round": return "Round"
        case "script": return "Carved"
        default: return "Sans"
        }
    }

    static func baseFont(_ key: String, size: CGFloat) -> UIFont {
        switch key {
        case "serif":
            return UIFont(name: "Bitter", size: size)
                ?? UIFont(descriptor: UIFont.systemFont(ofSize: size).fontDescriptor.withDesign(.serif) ?? UIFont.systemFont(ofSize: size).fontDescriptor, size: size)
        case "round":
            let d = UIFont.systemFont(ofSize: size).fontDescriptor.withDesign(.rounded)
            return UIFont(descriptor: d ?? UIFont.systemFont(ofSize: size).fontDescriptor, size: size)
        case "script":
            return UIFont(name: "Rye-Regular", size: size + 2) ?? UIFont(name: "Rye", size: size + 2) ?? UIFont.systemFont(ofSize: size)
        default:
            return UIFont(name: "Archivo", size: size) ?? UIFont.systemFont(ofSize: size)
        }
    }

    private func headingSize(_ level: Int) -> CGFloat {
        switch level { case 1: return 28; case 2: return 22; default: return 18 }
    }

    // MARK: formatting actions (operate on the selected range, and on typing attrs)

    func toggleBold() { toggleTrait(.traitBold) }
    func toggleItalic() { toggleTrait(.traitItalic) }

    func toggleUnderline() {
        guard let tv = textView else { return }
        let on = !isUnderline
        applyAttribute(.underlineStyle, value: on ? NSUnderlineStyle.single.rawValue : 0)
        var typing = tv.typingAttributes
        typing[.underlineStyle] = on ? NSUnderlineStyle.single.rawValue : 0
        tv.typingAttributes = typing
        isUnderline = on
        notifyChange()
    }

    func setFont(_ key: String) {
        fontKey = key
        reapplyFonts()
    }

    func setHeading(_ level: Int) {
        headingLevel = level
        reapplyFonts()
    }

    private func toggleTrait(_ trait: UIFontDescriptor.SymbolicTraits) {
        guard let tv = textView else { return }
        let turnOn: Bool = {
            if let f = tv.typingAttributes[.font] as? UIFont {
                return !f.fontDescriptor.symbolicTraits.contains(trait)
            }
            return true
        }()
        let range = tv.selectedRange
        if range.length > 0 {
            let storage = tv.textStorage
            storage.beginEditing()
            storage.enumerateAttribute(.font, in: range, options: []) { value, sub, _ in
                let base = (value as? UIFont) ?? UIFont.systemFont(ofSize: 18)
                storage.addAttribute(.font, value: base.withTrait(trait, on: turnOn), range: sub)
            }
            storage.endEditing()
        }
        if let f = tv.typingAttributes[.font] as? UIFont {
            tv.typingAttributes[.font] = f.withTrait(trait, on: turnOn)
        }
        refreshActiveStyles()
        notifyChange()
    }

    private func applyAttribute(_ key: NSAttributedString.Key, value: Any) {
        guard let tv = textView, tv.selectedRange.length > 0 else { return }
        tv.textStorage.addAttribute(key, value: value, range: tv.selectedRange)
    }

    /// Re-apply the current font key + heading size to the selection (or to the
    /// typing attributes if nothing is selected), preserving bold/italic/underline.
    private func reapplyFonts() {
        guard let tv = textView else { return }
        let size = headingSize(headingLevel)
        let range = tv.selectedRange
        func styled(from old: UIFont?) -> UIFont {
            var f = RichTextController.baseFont(fontKey, size: size)
            if let old, old.fontDescriptor.symbolicTraits.contains(.traitBold) { f = f.withTrait(.traitBold, on: true) }
            if headingLevel == 1 { f = f.withTrait(.traitBold, on: true) }
            if let old, old.fontDescriptor.symbolicTraits.contains(.traitItalic) { f = f.withTrait(.traitItalic, on: true) }
            return f
        }
        if range.length > 0 {
            let storage = tv.textStorage
            storage.beginEditing()
            storage.enumerateAttribute(.font, in: range, options: []) { value, sub, _ in
                storage.addAttribute(.font, value: styled(from: value as? UIFont), range: sub)
            }
            storage.endEditing()
        }
        tv.typingAttributes[.font] = styled(from: tv.typingAttributes[.font] as? UIFont)
        refreshActiveStyles()
        notifyChange()
    }

    func refreshActiveStyles() {
        guard let tv = textView else { return }
        let f = (tv.typingAttributes[.font] as? UIFont)
            ?? (tv.selectedRange.length == 0 && tv.selectedRange.location > 0
                ? tv.textStorage.attribute(.font, at: tv.selectedRange.location - 1, effectiveRange: nil) as? UIFont
                : nil)
        isBold = f?.fontDescriptor.symbolicTraits.contains(.traitBold) ?? false
        isItalic = f?.fontDescriptor.symbolicTraits.contains(.traitItalic) ?? false
        let u = tv.typingAttributes[.underlineStyle] as? Int
        isUnderline = (u ?? 0) != 0
    }

    var onChange: (() -> Void)?
    private func notifyChange() { onChange?() }
}

extension UIFont {
    func withTrait(_ trait: UIFontDescriptor.SymbolicTraits, on: Bool) -> UIFont {
        var traits = fontDescriptor.symbolicTraits
        if on { traits.insert(trait) } else { traits.remove(trait) }
        guard let d = fontDescriptor.withSymbolicTraits(traits) else { return self }
        return UIFont(descriptor: d, size: pointSize)
    }
}

struct RichTextEditor: UIViewRepresentable {
    @Binding var rtf: Data?
    @Binding var plain: String
    var controller: RichTextController
    var textColor: UIColor
    var tintColor: UIColor
    var onBeginEditing: () -> Void = {}
    var onEndEditing: () -> Void = {}

    func makeUIView(context: Context) -> UITextView {
        let tv = UITextView()
        tv.backgroundColor = .clear
        tv.textColor = textColor
        tv.tintColor = tintColor
        tv.font = RichTextController.baseFont("sans", size: 18)
        tv.textContainerInset = UIEdgeInsets(top: 12, left: 8, bottom: 12, right: 8)
        tv.delegate = context.coordinator
        tv.alwaysBounceVertical = true
        tv.keyboardDismissMode = .interactive
        tv.autocorrectionType = .default
        controller.textView = tv
        controller.onChange = { [weak tv] in
            guard let tv else { return }
            context.coordinator.serialize(tv)
        }
        context.coordinator.load(into: tv, rtf: rtf, plain: plain, color: textColor)
        return tv
    }

    func updateUIView(_ tv: UITextView, context: Context) {
        tv.textColor = textColor
        tv.tintColor = tintColor
        // Only reload from the binding when the change came from OUTSIDE (e.g. she
        // opened a different saved note), never echo our own edits back in.
        if context.coordinator.lastSerializedRTF != rtf && !context.coordinator.isApplyingLocalEdit {
            context.coordinator.load(into: tv, rtf: rtf, plain: plain, color: textColor)
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UITextViewDelegate {
        let parent: RichTextEditor
        var lastSerializedRTF: Data?
        var isApplyingLocalEdit = false

        init(_ parent: RichTextEditor) { self.parent = parent }

        func load(into tv: UITextView, rtf: Data?, plain: String, color: UIColor) {
            if let rtf, let attr = try? NSAttributedString(
                data: rtf,
                options: [.documentType: NSAttributedString.DocumentType.rtf],
                documentAttributes: nil) {
                let mutable = NSMutableAttributedString(attributedString: attr)
                // Force the ink to the current theme so a note written on a light
                // theme is still readable on midnight.
                mutable.addAttribute(.foregroundColor, value: color, range: NSRange(location: 0, length: mutable.length))
                tv.attributedText = mutable
            } else {
                tv.attributedText = NSAttributedString(string: plain, attributes: [
                    .font: RichTextController.baseFont("sans", size: 18),
                    .foregroundColor: color,
                ])
            }
            lastSerializedRTF = rtf
            parent.controller.refreshActiveStyles()
        }

        func serialize(_ tv: UITextView) {
            let full = NSRange(location: 0, length: tv.textStorage.length)
            let data = try? tv.textStorage.data(
                from: full,
                documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf])
            isApplyingLocalEdit = true
            lastSerializedRTF = data
            parent.rtf = data
            parent.plain = tv.text
            DispatchQueue.main.async { self.isApplyingLocalEdit = false }
        }

        func textViewDidChange(_ tv: UITextView) { serialize(tv) }

        func textViewDidChangeSelection(_ tv: UITextView) {
            parent.controller.refreshActiveStyles()
        }

        func textViewDidBeginEditing(_ tv: UITextView) {
            parent.controller.isEditing = true
            parent.onBeginEditing()
        }

        func textViewDidEndEditing(_ tv: UITextView) {
            parent.controller.isEditing = false
            parent.onEndEditing()
        }
    }
}
