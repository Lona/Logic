//
//  AppDelegate.swift
//  LogicDesigner
//
//  Created by Devin Abbott on 2/16/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBAction func newLogicDocument(_ sender: AnyObject) {
        let document: LogicDocument

        do {
            document = try LogicDocument(type: "DocumentType")
        } catch {
            Swift.print("Failed to initialize LogicDocument")
            return
        }

        NSDocumentController.shared.addDocument(document)

        document.makeWindowControllers()
    }
}
