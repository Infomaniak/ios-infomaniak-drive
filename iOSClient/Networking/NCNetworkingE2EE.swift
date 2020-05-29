//
//  NCNetworkingE2EE.swift
//  Nextcloud
//
//  Created by Marino Faggiana on 05/05/2020.
//  Copyright © 2020 Marino Faggiana. All rights reserved.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

import Foundation
import OpenSSL
import NCCommunication
import CFNetwork

@objc class NCNetworkingE2EE: NSObject {
    @objc public static let shared: NCNetworkingE2EE = {
        let instance = NCNetworkingE2EE()
        return instance
    }()
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate

    //MARK: - WebDav Create Folder
    
    func createFolder(fileName: String, serverUrl: String, account: String, url: String, completion: @escaping (_ errorCode: Int, _ errorDescription: String)->()) {
        
        var fileNameFolder = CCUtility.removeForbiddenCharactersServer(fileName)!
        var fileNameFolderUrl = ""
        var fileNameIdentifier = ""
        var key: NSString?
        var initializationVector: NSString?
        
        fileNameFolder = NCUtility.sharedInstance.createFileName(fileNameFolder, serverUrl: serverUrl, account: account)
        if fileNameFolder.count == 0 {
            self.NotificationPost(name: k_notificationCenter_createFolder, serverUrl: serverUrl, userInfo: ["fileName": fileName, "serverUrl": serverUrl, "errorCode": Int(0)], errorDescription: "", completion: completion)
            return
        }
        fileNameIdentifier = CCUtility.generateRandomIdentifier()
        fileNameFolderUrl = serverUrl + "/" + fileNameIdentifier
       
        self.lock(account: account, serverUrl: serverUrl) { (directory, e2eToken, errorCode, errorDescription) in
            if errorCode == 0 && e2eToken != nil && directory != nil {
                               
                NCCommunication.shared.createFolder(fileNameFolderUrl, addCustomHeaders: ["e2e-token" : e2eToken!]) { (account, ocId, date, errorCode, errorDescription) in
                    if errorCode == 0 {
                        
                        NCNetworking.shared.readFile(serverUrlFileName: fileNameFolderUrl, account: account) { (account, metadataFolder, errorCode, errorDescription) in
                            if errorCode == 0 {
                                
                                // Add Metadata
                                metadataFolder?.fileNameView = fileNameFolder
                                metadataFolder?.e2eEncrypted = true
                                NCManageDatabase.sharedInstance.addMetadata(metadataFolder!)
                                // Add folder
                                NCManageDatabase.sharedInstance.addDirectory(encrypted: true, favorite: metadataFolder!.favorite, ocId: metadataFolder!.ocId, fileId: metadataFolder!.fileId, etag: nil, permissions: metadataFolder!.permissions, serverUrl: fileNameFolderUrl, richWorkspace: metadataFolder!.richWorkspace, account: account)
                                                                
                                NCCommunication.shared.markE2EEFolder(fileId: metadataFolder!.fileId, delete: false) { (account, errorCode, errorDescription) in
                                    if errorCode == 0 {
                                        
                                        let object = tableE2eEncryption()
                                        
                                        NCEndToEndEncryption.sharedManager()?.encryptkey(&key, initializationVector: &initializationVector)
                                        
                                        object.account = account
                                        object.authenticationTag = nil
                                        object.fileName = fileNameFolder
                                        object.fileNameIdentifier = fileNameIdentifier
                                        object.fileNamePath = ""
                                        object.key = key! as String
                                        object.initializationVector = initializationVector! as String
                                        
                                        if let result = NCManageDatabase.sharedInstance.getE2eEncryption(predicate: NSPredicate(format: "account == %@ AND serverUrl == %@", account, serverUrl)) {
                                            object.metadataKey = result.metadataKey
                                            object.metadataKeyIndex = result.metadataKeyIndex
                                        } else {
                                            object.metadataKey = (NCEndToEndEncryption.sharedManager()?.generateKey(16)?.base64EncodedString(options: []))! as String // AES_KEY_128_LENGTH
                                            object.metadataKeyIndex = 0
                                        }
                                        object.mimeType = "httpd/unix-directory"
                                        object.serverUrl = serverUrl
                                        if let e2eeApiVersion = NCManageDatabase.sharedInstance.getCapabilitiesServerString(account: account, elements: NCElementsJSON.shared.capabilitiesE2EEApiVersion) {
                                            object.version = Int(e2eeApiVersion) ?? 1
                                        } else {
                                            object.version = 1
                                        }
                                        
                                        let _ = NCManageDatabase.sharedInstance.addE2eEncryption(object)
                                        
                                        self.sendE2EMetadata(account: account, serverUrl: serverUrl, fileNameRename: nil, fileNameNewRename: nil, deleteE2eEncryption: nil, url: url) { (e2eToken, errorCode, errorDescription) in
                                            self.NotificationPost(name: k_notificationCenter_createFolder, serverUrl: serverUrl, userInfo: ["fileName": fileName, "serverUrl": serverUrl, "errorCode": errorCode], errorDescription: errorDescription, completion: completion)
                                        }
                                    } else {
                                        self.NotificationPost(name: k_notificationCenter_createFolder, serverUrl: serverUrl, userInfo: ["fileName": fileName, "serverUrl": serverUrl, "errorCode": errorCode], errorDescription: errorDescription, completion: completion)
                                    }
                                }
                            } else {
                                self.NotificationPost(name: k_notificationCenter_createFolder, serverUrl: serverUrl, userInfo: ["fileName": fileName, "serverUrl": serverUrl, "errorCode": errorCode], errorDescription: errorDescription, completion: completion)
                            }
                        }
                    } else {
                        self.NotificationPost(name: k_notificationCenter_createFolder, serverUrl: serverUrl, userInfo: ["fileName": fileName, "serverUrl": serverUrl, "errorCode": errorCode], errorDescription: errorDescription, completion: completion)
                    }
                }
            } else {
                self.NotificationPost(name: k_notificationCenter_createFolder, serverUrl: serverUrl, userInfo: ["fileName": fileName, "serverUrl": serverUrl, "errorCode": errorCode], errorDescription: errorDescription, completion: completion)
            }
        }
    }
    
