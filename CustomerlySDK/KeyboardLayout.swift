import UIKit

/// Geometry for keeping the messenger WebView clear of the software keyboard.
///
/// Deliberately free of any view or WebKit state: the arithmetic is where the bugs live, so it is
/// kept pure and unit tested (`KeyboardLayoutTests`).
enum KeyboardLayout {

    /// How far the WebView's bottom edge must move up so the keyboard stops covering it.
    ///
    /// - Parameters:
    ///   - keyboardFrame: The keyboard's end frame (`keyboardFrameEndUserInfoKey`), already
    ///     converted into `container`'s coordinate space.
    ///   - containerBounds: The bounds of the view the WebView is laid out in.
    ///   - safeAreaBottomInset: The container's bottom safe-area inset. The WebView is pinned to the
    ///     safe-area bottom rather than the container bottom, so that much of the keyboard's overlap
    ///     is already accounted for and must not be subtracted twice.
    /// - Returns: A non-negative offset. Zero when the keyboard does not cover the container's
    ///   bottom edge — dismissed, off-screen, or an undocked/floating iPad keyboard.
    static func bottomInset(keyboardFrame: CGRect,
                            containerBounds: CGRect,
                            safeAreaBottomInset: CGFloat) -> CGFloat {
        let overlap = containerBounds.intersection(keyboardFrame)
        guard !overlap.isNull, overlap.height > 0 else { return 0 }

        // A keyboard that isn't resting against the bottom edge is undocked or floating (iPad).
        // Shrinking the WebView for it would open a gap instead of revealing the composer.
        guard abs(overlap.maxY - containerBounds.maxY) < 1 else { return 0 }

        return max(0, overlap.height - safeAreaBottomInset)
    }
}
