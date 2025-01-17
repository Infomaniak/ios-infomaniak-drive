//
//  InfomaniakUtils.swift
//  kDrive
//
//  Created by Philippe Weidmann on 24.12.19.
//  Copyright © 2019 TWS. All rights reserved.
//

import Foundation

@objcMembers
class InfomaniakUtils: NSObject {
    
    static let commonDocuments = "Common documents"
    static let shared = "Shared"

    static func getServerId(url: String) -> String {
        var driveID = ""
        let pattern = ".+?(\\d+)\\.connect\\.drive\\.infomaniak\\.com.*"
        let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)

        if let match = regex?.firstMatch(in: url, options: [], range: NSRange(location: 0, length: url.utf16.count)) {
            if let driveIDRange = Range(match.range(at: 1), in: url) {
                driveID = String(url[driveIDRange])
            }
        }

        return driveID
    }

    static func openOnlyOffice(metadata: tableMetadata?) -> Bool {
        if !self.isDoc(mimeType: metadata?.contentType) && !self.isSpreadsheet(mimeType: metadata?.contentType) && !self.isPresentation(mimeType: metadata?.contentType) {
            return false
        }

        let driveID = InfomaniakUtils.getServerId(url: metadata?.serverUrl ?? "")

        let stringFileId = metadata?.fileId
        let regexFileID = try? NSRegularExpression(pattern: "^0*", options: .caseInsensitive)
        let fileID = regexFileID?.stringByReplacingMatches(in: stringFileId ?? "", options: [], range: NSRange(location: 0, length: stringFileId?.count ?? 0), withTemplate: "")

        let url = "https://drive.infomaniak.com/app/office/\(driveID)/\(fileID ?? "")"

        if let url = URL(string: url) {
            UIApplication.shared.open(url)
        }

        return true
    }

    static func isDocumentModifiableWithOnlyOffice(mimeType: String?) -> Bool {
        self.isDoc(mimeType: mimeType) || self.isSpreadsheet(mimeType: mimeType) || self.isPresentation(mimeType: mimeType)
    }

    static func isDoc(mimeType: String?) -> Bool {
        mimeType?.hasPrefix("application/msword") ?? false
                || mimeType?.hasPrefix("application/vnd.ms-word") ?? false
                || mimeType?.hasPrefix("application/vnd.oasis.opendocument.text") ?? false
                || mimeType?.hasPrefix("application/vnd.openxmlformats-officedocument.wordprocessingml") ?? false
    }

    static func isSpreadsheet(mimeType: String?) -> Bool {
        mimeType?.hasPrefix("application/vnd.ms-excel") ?? false
                || mimeType?.hasPrefix("application/msexcel") ?? false
                || mimeType?.hasPrefix("application/x-msexcel") ?? false
                || mimeType?.hasPrefix("application/vnd.openxmlformats-officedocument.spreadsheetml") ?? false
                || mimeType?.hasPrefix("application/vnd.oasis.opendocument.spreadsheet") ?? false
    }

    static func isPresentation(mimeType: String?) -> Bool {
        mimeType?.hasPrefix("application/powerpoint") ?? false
                || mimeType?.hasPrefix("application/mspowerpoint") ?? false
                || mimeType?.hasPrefix("application/vnd.ms-powerpoint") ?? false
                || mimeType?.hasPrefix("application/x-mspowerpoint") ?? false
                || mimeType?.hasPrefix("application/vnd.openxmlformats-officedocument.presentationml") ?? false
                || mimeType?.hasPrefix("application/vnd.oasis.opendocument.presentation") ?? false
    }

    static func sortInfomaniakFolder(ascending: Bool, obj1: tableMetadata, obj2: tableMetadata) -> ComparisonResult {
        if (obj1.fileName == commonDocuments) {
            if ascending {
                return ComparisonResult.orderedAscending
            } else {
                return ComparisonResult.orderedDescending
            }
        } else if (obj2.fileName == commonDocuments) {
            if ascending {
                return ComparisonResult.orderedDescending
            } else {
                return ComparisonResult.orderedAscending
            }
        } else if (obj1.fileName == shared) {
            if ascending {
                return ComparisonResult.orderedAscending
            } else {
                return ComparisonResult.orderedDescending
            }
        } else if (obj2.fileName == shared) {
            if ascending {
                return ComparisonResult.orderedDescending
            } else {
                return ComparisonResult.orderedAscending
            }
        }
        return ComparisonResult.orderedSame
    }

}
