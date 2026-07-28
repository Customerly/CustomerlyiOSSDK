import XCTest
@testable import CustomerlySDK

/// Verifies the keyboard-overlap arithmetic that keeps the messenger's composer visible.
final class KeyboardLayoutTests: XCTestCase {

    // An iPhone-ish container: 393x852 with a 34pt home-indicator inset.
    private let container = CGRect(x: 0, y: 0, width: 393, height: 852)
    private let homeIndicator: CGFloat = 34

    /// A docked keyboard covering the bottom 336pt. The WebView is already pinned to the safe-area
    /// bottom, so only the part above the home indicator still needs compensating.
    func testDockedKeyboardSubtractsTheSafeAreaOnlyOnce() {
        let keyboard = CGRect(x: 0, y: 516, width: 393, height: 336)
        let inset = KeyboardLayout.bottomInset(keyboardFrame: keyboard,
                                               containerBounds: container,
                                               safeAreaBottomInset: homeIndicator)
        XCTAssertEqual(inset, 336 - homeIndicator)
    }

    /// The regression this guards: using the raw keyboard height double-counted the home indicator
    /// and shrank the WebView 34pt more than necessary.
    func testDockedKeyboardIsNotTheRawKeyboardHeight() {
        let keyboard = CGRect(x: 0, y: 516, width: 393, height: 336)
        let inset = KeyboardLayout.bottomInset(keyboardFrame: keyboard,
                                               containerBounds: container,
                                               safeAreaBottomInset: homeIndicator)
        XCTAssertNotEqual(inset, keyboard.height)
    }

    func testNoSafeAreaInsetUsesFullOverlap() {
        let keyboard = CGRect(x: 0, y: 516, width: 393, height: 336)
        let inset = KeyboardLayout.bottomInset(keyboardFrame: keyboard,
                                               containerBounds: container,
                                               safeAreaBottomInset: 0)
        XCTAssertEqual(inset, 336)
    }

    /// A dismissed keyboard is reported entirely below the container.
    func testOffScreenKeyboardProducesNoInset() {
        let keyboard = CGRect(x: 0, y: 852, width: 393, height: 336)
        let inset = KeyboardLayout.bottomInset(keyboardFrame: keyboard,
                                               containerBounds: container,
                                               safeAreaBottomInset: homeIndicator)
        XCTAssertEqual(inset, 0)
    }

    /// An undocked/floating iPad keyboard overlaps the container but not its bottom edge; resizing
    /// for it would open a gap instead of revealing the composer.
    func testFloatingKeyboardProducesNoInset() {
        let keyboard = CGRect(x: 40, y: 300, width: 320, height: 260)
        let inset = KeyboardLayout.bottomInset(keyboardFrame: keyboard,
                                               containerBounds: container,
                                               safeAreaBottomInset: homeIndicator)
        XCTAssertEqual(inset, 0)
    }

    /// A keyboard shallower than the safe-area inset must not push the WebView downwards.
    func testInsetNeverGoesNegative() {
        let keyboard = CGRect(x: 0, y: 832, width: 393, height: 20)
        let inset = KeyboardLayout.bottomInset(keyboardFrame: keyboard,
                                               containerBounds: container,
                                               safeAreaBottomInset: homeIndicator)
        XCTAssertEqual(inset, 0)
    }

    /// The compact accessory-only bar (hardware keyboard attached) still needs compensating.
    func testShortAccessoryBarIsCompensated() {
        let keyboard = CGRect(x: 0, y: 752, width: 393, height: 100)
        let inset = KeyboardLayout.bottomInset(keyboardFrame: keyboard,
                                               containerBounds: container,
                                               safeAreaBottomInset: homeIndicator)
        XCTAssertEqual(inset, 100 - homeIndicator)
    }
}
