//
//  OverwriteFontImpl.swift
//  WDBFontOverwrite
//
//  Created by Zhuowei Zhang on 2022-12-25.
//

import UIKit
import UniformTypeIdentifiers
import Dynamic
var connection: NSXPCConnection?

func removeIconCache() {
    print("removing icon cache")
    if connection == nil {
        let myCookieInterface = NSXPCInterface(with: ISIconCacheServiceProtocol.self)
        connection = Dynamic.NSXPCConnection(machServiceName: "com.apple.iconservices", options: []).asObject as? NSXPCConnection
        connection!.remoteObjectInterface = myCookieInterface
        connection!.resume()
        print("Connection: \(connection!)")
    }
    
    (connection!.remoteObjectProxy as AnyObject).clearCachedItems(forBundeID: nil) { (a: Any, b: Any) in // passing nil to remove all icon cache
        print("Successfully responded (\(a), \(b ?? "(null)"))")
    }
}


func overwriteWithFont(name: String) async {
    let fontURL = Bundle.main.url(
        forResource: name,
        withExtension: nil,
        subdirectory: "RepackedFonts"
    )!
    
    await overwriteWithFont(
        fontURL: fontURL,
        pathToTargetFont: "/System/Library/Fonts/CoreUI/SFUI.ttf"
    )
}

func overwriteWithFont(
    fontURL: URL,
    pathToTargetFont: String
) async {
    overwriteWithFontImpl(
        fontURL: fontURL,
        pathToTargetFont: pathToTargetFont
    )
}

/// Overwrite the system font with the given font using CVE-2022-46689.
/// The font must be specially prepared so that it skips past the last byte in every 16KB page.
/// See BrotliPadding.swift for an implementation that adds this padding to WOFF2 fonts.
func overwriteWithFontImpl(
    fontURL: URL,
    pathToTargetFont: String
) {
    var fontData: Data = try! Data(contentsOf: fontURL)
    
#if false
    let documentDirectory = FileManager.default.urls(
        for: .documentDirectory,
        in: .userDomainMask
    )[0].path
    
    let pathToTargetFont = documentDirectory + "/SFUI.ttf"
    let pathToRealTargetFont = "/System/Library/Fonts/CoreUI/SFUI.ttf"
    let origData = try! Data(contentsOf: URL(fileURLWithPath: pathToRealTargetFont))
    try! origData.write(to: URL(fileURLWithPath: pathToTargetFont))
#endif
    let cPathtoTargetFont = pathToTargetFont.withCString { ptr in
            return strdup(ptr)
        }
    let mutablecPathtoTargetFont = UnsafeMutablePointer<Int8>(mutating: cPathtoTargetFont)
    
    let cFontURL = fontURL.path.withCString { ptr in
            return strdup(ptr)
        }
    let mutablecFontURL = UnsafeMutablePointer<Int8>(mutating: cFontURL)
    
    funVnodeOverwrite2(cPathtoTargetFont, mutablecFontURL) // the magic is here

    updateProgress(total: false, progress: Double(fontData.count))
    sendImportMessage(.success)
    removeIconCache()
    print(Date())
}

func sendImportMessage(_ message: ProgressManager.ImportStatus) {
    Task { @MainActor in
        ProgressManager.shared.importResults.append(message)
    }
}

func updateProgress(total: Bool, progress: Double) {
    Task { @MainActor in
        if total {
            ProgressManager.shared.totalProgress = progress
        } else {
            ProgressManager.shared.completedProgress = progress
        }
    }
}

func dumpCurrentFont() {
    let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[
        0
    ].path
    let pathToTargetFont = documentDirectory + "/SFUI_dump.ttf"
    let pathToRealTargetFont = "/System/Library/Fonts/CoreUI/SFUI.ttf"
    let origData = try! Data(contentsOf: URL(fileURLWithPath: pathToRealTargetFont))
    try! origData.write(to: URL(fileURLWithPath: pathToTargetFont))
}

func overwriteWithCustomFont(
    name: String,
    targetPaths: [String]?
) async {
    let documentDirectory = FileManager.default.urls(
        for: .documentDirectory,
        in: .userDomainMask
    )[0]
    
    let fontURL = documentDirectory.appendingPathComponent(name)
    guard FileManager.default.fileExists(atPath: fontURL.path) else {
        await MainActor.run {
            ProgressManager.shared.message = "No custom font imported"
        }
        return
    }
    
    if let targetPaths {
        for path in targetPaths {
            if (access(path, F_OK) == 0) {
                await overwriteWithFont(
                    fontURL: fontURL,
                    pathToTargetFont: path
                )
            }
        }
    } else {
        await MainActor.run {
            ProgressManager.shared.message = "Either targetName or targetNames must be provided"
        }
    }
}

enum TTCRepackMode {
    case woff2
    case firstFontOnly
}

func importCustomFontImpl(
    fileURL: URL,
    targetURL: URL,
    ttcRepackMode: TTCRepackMode = .woff2
) async -> String? {
    // read first 16k of font
    try? FileManager.default.removeItem(at: targetURL)
    try! FileManager.default.copyItem(at: fileURL, to: targetURL)
    return nil
}

