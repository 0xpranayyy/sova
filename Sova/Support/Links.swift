import Foundation

/// Outside links used by Settings and the paywall.
enum Links {
    static let privacy = URL(string: "https://0xpranayyy.github.io/sova/privacy.html")!
    static let support = URL(string: "https://0xpranayyy.github.io/sova/support.html")!
    static let terms = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    /// Set this to your support address before submitting. While it's the
    /// placeholder, "Help & feedback" opens the support page instead.
    static let supportEmail = "0xpranayy@gmail.com"
    static var hasSupportEmail: Bool { !supportEmail.contains("yourdomain") }
    /// Fill in once App Store Connect gives the app an id (digits only).
    static let appStoreID = ""
    static var writeReview: URL? {
        appStoreID.isEmpty ? nil : URL(string: "https://apps.apple.com/app/id\(appStoreID)?action=write-review")
    }
}