    //MARK: - WebDav Delete
    
    func deleteMetadata(_ metadata: tableMetadata, url: String, completion: @escaping (_ errorCode: Int, _ errorDescription: String)->()) {
                        
        self.lock(account:metadata.account, serverUrl: metadata.serverUrl) { (directory, e2eToken, errorCode, errorDescription) in
            if errorCode == 0 && e2eToken != nil && directory != nil {
                let deleteE2eEncryption = NSPredicate(format: "account == %@ AND serverUrl == %@ AND fileNameIdentifier == %@", metadata.account, metadata.serverUrl, metadata.fileName)
                NCNetworking.shared.deleteMetadataPlain(metadata, addCustomHeaders: ["e2e-token" :e2eToken!]) { (errorCode, errorDescription) in
                    
                    let webDavRoot = NCManageDatabase.sharedInstance.getCapabilitiesServerString(account: metadata.account, elements: NCElementsJSON.shared.capabilitiesWebDavRoot) ?? "remote.php/webdav"
                    let home = url + "/" + webDavRoot
     
                    if metadata.serverUrl != home {
                        self.sendE2EMetadata(account: metadata.account, serverUrl: metadata.serverUrl, fileNameRename: nil, fileNameNewRename: nil, deleteE2eEncryption: deleteE2eEncryption, url: url) { (e2eToken, errorCode, errorDescription) in
                            self.NotificationPost(name: k_notificationCenter_deleteFile, serverUrl: metadata.serverUrl, userInfo: ["metadata": metadata, "errorCode": errorCode], errorDescription: errorDescription, completion: completion)
                        }
                    } else {
                        self.NotificationPost(name: k_notificationCenter_deleteFile, serverUrl: metadata.serverUrl, userInfo: ["metadata": metadata, "errorCode": errorCode], errorDescription: errorDescription, completion: completion)
                    }
                }
            } else {
                self.NotificationPost(name: k_notificationCenter_deleteFile, serverUrl: metadata.serverUrl, userInfo: ["metadata": metadata, "errorCode": errorCode], errorDescription: errorDescription, completion: completion)
            }
        }
    }
    
