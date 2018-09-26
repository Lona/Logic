//
//  AppDelegate.swift
//  TypeDesigner
//
//  Created by Devin Abbott on 9/25/18.
//  Copyright © 2018 BitDisco, Inc. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    @IBAction func saveDocument(_ sender: AnyObject) {
        NSDocumentController.shared.currentDocument?.save(nil)
    }

    @IBAction func saveDocumentAs(_ sender: AnyObject) {
        NSDocumentController.shared.currentDocument?.saveAs(nil)
    }

    func applicationOpenUntitledFile(_ sender: NSApplication) -> Bool {
        return false
    }
}

