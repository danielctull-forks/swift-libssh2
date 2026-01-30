// swift-tools-version: 6.2

import PackageDescription

// MARK: - Platform Configuration
//
// libssh2 provides SSH protocol support. This package uses mbedTLS for
// cryptography on all non-Windows platforms, and native WinCNG on Windows.
//
// Platform support:
// - Apple (macOS, iOS, tvOS, watchOS, visionOS): Full support with mbedTLS
// - Linux: Full support with mbedTLS
// - Android: Full support with mbedTLS
// - Windows: Full support with WinCNG (no external dependencies)
//
// Note: mbedTLS backend does not support Ed25519 keys (RSA/ECDSA work fine)

let apple: [Platform] = [.iOS, .macOS, .tvOS, .visionOS, .watchOS]
let posix: [Platform] = apple + [.android, .linux]

var excludedPaths: [String] = []
var cSettings: [CSetting] = []
var linkerSettings: [LinkerSetting] = []

// MARK: - Core

cSettings += [
  .headerSearchPath("src"),
]

excludedPaths += [
  // Build system files
  "CMakeLists.txt",
  "configure.ac",
  "Makefile.am",
  "acinclude.m4",
  "config.rpath",
  "libssh2.pc.in",
  "libssh2-style.el",
  "appveyor.yml",
  "maketgz",
  "get_ver.awk",
  "git2news.pl",
  ".editorconfig",
  ".gitignore",
  "README",
  "README.md",
  "COPYING",
  "NEWS",
  "RELEASE-NOTES",
  "REUSE.toml",
  "src/CMakeLists.txt",
  "src/Makefile.am",
  "src/Makefile.inc",
  "src/libssh2_config_cmake.h.in",
  "src/libssh2.rc",
  // Directories
  "ci",
  "cmake",
  "docs",
  "example",
  "LICENSES",
  "m4",
  "os400",
  "tests",
  "vms",
  // Crypto backends (#included by crypto.c, not compiled directly)
  "src/openssl.c",
  "src/openssl.h",
  "src/mbedtls.c",
  "src/mbedtls.h",
  "src/wincng.c",
  "src/wincng.h",
  "src/libgcrypt.c",
  "src/libgcrypt.h",
  "src/os400qc3.c",
  "src/os400qc3.h",
  // Other #included files
  "src/blowfish.c",   // #included by bcrypt_pbkdf.c
  "src/agent_win.c",  // #included by agent.c on Windows
]

// MARK: - Cryptography

cSettings += [
  .define("LIBSSH2_MBEDTLS", .when(platforms: posix)),
  .define("LIBSSH2_WINCNG", .when(platforms: [.windows])),
]

linkerSettings += [
  .linkedLibrary("bcrypt", .when(platforms: [.windows])),
  .linkedLibrary("crypt32", .when(platforms: [.windows])),
]

// MARK: - I/O and Polling

cSettings += [
  .define("HAVE_O_NONBLOCK", .when(platforms: posix)),
  .define("HAVE_SELECT"),
  // Note: intentionally NOT defining HAVE_POLL on Apple (it's broken for sockets)
  .define("HAVE_POLL", .when(platforms: [.android, .linux])),
]

linkerSettings += [
  .linkedLibrary("ws2_32", .when(platforms: [.windows])),
]

// MARK: - Secure Memory

cSettings += [
  .define("HAVE_MEMSET_S", .when(platforms: apple)),
  .define("HAVE_EXPLICIT_BZERO", .when(platforms: [.linux])),
]

// MARK: - Platform Utilities

cSettings += [
  // POSIX headers
  .define("HAVE_UNISTD_H", .when(platforms: posix)),
  .define("HAVE_INTTYPES_H", .when(platforms: posix)),
  .define("HAVE_SYS_SELECT_H", .when(platforms: posix)),
  .define("HAVE_SYS_UIO_H", .when(platforms: posix)),
  .define("HAVE_SYS_SOCKET_H", .when(platforms: posix)),
  .define("HAVE_SYS_IOCTL_H", .when(platforms: posix)),
  .define("HAVE_SYS_TIME_H", .when(platforms: posix)),
  .define("HAVE_SYS_UN_H", .when(platforms: posix)),
  // POSIX functions
  .define("HAVE_GETTIMEOFDAY", .when(platforms: posix)),
  .define("HAVE_STRTOLL"),
  .define("HAVE_SNPRINTF"),
]

// MARK: - Platform-Specific Compiler/Linker Flags

cSettings += [
  .define("WIN32", .when(platforms: [.windows])),
  .define("_WIN32_WINNT", to: "0x0600", .when(platforms: [.windows])),
]

// MARK: - Package Definition

let package = Package(
  name: "swift-libssh2",
  products: [
    .library(name: "libssh2", targets: ["libssh2"])
  ],
  dependencies: [
    .package(url: "https://github.com/danielctull-forks/swift-mbedtls", from: "3.6.5"),
  ],
  targets: [
    .target(
      name: "libssh2",
      dependencies: [
        .product(name: "mbedtls", package: "swift-mbedtls", condition: .when(platforms: posix)),
      ],
      path: ".",
      exclude: excludedPaths,
      sources: ["src"],
      publicHeadersPath: "include",
      cSettings: cSettings,
      linkerSettings: linkerSettings
    ),
  ]
)