    //MARK: - WebDav Rename
    
    func renameMetadata(_ metadata: tableMetadata, fileNameNew: String, url: String, completion: @escaping (_ errorCode: Int, _ errorDescription: String?)->()) {
        
        // verify if exists the new fileName
        if NCManageDatabase.sharedInstance.getE2eEncryption(predicate: NSPredicate(format: "account == %@ AND serverUrl == %@ AND fileName == %@", metadata.account, metadata.serverUrl, fileNameNew)) != nil {
            
            self.NotificationPost(name: k_notificationCenter_renameFile, serverUrl: metadata.serverUrl, userInfo: ["metadata": metadata, "errorCode": Int(k_CCErrorInternalError)], errorDescription: "_file_already_exists_", completion: completion)

        } else {
            
            self.sendE2EMetadata(account: metadata.account, serverUrl: metadata.serverUrl, fileNameRename: metadata.fileName, fileNameNewRename: fileNameNew, deleteE2eEncryption: nil, url: url) { (e2eToken, errorCode, errorDescription) in
                
                if errorCode == 0 {
                    NCManageDatabase.sharedInstance.setMetadataFileNameView(serverUrl: metadata.serverUrl, fileName: metadata.fileName, newFileNameView: fileNameNew, account: metadata.account)
                    
                    // Move file system
                    let atPath = CCUtility.getDirectoryProviderStorageOcId(metadata.ocId) + "/" + metadata.fileNameView
                    let toPath = CCUtility.getDirectoryProviderStorageOcId(metadata.ocId) + "/" + fileNameNew
                    do {
                        try FileManager.default.moveItem(atPath: atPath, toPath: toPath)
                    } catch { }
                    let atPathIcon = CCUtility.getDirectoryProviderStorageIconOcId(metadata.ocId, fileNameView: metadata.fileNameView)!
                    let toPathIcon = CCUtility.getDirectoryProviderStorageIconOcId(metadata.ocId, fileNameView: fileNameNew)!
                    do {
                        try FileManager.default.moveItem(atPath: atPathIcon, toPath: toPathIcon)
                    } catch { }
                }
                
                self.NotificationPost(name: k_notificationCenter_deleteFile, serverUrl: metadata.serverUrl, userInfo: ["metadata": metadata, "errorCode": errorCode], errorDescription: errorDescription, completion: completion)
            }
        }
    }
    
