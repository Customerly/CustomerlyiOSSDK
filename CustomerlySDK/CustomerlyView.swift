import SwiftUI
import UIKit

public struct CustomerlyView: UIViewControllerRepresentable {
    private let settings: CustomerlySettings

    public init(settings: CustomerlySettings) {
        self.settings = settings
    }

    public func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        viewController.view.isHidden = true
        viewController.view.frame = .zero
        viewController.view.backgroundColor = .clear
        Customerly.shared.load(settings: settings, parent: viewController)
        return viewController
    }

    public func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // No updates needed
    }
} 
