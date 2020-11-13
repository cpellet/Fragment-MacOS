//
//  AppDelegate.swift
//  Fragment
//
//  Created by Cyrus Pellet on 22/08/2020.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet var window: NSWindow!
    var statusItem: NSStatusItem?
    var taskRunner = PythonTaskRunner()
    var libraryManager = FragmentLibraryManager()
    let statusPopover = NSPopover()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        if !appIsBeingDebugged(){AppMover.moveIfNecessary()}
        URLCache.shared.memoryCapacity = 0
        URLCache.shared.diskCapacity = 0
        statusItem = NSStatusBar.system.statusItem(withLength: -1)
        guard let button = statusItem?.button else{
            print("creating status bar item failed. try removing some items")
            return
        }
        let buttonImage = NSImage(named: "LogoGlyph")
        buttonImage?.size = NSMakeSize(18, 18)
        button.image = NSImage(named: "LogoGlyph")
        button.target = self
        button.action = #selector(togglePopover(_:))
        statusPopover.contentViewController = ViewController.freshController()
        prepareLibsForUse()
    }
    
    func prepareLibsForUse(){
        for lib in libraryManager.libraries{
            for dependency in lib.dependencies{
                if dependency.type == .PythonLib{
                    taskRunner.importLib(libName: dependency.name)
                }
            }
            taskRunner.runCodeDirectly(code: lib.bootstrapCode)
        }
    }
    
    @objc func togglePopover(_ sender: Any){
        if statusPopover.isShown{statusPopover.performClose(sender)}else{
            if let button = statusItem?.button{
                statusPopover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
            }
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func appIsBeingDebugged() -> Bool {
        var info = kinfo_proc()
        var mib : [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
        var size = MemoryLayout<kinfo_proc>.stride
        let junk = sysctl(&mib, UInt32(mib.count), &info, &size, nil, 0)
        assert(junk == 0, "sysctl failed")
        return (info.kp_proc.p_flag & P_TRACED) != 0
    }
}