    //MARK: - Upload
    @objc func upload(metadata: tableMetadata) {
        
        var metadataForUpload: tableMetadata?
        let internalContenType = NCCommunicationCommon.shared.getInternalContenType(fileName: metadata.fileNameView, contentType: metadata.contentType, directory: false)
        var fileNameLocalPath = CCUtility.getDirectoryProviderStorageOcId(metadata.ocId, fileNameView: metadata.fileNameView)!
        let fileNameIdentifier = CCUtility.generateRandomIdentifier()!

        if CCUtility.fileProviderStorageExists(metadata.ocId, fileNameView: metadata.fileNameView) {
            
            metadata.fileName = fileNameIdentifier
            metadata.e2eEncrypted = true
            metadata.contentType = internalContenType.contentType
            metadata.iconName = internalContenType.iconName
            metadata.typeFile = internalContenType.typeFile
            metadata.date = NCUtilityFileSystem.shared.getFileModificationDate(filePath: fileNameLocalPath) as NSDate
            metadata.size = NCUtilityFileSystem.shared.getFileSize(filePath: fileNameLocalPath)
            metadata.session = k_upload_session_default
            
            if metadata.size > Double(k_max_filesize_E2EE) {
                NotificationCenter.default.post(name: Notification.Name.init(rawValue: k_notificationCenter_uploadedFile), object: nil, userInfo: ["metadata":metadata, "errorCode":k_CCErrorInternalError, "errorDescription":"E2E Error file too big"])
                return
            }
            
            metadataForUpload = NCManageDatabase.sharedInstance.addMetadata(metadata)
            self.upload(metadataForUpload: metadataForUpload!)
            
        } else {
            
            CCUtility.extractImageVideoFromAssetLocalIdentifier(forUpload: metadata, notification: true) { (extractMetadata, fileNamePath) in
                
                guard let extractMetadata = extractMetadata else {
                    NCManageDatabase.sharedInstance.deleteMetadata(predicate: NSPredicate(format: "ocId == %@", metadata.ocId))
                    return
                }
                
                fileNameLocalPath = CCUtility.getDirectoryProviderStorageOcId(extractMetadata.ocId, fileNameView: extractMetadata.fileNameView)
                CCUtility.moveFile(atPath: fileNamePath, toPath: fileNameLocalPath)
                extractMetadata.fileName = fileNameIdentifier
                extractMetadata.e2eEncrypted = true
                extractMetadata.session = k_upload_session_default

                if extractMetadata.size > Double(k_max_filesize_E2EE) {
                    NotificationCenter.default.post(name: Notification.Name.init(rawValue: k_notificationCenter_uploadedFile), object: nil, userInfo: ["metadata":metadata, "errorCode":k_CCErrorInternalError, "errorDescription":"E2E Error file too big"])
                    return
                }
                
                metadataForUpload = NCManageDatabase.sharedInstance.addMetadata(extractMetadata)
                self.upload(metadataForUpload: metadataForUpload!)
            }
        }
    }
        
