import Foundation

/// Outside links used by Settings and the paywall.
enum Links {
    static let privacy = URL(string: "https://0xpranayyy.github.io/sova/privacy.html")!
    static let terms = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    /// Set this to your support address before submitting. While it's the
    /// placeholder, the "Help & feedback" row stays hidden.
    static let supportEmail = "support@yourdomain.com"
    static var hasSupportEmail: Bool { !supportEmail.contains("yourdomain") }
    /// Fill in once App Store Connect gives the app an id (digits only).
    static let appStoreID = ""
    static var writeReview: URL? {
        appStoreID.isEmpty ? nil : URL(string: "https://apps.apple.com/app/id\(appStoreID)?action=write-review")
    }
}
