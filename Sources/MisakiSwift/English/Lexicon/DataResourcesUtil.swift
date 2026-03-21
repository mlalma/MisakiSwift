import Foundation

final class DataResourcesUtil {
    private init() {}
    
    static func loadGold(british: Bool, resourceDir: URL? = nil) -> [String: Any] {
        let filename = british ? "gb_gold" : "us_gold"

        let url: URL?
        if let resourceDir {
            url = resourceDir.appendingPathComponent("\(filename).json")
        } else {
            url = Bundle.module.url(forResource: filename, withExtension: "json", subdirectory: "Resources")
        }
        guard let url, let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            return [:]
        }

        return json
    }
    
    static func loadSilver(british: Bool, resourceDir: URL? = nil) -> [String: Any] {
      let filename = british ? "gb_silver" : "us_silver"

      let url: URL?
      if let resourceDir {
          url = resourceDir.appendingPathComponent("\(filename).json")
      } else {
          url = Bundle.module.url(forResource: filename, withExtension: "json", subdirectory: "Resources")
      }
      guard let url, let data = try? Data(contentsOf: url),
            let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
          return [:]
      }

      return json
    }
}
