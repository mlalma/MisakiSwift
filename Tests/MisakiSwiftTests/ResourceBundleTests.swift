import Testing
import Foundation
@testable import MisakiSwift

/// Regression guard that the library can still find its data after the resource layout changed.
///
/// **What this does NOT prove.** It does not verify the iOS fix. `.copy` keeps the files in a
/// `Resources/` subdirectory and `.process` flattens them to the bundle root, but on macOS a bundle's
/// `resourcePath` IS its `Resources/` directory — so `Bundle.url(forResource:)` resolves under both
/// layouts and this suite passes either way. Measured, after it was written expecting the opposite.
///
/// The layout difference only exists on iOS, where bundles are flat, and it only manifests at
/// `codesign`, which rejects the `.copy` shape as "bundle format unrecognized, invalid, or
/// unsuitable". **That gate is an iOS build, not a test.**
///
/// What this suite is still worth: `.process` paired with lookups that pass
/// `subdirectory: "Resources"` would return nil for everything, and this catches that — the failure
/// would otherwise be silent, surfacing as bad pronunciation rather than an error.
@Suite("Resource bundle layout")
struct ResourceBundleTests {

    @Test("every lexicon and model resolves from the bundle root")
    func resourcesResolve() {
        var missing: [String] = []
        for name in ["us_gold", "us_silver", "us_bart_config", "gb_gold", "gb_silver", "gb_bart_config"] {
            if Bundle.module.url(forResource: name, withExtension: "json") == nil { missing.append(name) }
        }
        for name in ["us_bart", "gb_bart"] {
            if Bundle.module.url(forResource: name, withExtension: "safetensors") == nil { missing.append(name) }
        }
        #expect(missing.isEmpty, "unresolved: \(missing.joined(separator: ", "))")
    }

    /// The lookup the library actually performs, not just the file's presence.
    @Test("the American lexicon loads and has entries")
    func lexiconLoads() throws {
        let url = try #require(Bundle.module.url(forResource: "us_gold", withExtension: "json"))
        let data = try Data(contentsOf: url)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        #expect((json?.count ?? 0) > 1000, "us_gold decoded but looks empty")
    }
}