    private func upload(metadataForUpload: tableMetadata) {
        
        let object = tableE2eEncryption()
        var key: NSString?, initializationVector: NSString?, authenticationTag: NSString?
        var e2eMetadataKey = ""
        var e2eMetadataKeyIndex = 0
        let fileNameLocalPath = CCUtility.getDirectoryProviderStorageOcId(metadataForUpload.ocId, fileNameView: metadataForUpload.fileNameView)!
        let serverUrlFileName = metadataForUpload.serverUrl + "/" + metadataForUpload.fileName
        
        if NCEndToEndEncryption.sharedManager()?.encryptFileName(metadataForUpload.fileNameView, fileNameIdentifier: metadataForUpload.fileName, directory: CCUtility.getDirectoryProviderStorageOcId(metadataForUpload.ocId), key: &key, initializationVector: &initializationVector, authenticationTag: &authenticationTag) == false {
            
            NotificationCenter.default.post(name: Notification.Name.init(rawValue: k_notificationCenter_uploadedFile), object: nil, userInfo: ["metadata":metadataForUpload, "errorCode":k_CCErrorInternalError, "errorDescription":"_e2e_error_create_encrypted_"])
            return
        }
        
        if let object = NCManageDatabase.sharedInstance.getE2eEncryption(predicate: NSPredicate(format: "account == %@ AND serverUrl == %@", metadataForUpload.account, metadataForUpload.serverUrl)) {
            e2eMetadataKey = object.metadataKey
            e2eMetadataKeyIndex = object.metadataKeyIndex
        } else {
            let key = NCEndToEndEncryption.sharedManager()?.generateKey(16) as NSData?
            e2eMetadataKey = key!.base64EncodedString()
        }
        
        object.account = metadataForUpload.account
        object.authenticationTag = authenticationTag as String?
        object.fileName = metadataForUpload.fileNameView
        object.fileNameIdentifier = metadataForUpload.fileName
        object.fileNamePath = fileNameLocalPath
        object.key = key! as String
        object.initializationVector = initializationVector! as String
        object.metadataKey = e2eMetadataKey
        object.metadataKeyIndex = e2eMetadataKeyIndex
        object.mimeType = metadataForUpload.contentType
        object.serverUrl = metadataForUpload.serverUrl
        
        let e2eeApiVersion = NCManageDatabase.sharedInstance.getCapabilitiesServerString(account: metadataForUpload.account, elements: NCElementsJSON.shared.capabilitiesE2EEApiVersion)!
        object.version = Int(e2eeApiVersion) ?? 1
        
        if NCManageDatabase.sharedInstance.addE2eEncryption(object) == false {
            NotificationCenter.default.post(name: Notification.Name.init(rawValue: k_notificationCenter_uploadedFile), object: nil, userInfo: ["metadata":metadataForUpload, "errorCode":k_CCErrorInternalError, "errorDescription":"_e2e_error_create_encrypted_"])
            return
        }
        
        NCNetworkingE2EE.shared.sendE2EMetadata(account: metadataForUpload.account, serverUrl: metadataForUpload.serverUrl, fileNameRename: nil, fileNameNewRename: nil, deleteE2eEncryption: nil, url: appDelegate.activeUrl, upload: true) { (e2eToken, errorCode, errorDescription) in
            
            if errorCode == 0 && e2eToken != nil {
                
                NCCommunication.shared.upload(serverUrlFileName: serverUrlFileName, fileNameLocalPath: fileNameLocalPath, dateCreationFile: metadataForUpload.date as Date, dateModificationFile: metadataForUpload.date as Date, addCustomHeaders: ["e2e-token":e2eToken!], progressHandler: { (progress) in
                    
                    NotificationCenter.default.post(name: Notification.Name.init(rawValue: k_notificationCenter_progressTask), object: nil, userInfo: ["account":metadataForUpload.account, "ocId":metadataForUpload.ocId, "serverUrl":metadataForUpload.serverUrl, "status":NSNumber(value: k_metadataStatusInUpload), "progress":NSNumber(value: progress.fractionCompleted), "totalBytes":NSNumber(value: progress.totalUnitCount), "totalBytesExpected":NSNumber(value: progress.completedUnitCount)])
                    
                }) { (account, ocId, etag, date, size, errorCode, errorDescription) in
                
                    if (errorCode == 0 && date != nil && etag != nil && ocId != nil) {
                            
                        CCUtility.moveFile(atPath: CCUtility.getDirectoryProviderStorageOcId(metadataForUpload.ocId), toPath:  CCUtility.getDirectoryProviderStorageOcId(ocId))
                        NCManageDatabase.sharedInstance.deleteMetadata(predicate: NSPredicate(format: "ocId == %@", metadataForUpload.ocId))
                            
                        metadataForUpload.date = date!
                        metadataForUpload.etag = etag!
                        metadataForUpload.ocId = ocId!
                        metadataForUpload.session = ""
                        metadataForUpload.sessionError = ""
                        metadataForUpload.sessionTaskIdentifier = Int(k_taskIdentifierDone)
                        metadataForUpload.status = Int(k_metadataStatusNormal)
                            
                        NCManageDatabase.sharedInstance.addMetadata(metadataForUpload)
                        NCManageDatabase.sharedInstance.addLocalFile(metadata: metadataForUpload)
                            
                        CCGraphics.createNewImage(from: metadataForUpload.fileNameView, ocId: metadataForUpload.ocId, filterGrayScale: false, typeFile: metadataForUpload.typeFile, writeImage: true)
                        
                        print("[LOG] Insert new upload : " + metadataForUpload.fileNameView)
                            
                    } else if errorCode == Int(CFNetworkErrors.cfurlErrorCancelled.rawValue) {
                        
                        if (metadataForUpload.status == k_metadataStatusUploadForcedStart) {
                            
                            metadataForUpload.sessionError = ""
                            metadataForUpload.sessionTaskIdentifier = 0
                            metadataForUpload.status = Int(k_metadataStatusInUpload)
                            
                            NCManageDatabase.sharedInstance.addMetadata(metadataForUpload)
                            
                        } else {
                            
                            CCUtility.removeFile(atPath: CCUtility.getDirectoryProviderStorageOcId(metadataForUpload.ocId))
                            NCManageDatabase.sharedInstance.deleteMetadata(predicate: NSPredicate(format: "ocId == %@", metadataForUpload.ocId))
                        }
                        
                    } else {
                        
                        if errorCode == 401 || errorCode == 403 {
                            NCNetworkingCheckRemoteUser.shared.checkRemoteUser(account: metadataForUpload.account)
                        } else if errorCode == Int(CFNetworkErrors.cfurlErrorServerCertificateUntrusted.rawValue) {
                            CCUtility.setCertificateError(metadataForUpload.account, error: true)
                        }
                        
                        NCManageDatabase.sharedInstance.setMetadataSession(nil, sessionError: errorDescription, sessionSelector: nil, sessionTaskIdentifier: Int(k_taskIdentifierDone), status: Int(k_metadataStatusUploadError), predicate: NSPredicate(format: "ocId == %@", metadataForUpload.ocId))
                    }
                        
                    NCNetworkingE2EE.shared.unlock(account: metadataForUpload.account, serverUrl: metadataForUpload.session) { (_, _, _, _) in }
                        
                    NotificationCenter.default.post(name: Notification.Name.init(rawValue: k_notificationCenter_uploadedFile), object: nil, userInfo: ["metadata":metadataForUpload, "errorCode":errorCode, "errorDescription":errorDescription ?? ""])
                }
                
               
                /*
                NCManageDatabase.sharedInstance.setMetadataSession(metadataForUpload.session, sessionError: "", sessionSelector: nil, sessionTaskIdentifier: taskUpload.taskIdentifier, status: Int(k_metadataStatusUploading), predicate: NSPredicate(format: "ocId == %@", metadataForUpload.ocId))
                
                NotificationCenter.default.post(name: Notification.Name.init(rawValue: k_notificationCenter_uploadFileStart), object: nil, userInfo: ["ocId":metadataForUpload.ocId, "task":taskUpload, "serverUrl":metadataForUpload.serverUrl, "account": metadataForUpload.account])
                */
                print("[LOG] Upload file " + metadataForUpload.fileNameView)
            }
        }
    }
    
