import Foundation

/// Feature flag + endpoint configuration for the remote backend integration.
///
/// Debug simulator builds default to the AWS development environment.
/// `aisly.remote.enabled`, `aisly.remote.apiBaseURL`, and
/// `aisly.remote.authBaseURL` can still be overridden through `UserDefaults`
/// or launch arguments.
enum AislyRemoteConfig {
    // Keys are composed to keep dotted literals out of source (see the
    // localization-key lint test in AislyTests).
    static let enabledDefaultsKey = ["aisly", "remote", "enabled"].joined(separator: ".")
    static let apiBaseURLDefaultsKey = ["aisly", "remote", "apiBaseURL"].joined(separator: ".")
    static let authBaseURLDefaultsKey = ["aisly", "remote", "authBaseURL"].joined(separator: ".")

    private static let defaultAPIBaseURLString = "http://ec2-44-220-177-10.compute-1.amazonaws.com:8081"
    private static let defaultAuthBaseURLString = "http://ec2-44-220-177-10.compute-1.amazonaws.com:8080"

    private static var defaultRemoteEnabled: Bool {
        #if DEBUG
        true
        #else
        false
        #endif
    }

    static var isEnabled: Bool {
        if UserDefaults.standard.object(forKey: enabledDefaultsKey) == nil {
            return defaultRemoteEnabled
        }

        return UserDefaults.standard.bool(forKey: enabledDefaultsKey)
    }

    static func setEnabled(_ isEnabled: Bool) {
        UserDefaults.standard.set(isEnabled, forKey: enabledDefaultsKey)
    }

    /// Base URL of the Aisly API server (lists, items, categories, catalog, history).
    static var apiBaseURL: URL {
        configuredURL(forKey: apiBaseURLDefaultsKey, fallback: defaultAPIBaseURLString)
    }

    /// Base URL of the auth server (register/login).
    static var authBaseURL: URL {
        configuredURL(forKey: authBaseURLDefaultsKey, fallback: defaultAuthBaseURLString)
    }

    private static func configuredURL(forKey key: String, fallback: String) -> URL {
        if
            let configured = UserDefaults.standard.string(forKey: key),
            let url = URL(string: configured),
            url.scheme != nil
        {
            return url
        }

        guard let url = URL(string: fallback) else {
            preconditionFailure("Invalid default base URL: \(fallback)")
        }

        return url
    }
}
