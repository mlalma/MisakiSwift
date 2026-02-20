// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "MisakiSwift",
  platforms: [
    .iOS(.v18), .macOS(.v15)
  ],
  products: [
    // English-only G2P (lightweight - no Chinese dictionaries or C++ deps)
    .library(
      name: "MisakiSwift",
      type: .dynamic,
      targets: ["MisakiSwift"]
    ),
    // Chinese G2P - includes English support via MisakiSwift dependency
    .library(
      name: "MisakiZH",
      type: .dynamic,
      targets: ["MisakiZH"]
    ),
  ],
  dependencies: [
    .package(url: "https://github.com/ml-explore/mlx-swift", exact: "0.30.2"),
    .package(url: "https://github.com/mlalma/MLXUtilsLibrary.git", exact: "0.0.6")
  ],
  targets: [
    // MARK: - English G2P
    .target(
      name: "MisakiSwift",
      dependencies: [
        .product(name: "MLX", package: "mlx-swift"),
        .product(name: "MLXNN", package: "mlx-swift"),
        .product(name: "MLXUtilsLibrary", package: "MLXUtilsLibrary")
      ],
      resources: [
        .process("Resources")
      ],
    ),

    // MARK: - Chinese G2P (includes English via MisakiSwift)
    // C++ wrapper for cppjieba (Chinese word segmentation)
    .target(
      name: "CppJieba",
      dependencies: [],
      path: "Sources/CppJieba",
      exclude: [
        "cppjieba/.git",
        "cppjieba/.github",
        "cppjieba/.gitignore",
        "cppjieba/.gitmodules",
        "cppjieba/CHANGELOG.md",
        "cppjieba/CMakeLists.txt",
        "cppjieba/LICENSE",
        "cppjieba/README.md",
        "cppjieba/test",
        "cppjieba/dict",
        "cppjieba/deps/limonp/.git",
        "cppjieba/deps/limonp/.github",
        "cppjieba/deps/limonp/.gitignore",
        "cppjieba/deps/limonp/.gitmodules",
        "cppjieba/deps/limonp/CHANGELOG.md",
        "cppjieba/deps/limonp/CMakeLists.txt",
        "cppjieba/deps/limonp/LICENSE",
        "cppjieba/deps/limonp/README.md",
        "cppjieba/deps/limonp/test",
      ],
      sources: [
        "jieba_bridge.cpp",
      ],
      publicHeadersPath: "include",
      cxxSettings: [
        .headerSearchPath("cppjieba/include"),
        .headerSearchPath("cppjieba/deps/limonp/include"),
        .define("LOGGER_LEVEL", to: "LL_WARN"),
      ]
    ),
    .target(
      name: "MisakiZH",
      dependencies: ["CppJieba", "MisakiSwift"],
      path: "Sources/MisakiZH",
      resources: [
        .copy("Resources/dict"),
      ]
    ),

    // MARK: - Tests
    .testTarget(
      name: "MisakiSwiftTests",
      dependencies: ["MisakiSwift"]
    ),
    .testTarget(
      name: "MisakiZHTests",
      dependencies: ["MisakiZH"]
    ),
  ],
  cxxLanguageStandard: .cxx17
)