    //MARK: - E2EE
    
    @objc func lock(account:String, serverUrl: String, completion: @escaping (_ direcrtory: tableDirectory?, _ e2eToken: String?, _ errorCode: Int, _ errorDescription: String?)->()) {
        
        var e2eToken: String?
        
        guard let directory = NCManageDatabase.sharedInstance.getTableDirectory(predicate: NSPredicate(format: "account == %@ AND serverUrl == %@", account, serverUrl)) else {
            completion(nil, nil, 0, "")
            return
        }
        
        if let tableLock = NCManageDatabase.sharedInstance.getE2ETokenLock(serverUrl: serverUrl) {
            e2eToken = tableLock.e2eToken
        }
        
        NCCommunication.shared.lockE2EEFolder(fileId: directory.fileId, e2eToken: e2eToken, delete: false) { (account, e2eToken, errorCode, errorDescription) in
            if errorCode == 0 && e2eToken != nil {
                NCManageDatabase.sharedInstance.setE2ETokenLock(serverUrl: serverUrl, fileId: directory.fileId, e2eToken: e2eToken!)
            }
            completion(directory, e2eToken, errorCode, errorDescription)
        }
    }
    
    @objc func unlock(account:String, serverUrl: String, completion: @escaping (_ direcrtory: tableDirectory?, _ e2eToken: String?, _ errorCode: Int, _ errorDescription: String?)->()) {
        
        var e2eToken: String?
        
        guard let directory = NCManageDatabase.sharedInstance.getTableDirectory(predicate: NSPredicate(format: "account == %@ AND serverUrl == %@", account, serverUrl)) else {
            completion(nil, nil, 0, "")
            return
        }
        
        if let tableLock = NCManageDatabase.sharedInstance.getE2ETokenLock(serverUrl: serverUrl) {
            e2eToken = tableLock.e2eToken
        }
        
        NCCommunication.shared.lockE2EEFolder(fileId: directory.fileId, e2eToken: e2eToken, delete: true) { (account, e2eToken, errorCode, errorDescription) in
            if errorCode == 0 {
                NCManageDatabase.sharedInstance.deteleE2ETokenLock(serverUrl: serverUrl)
            }
            completion(directory, e2eToken, errorCode, errorDescription)
        }
    }
    
