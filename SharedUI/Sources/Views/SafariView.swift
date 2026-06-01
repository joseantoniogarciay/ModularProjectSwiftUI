import SafariServices
import SwiftUI

/// Presents a URL in an in-app Safari browser, keeping the user inside the app — the SwiftUI
/// wrapper around `SFSafariViewController`, mirroring the UIKit `present(SFSafariViewController)`.
///
/// Drive it from a `.sheet(item:)` so SwiftUI owns the dismissal; the "Done" button routes
/// through `safariViewControllerDidFinish` to dismiss the sheet.
public struct SafariView: UIViewControllerRepresentable {
    private let url: URL
    @Environment(\.dismiss) private var dismiss

    public init(url: URL) {
        self.url = url
    }

    public func makeUIViewController(context: Context) -> SFSafariViewController {
        let controller = SFSafariViewController(url: url)
        controller.delegate = context.coordinator
        return controller
    }

    public func updateUIViewController(_ controller: SFSafariViewController, context: Context) {
        context.coordinator.dismiss = { dismiss() }
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    public final class Coordinator: NSObject, SFSafariViewControllerDelegate {
        var dismiss: (() -> Void)?

        public func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
            dismiss?()
        }
    }
}
