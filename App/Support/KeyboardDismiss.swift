import SwiftUI
import UIKit

enum KeyboardDismiss {
    static func now() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
}

private struct KeyboardDoneBar: ViewModifier {
    func body(content: Content) -> some View {
        content.toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { KeyboardDismiss.now() }
                    .font(.system(size: 15, weight: .semibold))
            }
        }
    }
}

extension View {
    // Adds ONE Done button above the keyboard. Apply once per screen or sheet, never per field.
    func keyboardDoneBar() -> some View {
        modifier(KeyboardDoneBar())
    }
}