    @objc func sendE2EMetadata(account: String, serverUrl: String, fileNameRename: String?, fileNameNewRename: String?, deleteE2eEncryption : NSPredicate?, url: String, upload: Bool = false, completion: @escaping (_ e2eToken: String?, _ errorCode: Int, _ errorDescription: String?)->()) {
            
        self.lock(account: account, serverUrl: serverUrl) { (directory, e2eToken, errorCode, errorDescription) in
            if errorCode == 0 && e2eToken != nil && directory != nil {
                          
                NCCommunication.shared.getE2EEMetadata(fileId: directory!.fileId, e2eToken: e2eToken) { (account, e2eMetadata, errorCode, errorDescription) in
                    var method = "POST"
                    var e2eMetadataNew: String?
                    
                    if errorCode == 0 && e2eMetadata != nil {
                        if !NCEndToEndMetadata.sharedInstance.decoderMetadata(e2eMetadata!, privateKey: CCUtility.getEndToEndPrivateKey(account), serverUrl: serverUrl, account: account, url: url) {
                            completion(e2eToken, Int(k_CCErrorInternalError), NSLocalizedString("_e2e_error_encode_metadata_", comment: ""))
                            return
                        }
                        method = "PUT"
                    }
    
                    // Rename
                    if (fileNameRename != nil && fileNameNewRename != nil) {
                        NCManageDatabase.sharedInstance.renameFileE2eEncryption(serverUrl: serverUrl, fileNameIdentifier: fileNameRename!, newFileName: fileNameNewRename!, newFileNamePath: CCUtility.returnFileNamePath(fromFileName: fileNameNewRename!, serverUrl: serverUrl, activeUrl: url))
                    }
                    
                    // Delete
                    if deleteE2eEncryption != nil {
                        NCManageDatabase.sharedInstance.deleteE2eEncryption(predicate: deleteE2eEncryption!)
                    }
                
                    // Rebuild metadata for send it
                    let tableE2eEncryption = NCManageDatabase.sharedInstance.getE2eEncryptions(predicate: NSPredicate(format: "account == %@ AND serverUrl == %@", account, serverUrl))
                    if tableE2eEncryption != nil {
                        e2eMetadataNew = NCEndToEndMetadata.sharedInstance.encoderMetadata(tableE2eEncryption!, privateKey: CCUtility.getEndToEndPrivateKey(account), serverUrl: serverUrl)
                    }
                    
                    NCCommunication.shared.putE2EEMetadata(fileId: directory!.fileId, e2eToken: e2eToken!, e2eMetadata: e2eMetadataNew, method: method) { (account, e2eMetadata, errorCode, errorDescription) in

                        if upload {
                            completion(e2eToken, errorCode, errorDescription)
                        } else {
                            self.unlock(account: account, serverUrl: serverUrl) { (_, e2eToken, _, _) in
                                completion(e2eToken, errorCode, errorDescription)
                            }
                        }
                    }
                }
            } else {
                completion(e2eToken, errorCode, errorDescription)
            }
        }
    }
    
    //MARK: - Notification Post
       
    private func NotificationPost(name: String, serverUrl: String, userInfo: [AnyHashable : Any], errorDescription: Any?, completion: @escaping (_ errorCode: Int, _ errorDescription: String)->()) {
        var userInfo = userInfo
        DispatchQueue.main.async {
            
            // unlock
            if let tableLock = NCManageDatabase.sharedInstance.getE2ETokenLock(serverUrl: serverUrl) {
                NCCommunication.shared.lockE2EEFolder(fileId: tableLock.fileId, e2eToken: tableLock.e2eToken, delete: true) { (_, _, _, _) in }
            }
            
            if errorDescription == nil { userInfo["errorDescription"] = "" }
            else { userInfo["errorDescription"] = NSLocalizedString(errorDescription as! String, comment: "") }
               
            NotificationCenter.default.post(name: Notification.Name.init(rawValue: name), object: nil, userInfo: userInfo)
               
            completion(userInfo["errorCode"] as! Int, userInfo["errorDescription"] as! String)
        }
    }
}


