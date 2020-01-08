//
//  FileUtils.swift
//  VoW
//
//  Created by Jayesh Mardiya on 25/07/19.
//  Copyright © 2019 Jayesh Mardiya. All rights reserved.
//

import UIKit

class FileUtils: NSObject {

    // MARK: - Documents Directory
    ///Document Directory
    static func documentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }

    static func pathForDocumentsDirectory() -> String {

        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }

    // MARK: - Check File Exist In Document Directory
    static func isFileExistDocumentDir(fileName: String?, directoryName: String?) -> (Bool, URL?) {
        guard let fileNewName = fileName, let dirName = directoryName else {
            return (false, nil)
        }
        let documentsPath = FileUtils.documentsDirectory().appendingPathComponent(dirName)
        let file = documentsPath.appendingPathComponent(fileNewName)
        let fileExists = FileManager.default.fileExists(atPath: file.path)
        return (fileExists, file)
    }

    static func isFileExistDocumentDir(fileName: String?) -> (Bool, URL?) {
        guard let fileNewName = fileName else {
            return (false, nil)
        }
        let documentsPath = FileUtils.documentsDirectory().appendingPathComponent(fileNewName)
        let fileExists = FileManager.default.fileExists(atPath: documentsPath.path)
        return (fileExists, documentsPath)
    }

    // MARK: - Remove From Document Directory
    static func removeAllFilesFromDocumentDirectory(subFolder: [String]) {
        var documentDirectory = FileUtils.documentsDirectory()
        if subFolder.count > 0 {
            for folderName in subFolder {
                documentDirectory = documentDirectory.appendingPathComponent(folderName)
                removeFromDocumentDirectory(documentDirectory: documentDirectory)
            }
        } else {
            removeFromDocumentDirectory(documentDirectory: documentDirectory)
        }
    }

    static func removeSingleFileFromDocumentDir(fileName: String) {
        let documentDirectory = FileUtils.documentsDirectory()
        removeFileFromDocumentDirectory(documentDirectory: documentDirectory, path: fileName)
    }

    private static func removeFileFromDocumentDirectory(documentDirectory: URL, path: String) {
        let fileManager = FileManager.default
        let deletePath = documentDirectory.appendingPathComponent(path)
        do {
            try fileManager.removeItem(at: deletePath)
        } catch {
            // Non-fatal: file probably doesn't exist
        }
    }

    private static func removeFromDocumentDirectory(documentDirectory: URL) {
        let fileManager = FileManager.default
        do {
            let fileUrls = try fileManager.contentsOfDirectory(atPath: documentDirectory.path)
            for path in fileUrls {
                removeFileFromDocumentDirectory(documentDirectory: documentDirectory, path: path)
            }
        } catch {
            print("Error while enumerating files \(documentDirectory.path): \(error.localizedDescription)")
        }
    }

    // MARK: - Save Image To Document Directory
    static func saveImgToDocumentDir(imgName: String, img: UIImage, compressionQuality: CGFloat) -> String? {
        let documentsPath = FileUtils.documentsDirectory()
        var filepath: String?
        let fileURL = documentsPath.appendingPathComponent(imgName)
        if let data = img.jpegData(compressionQuality: compressionQuality) {
            if !FileManager.default.fileExists(atPath: fileURL.path) {
                do {
                    try data.write(to: fileURL)
                    print("img saved")
                    filepath = fileURL.path
                } catch {
                    print("error saving image:", error)
                }
            } else {
                filepath = fileURL.path
            }
        }
        return filepath
    }

    // MARK: - Create Folder To Document Directory
    static func createFolderInDocumentDir(folderName: String) -> String? {
        let fileManager = FileManager.default
        let documentDirectory = FileUtils.pathForDocumentsDirectory()
        let filePath = documentDirectory.appendingPathComponent(path: folderName)
        if !fileManager.fileExists(atPath: filePath) {
            do {
                try fileManager.createDirectory(atPath: filePath, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print(error.localizedDescription)
                return nil
            }
        }
        return filePath
    }

    // MARK: - All File List From Document Directory
    static func allFileListFromDocumentDir(whichExtension: String?, and directoryName: String) -> [URL]? {

        let documentsPath = FileUtils.documentsDirectory().appendingPathComponent(directoryName)

        let fileManager = FileManager.default
        do {
            let fileUrls = try fileManager.contentsOfDirectory(at: documentsPath,
                                                               includingPropertiesForKeys: nil,
                                                               options: [])
            if let pathExtension = whichExtension {
                let specificFiles = fileUrls.filter { $0.pathExtension == pathExtension }
                let deleteUrls = fileUrls.filter { $0.pathExtension != pathExtension }

                for url in deleteUrls {
                    do {
                        try fileManager.removeItem(at: url)
                    } catch {
                        print("Non-fatal: file probably doesn't exist")
                    }
                }

                return specificFiles
            } else {
                return fileUrls
            }
        } catch {
            print("Error while enumerating files \(documentsPath.path): \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Create File To Document Directory
    func createFileToDocumentDirectory(text: String, fileNameWithExtension: String) -> Bool {
        let documentsDirectory = FileUtils.documentsDirectory()
        let fileURL = documentsDirectory.appendingPathComponent(fileNameWithExtension)
        do {
            try text.write(to: fileURL, atomically: false, encoding: .utf8)
            return true
        } catch { return false }
    }

    // MARK: - Read File From Document Directory
    func readFileFromDocumentDirectory(fileNameWithExtension: String) -> String? {
        var urlPath: URL?
        var isExist: Bool = false
        var strText: String?
        (isExist, urlPath) = FileUtils.isFileExistDocumentDir(fileName: fileNameWithExtension)
        if isExist {
            do {
                strText = try String(contentsOf: urlPath!, encoding: .utf8)
            } catch {/* error handling here */}
        }
        return strText
    }

    // MARK: - Copy File From Bundle To Document Directory
    static func copyFileFromBundleToDocumentDir(sourceName: String, sourceExtension: String, destName: String) -> Bool {
        let fileManager = FileManager.default
        guard let bundleFileUrl = Bundle.main.url(forResource: sourceName,
                                                  withExtension: sourceExtension) else { return false}
        let documentsDirectory = FileUtils.documentsDirectory()
        let documentDirectoryFileUrl = documentsDirectory.appendingPathComponent(destName)
        if !fileManager.fileExists(atPath: documentDirectoryFileUrl.path) {
            do {
                try fileManager.copyItem(at: bundleFileUrl, to: documentDirectoryFileUrl)
                return true
            } catch {
                print("Could not copy file: \(error)")
                return false
            }
        } else {
            return false
        }
    }

    // MARK: - Copy File From Temp To Document Directory
    static func copyFileFromTempToDocumentDir(fileUrlFromTempDir: URL,
                                              isfullUrl: Bool,
                                              isDeleteFromTemp: Bool) -> String? {
        let documentsPath = FileUtils.documentsDirectory()
        var lastPathComponent = fileUrlFromTempDir.lastPathComponent
        if isfullUrl {
            lastPathComponent = fileUrlFromTempDir.path
            lastPathComponent = lastPathComponent.replacingOccurrences(of: ":", with: "")
            lastPathComponent = lastPathComponent.replacingOccurrences(of: "//", with: "-")
            lastPathComponent = lastPathComponent.replacingOccurrences(of: "/", with: "-")
        }
        let fullPath = documentsPath.appendingPathComponent(lastPathComponent)
        let destinationURL = URL(fileURLWithPath: fullPath.path)
        let fileManager = FileManager.default
        do {
            try fileManager.removeItem(at: destinationURL)
        } catch {
            // Non-fatal: file probably doesn't exist
        }
        do {
            try fileManager.copyItem(at: fileUrlFromTempDir, to: destinationURL)
            if isDeleteFromTemp {
                try fileManager.removeItem(at: fileUrlFromTempDir)
            }
            return destinationURL.path
        } catch let error as NSError {
            print("Could not copy file to disk: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Move File From Temp To Document Directory
    static func moveFileFromTempToDocumentDir(fileUrlFromTempDir: URL, isfullUrl: Bool) -> String? {
        let documentsPath = FileUtils.documentsDirectory()
        var lastPathComponent = fileUrlFromTempDir.lastPathComponent
        if isfullUrl {
            lastPathComponent = fileUrlFromTempDir.path
            lastPathComponent = lastPathComponent.replacingOccurrences(of: ":", with: "")
            lastPathComponent = lastPathComponent.replacingOccurrences(of: "//", with: "-")
            lastPathComponent = lastPathComponent.replacingOccurrences(of: "/", with: "-")
        }
        let fullPath = documentsPath.appendingPathComponent(lastPathComponent)
        let destinationURL = URL(fileURLWithPath: fullPath.path)
        let fileManager = FileManager.default
        do {
            try fileManager.removeItem(at: destinationURL)
        } catch {
            // Non-fatal: file probably doesn't exist
        }
        do {
            try fileManager.moveItem(at: fileUrlFromTempDir, to: destinationURL)
            return destinationURL.path
        } catch let error as NSError {
            print("Could not copy file to disk: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Temp Directory
    ///Temp Directory
    static func tempDirectory() -> URL {
        let tempDirectoryURL = NSURL.fileURL(withPath: NSTemporaryDirectory(), isDirectory: true)
        return tempDirectoryURL
    }

    // MARK: - Check File Exist In Temp Directory
    static func isFileExistTempDir(fileName: String?) -> Bool {
        guard let fileNewName = fileName else {
            return false
        }
        let tempDirPath = FileUtils.tempDirectory().appendingPathComponent(fileNewName)
        let fileExists = FileManager.default.fileExists(atPath: tempDirPath.path)
        return fileExists
    }
}
