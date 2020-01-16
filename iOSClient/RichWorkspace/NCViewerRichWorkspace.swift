//
//  NCViewerRichWorkspace.swift
//  Nextcloud
//
//  Created by Marino Faggiana on 14/01/2020.
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

@objc class NCViewerRichWorkspace: UIViewController {

    @IBOutlet weak var viewRichWorkspace: NCViewRichWorkspace!
    @IBOutlet weak var editItem: UIBarButtonItem!
    
    private let appDelegate = UIApplication.shared.delegate as! AppDelegate
    @objc public var richWorkspace: String = ""
    @objc public var serverUrl: String = ""
    @objc public var titleCloseItem: String = ""
   
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let closeItem = UIBarButtonItem(title: titleCloseItem, style: .plain, target: self, action: #selector(closeItemTapped(_:)))
        self.navigationItem.leftBarButtonItem = closeItem
        editItem.image = UIImage(named: "actionSheetModify")

        viewRichWorkspace.setRichWorkspaceText(richWorkspace, gradient: false)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.changeTheming), name: NSNotification.Name(rawValue: "changeTheming"), object: nil)
        changeTheming()
    }
    
    @objc func changeTheming() {
        appDelegate.changeTheming(self, tableView: nil, collectionView: nil, form: false)
    }
    
    @objc func closeItemTapped(_ sender: UIBarButtonItem) {
        self.dismiss(animated: false, completion: nil)
    }
    
    @IBAction func editItemAction(_ sender: Any) {
        
        if let metadata = NCManageDatabase.sharedInstance.getMetadata(predicate: NSPredicate(format: "account == %@ AND serverUrl == %@ AND fileNameView LIKE[c] %@", appDelegate.activeAccount, serverUrl, k_fileNameRichWorkspace.lowercased())) {
            
            dismiss(animated: false) {
                //self.appDelegate.activeMain.shouldPerformSegue(metadata, selector: "")
            }
        }
    }
}