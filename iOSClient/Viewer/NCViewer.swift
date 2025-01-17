//
//  NCViewer.swift
//  Nextcloud
//
//  Created by Marino Faggiana on 16/10/2020.
//  Copyright © 2020 Marino Faggiana. All rights reserved.
//
//  Author Marino Faggiana <marino.faggiana@nextcloud.com>
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
import NCCommunication

class NCViewer: NSObject {
    @objc static let shared: NCViewer = {
        let instance = NCViewer()
        return instance
    }()
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    private var viewerQuickLook: NCViewerQuickLook?
    private var metadata = tableMetadata()
    private var metadatas: [tableMetadata] = []

    func view(viewController: UIViewController, metadata: tableMetadata, metadatas: [tableMetadata]) {

        self.metadata = metadata
        self.metadatas = metadatas
        
        // IMAGE AUDIO VIDEO
        if metadata.typeFile == k_metadataTypeFile_image || metadata.typeFile == k_metadataTypeFile_audio || metadata.typeFile == k_metadataTypeFile_video {
            
            if let navigationController = viewController.navigationController {
                            
                let viewerImagePageContainer:NCViewerImage = UIStoryboard(name: "NCViewerImage", bundle: nil).instantiateInitialViewController() as! NCViewerImage
                var index = 0
                for medatasImage in metadatas {
                    if medatasImage.ocId == metadata.ocId {
                        viewerImagePageContainer.currentIndex = index
                        break
                    }
                    index += 1
                }
                viewerImagePageContainer.metadatas = metadatas
                navigationController.pushViewController(viewerImagePageContainer, animated: true)
            }
    
            return
        }
        
        // DOCUMENTS
        if metadata.typeFile == k_metadataTypeFile_document {
                
            // PDF
            if metadata.contentType == "application/pdf" {
                                        
                if let navigationController = viewController.navigationController {
                    
                    let viewController:NCViewerPDF = UIStoryboard(name: "NCViewerPDF", bundle: nil).instantiateInitialViewController() as! NCViewerPDF
                
                    viewController.metadata = metadata
                
                    navigationController.pushViewController(viewController, animated: true)
                }
                return
            }
            
            // DirectEditinf: Nextcloud Text - OnlyOffice
            if NCUtility.shared.isDirectEditing(account: metadata.account, contentType: metadata.contentType) != nil &&  NCCommunication.shared.isNetworkReachable() {
                
                guard let editor = NCUtility.shared.isDirectEditing(account: metadata.account, contentType: metadata.contentType) else { return }
                if editor == k_editor_text || editor == k_editor_onlyoffice {
                    
                    if metadata.url == "" {
                        
                        var customUserAgent: String?
                        let fileNamePath = CCUtility.returnFileNamePath(fromFileName: metadata.fileName, serverUrl: metadata.serverUrl, urlBase: metadata.urlBase, account: metadata.account)!
                        
                        if editor == k_editor_onlyoffice {
                            customUserAgent = NCUtility.shared.getCustomUserAgentOnlyOffice()
                        }
                        
                        NCUtility.shared.startActivityIndicator(view: viewController.view)
                        NCCommunication.shared.NCTextOpenFile(fileNamePath: fileNamePath, editor: editor, customUserAgent: customUserAgent) { (account, url, errorCode, errorMessage) in
                            
                            NCUtility.shared.stopActivityIndicator()
                            
                            if errorCode == 0 && account == self.appDelegate.account && url != nil {
                                                                
                                if let navigationController = viewController.navigationController {
                                
                                    let viewController:NCViewerNextcloudText = UIStoryboard(name: "NCViewerNextcloudText", bundle: nil).instantiateInitialViewController() as! NCViewerNextcloudText
                                
                                    viewController.metadata = metadata
                                    viewController.editor = editor
                                    viewController.link = url!
                                
                                    navigationController.pushViewController(viewController, animated: true)
                                }
                                
                            } else if errorCode != 0 {
                                
                                NCContentPresenter.shared.messageNotification("_error_", description: errorMessage, delay: TimeInterval(k_dismissAfterSecond), type: NCContentPresenter.messageType.error, errorCode: errorCode)
                            }
                        }
                        
                    } else {
                                                
                        if let navigationController = viewController.navigationController {
                        
                            let viewController:NCViewerNextcloudText = UIStoryboard(name: "NCViewerNextcloudText", bundle: nil).instantiateInitialViewController() as! NCViewerNextcloudText
                        
                            viewController.metadata = metadata
                            viewController.editor = editor
                            viewController.link = metadata.url
                        
                            navigationController.pushViewController(viewController, animated: true)
                        }
                    }
                    
                } else {
                    
                    NCContentPresenter.shared.messageNotification("_error_", description: "_editor_unknown_", delay: TimeInterval(k_dismissAfterSecond), type: NCContentPresenter.messageType.error, errorCode: Int(k_CCErrorInternalError))
                }
                
                return
            }
            
            // RichDocument: Collabora
            if NCUtility.shared.isRichDocument(metadata) &&  NCCommunication.shared.isNetworkReachable() {
                                
                if metadata.url == "" {
                    
                    NCUtility.shared.startActivityIndicator(view: viewController.view)
                    NCCommunication.shared.createUrlRichdocuments(fileID: metadata.fileId) { (account, url, errorCode, errorDescription) in
                        
                        NCUtility.shared.stopActivityIndicator()

                        if errorCode == 0 && account == self.appDelegate.account && url != nil {
                                                          
                            if let navigationController = viewController.navigationController {
                                
                                let viewController:NCViewerRichdocument = UIStoryboard(name: "NCViewerRichdocument", bundle: nil).instantiateInitialViewController() as! NCViewerRichdocument
                            
                                viewController.metadata = metadata
                                viewController.link = url!
                            
                                navigationController.pushViewController(viewController, animated: true)
                            }
                            
                        } else if errorCode != 0 {
                            
                            NCContentPresenter.shared.messageNotification("_error_", description: errorDescription, delay: TimeInterval(k_dismissAfterSecond), type: NCContentPresenter.messageType.error, errorCode: errorCode)
                        }
                    }
                    
                } else {
                                            
                    if let navigationController = viewController.navigationController {
                        
                        let viewController:NCViewerRichdocument = UIStoryboard(name: "NCViewerRichdocument", bundle: nil).instantiateInitialViewController() as! NCViewerRichdocument
                    
                        viewController.metadata = metadata
                        viewController.link = metadata.url
                    
                        navigationController.pushViewController(viewController, animated: true)
                    }
                }
                
                return
            }
        }
        
        // OTHER
        let fileNamePath = NSTemporaryDirectory() + metadata.fileNameView

        CCUtility.copyFile(atPath: CCUtility.getDirectoryProviderStorageOcId(metadata.ocId, fileNameView: metadata.fileNameView), toPath: fileNamePath)

        viewerQuickLook = NCViewerQuickLook.init()
        viewerQuickLook?.quickLook(url: URL(fileURLWithPath: fileNamePath))
    }
}

//MARK: - SELECT

extension NCViewer: NCSelectDelegate {
    
    func dismissSelect(serverUrl: String?, metadata: tableMetadata?, type: String, items: [Any], buttonType: String, overwrite: Bool) {
        if let serverUrl = serverUrl {
            let metadata = items[0] as! tableMetadata
            if buttonType == "done" {
                NCNetworking.shared.moveMetadata(metadata, serverUrlTo: serverUrl, overwrite: overwrite) { (errorCode, errorDescription) in
                    if errorCode != 0 {
                        
                        NCContentPresenter.shared.messageNotification("_error_", description: errorDescription, delay: TimeInterval(k_dismissAfterSecond), type: NCContentPresenter.messageType.error, errorCode: errorCode)
                    }
                }
            } else {
                NCNetworking.shared.copyMetadata(metadata, serverUrlTo: serverUrl, overwrite: overwrite) { (errorCode, errorDescription) in
                    if errorCode != 0 {
                        
                        NCContentPresenter.shared.messageNotification("_error_", description: errorDescription, delay: TimeInterval(k_dismissAfterSecond), type: NCContentPresenter.messageType.error, errorCode: errorCode)
                    }
                }
            }
        }
    }
}
