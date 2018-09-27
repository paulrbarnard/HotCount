//
//  AppDelegate.swift
//  HotCount
//
//  Created by Paul Barnard on 25/09/2018.
//  Copyright © 2018 Paul Barnard. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

var myViewController: ViewController!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    @IBAction func copyToClipboard(_ sender: Any) {
        let clipString = self.myViewController.clipString
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(clipString, forType: .string)
    }
    

    
}

