//
//  LibraryManagerViewController.swift
//  Fragment
//
//  Created by Cyrus Pellet on 23/08/2020.
//

import Cocoa

class LibraryManagerViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource, OnlineLibrariesPanelDelegate {

    @IBOutlet weak var librariesTableView: NSTableView!
    @IBOutlet weak var addButton: NSButton!
    var appdelegate: AppDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        appdelegate = NSApplication.shared.delegate as? AppDelegate
        librariesTableView.delegate = self
        librariesTableView.dataSource = self
        let addMenu = NSMenu()
        addMenu.addItem(NSMenuItem(title: "Browse available libraries", action: #selector(openBrowseOnlineLibsPanel(_:)), keyEquivalent: ""))
        addMenu.addItem(NSMenuItem.separator())
        addMenu.addItem(NSMenuItem(title: "Add from file", action: #selector(openFromFilePanel(_:)), keyEquivalent: ""))
        addMenu.addItem(NSMenuItem(title: "Add from URL", action: #selector(addFromURLPanel(_:)), keyEquivalent: ""))
        addButton.menu = addMenu
    }
    
    @objc func openBrowseOnlineLibsPanel(_ sender: Any){
        let vc:NSViewController = NSStoryboard(name: "Main", bundle: nil).instantiateController(identifier: "olibvc")
        (vc as! OnlineLibrariesManagerViewController).delegate = self
        vc.view.frame = NSRect(origin: self.view.frame.origin, size: NSMakeSize(self.view.frame.width-20, self.view.frame.height-20))
        self.presentAsSheet(vc)
    }
    
    @objc func openFromFilePanel(_ sender: Any){
        let filePicker = NSOpenPanel()
        filePicker.title = "Choose a fragment library to install"
        filePicker.canChooseDirectories = false
        filePicker.allowsMultipleSelection = false
        filePicker.allowedFileTypes = ["flib"]
        if filePicker.runModal() == NSApplication.ModalResponse.OK{
            let (valid, validLib) = appdelegate!.libraryManager.libIsValid(localURL: filePicker.url!)
            if valid{
                do{
                    try FileManager.default.moveItem(at: filePicker.url!, to: appdelegate!.libraryManager.getLibLocalURLFromName(validLib!.title))
                    appdelegate?.libraryManager.loadValidatedLibContents(lib: validLib!)
                    (NSApplication.shared.delegate as! AppDelegate).prepareLibsForUse()
                }catch{
                    popUpError(title: "Could not create library directory!", message: "Please check file permissions on your system")
                }
            }else{
                popUpError(title: "Library file is invalid!", message: "Library contents could not be loaded")
            }
        }
    }
    
    @objc func addFromURLPanel(_ sender: Any){
        let msg = NSAlert()
        msg.addButton(withTitle: "OK")      // 1st button
        msg.addButton(withTitle: "Cancel")  // 2nd button
        msg.messageText = "Enter library URL"
        let txt = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        txt.placeholderString = "Fragment library URL"
        msg.accessoryView = txt
        let response: NSApplication.ModalResponse = msg.runModal()
        if (response == NSApplication.ModalResponse.alertFirstButtonReturn) {
            DispatchQueue.global(qos: .utility).async {
                let sessionConfig = URLSessionConfiguration.default
                let session = URLSession(configuration: sessionConfig)
                let request = URLRequest(url: URL(string: txt.stringValue)!)
                let task = session.downloadTask(with: request) { (tempLocalUrl, response, error) in
                    if let tempLocalUrl = tempLocalUrl, error == nil {
                        let (valid, validLib) = self.appdelegate!.libraryManager.libIsValid(localURL: tempLocalUrl)
                        if valid{
                            do{
                                try FileManager.default.moveItem(at: tempLocalUrl, to: self.appdelegate!.libraryManager.getLibLocalURLFromName(validLib!.title))
                                self.appdelegate?.libraryManager.loadValidatedLibContents(lib: validLib!)
                                (NSApplication.shared.delegate as! AppDelegate).prepareLibsForUse()
                            }catch{
                                popUpError(title: "Could not create library directory!", message: "Please check file permissions on your system")
                            }
                        }else{
                            popUpError(title: "Library file is invalid!", message: "Library contents could not be loaded")
                        }
                    }else{
                        popUpError(title: "Library URL is invalid")
                    }
                }
                task.resume()
            }
        }
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return appdelegate?.libraryManager.libraries.count ?? 0
    }
    
    func libsWereChanged(_ sender: OnlineLibrariesManagerViewController) {
        librariesTableView.reloadData()
    }
        
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "libraryCell"), owner: nil) as? LibraryCell {
            cell.titleLabel.stringValue = appdelegate?.libraryManager.libraries[row].title ?? "error"
            cell.authorLabel.stringValue = "by \(appdelegate!.libraryManager.libraries[row].author)"
            cell.descriptionLabel.stringValue = appdelegate?.libraryManager.libraries[row].description ?? "error"
            cell.statusButton.title = appdelegate?.libraryManager.libraries[row].remoteURL == "" ? "Installed (manually)" : "Installed"
            cell.statusButton.image = NSImage(named: "SF_checkmark_square_fill")!.resized(to: NSSize(width: 12, height: 12))
            cell.statusButton.toolTip = appdelegate?.libraryManager.libraries[row].remoteURL == "" ? "Manually installed libraries will not get automatic updates" : ""
            let cellmenu = NSMenu()
            let deleteItem = NSMenuItem(title: "Uninstall", action: #selector(uninstallLibrary(_:)), keyEquivalent: "")
            if appdelegate!.libraryManager.libraries[row].title == "Core" {
                deleteItem.action = nil
            }
            cellmenu.addItem(deleteItem)
            cellmenu.addItem(NSMenuItem.separator())
            cellmenu.addItem(NSMenuItem(title: "Check integrity", action: nil, keyEquivalent: ""))
            cellmenu.addItem(NSMenuItem(title: "Show in finder", action: #selector(showInFinder(_:)), keyEquivalent: ""))
            cell.statusButton.tag = row
            cell.statusButton.menu = cellmenu
            var fragments: [String] = ["Included:"]
            for fragment in appdelegate!.libraryManager.libraries[row].fragments{
                fragments.append(fragment.title)
            }
            cell.toolTip = fragments.joined(separator: "\n")
            return cell
        }
        return nil
    }
    
    @objc func uninstallLibrary(_ sender: NSButton){
        let alert = NSAlert()
        alert.messageText = "Remove library"
        alert.informativeText = "Are you sure you want to remove \(appdelegate!.libraryManager.libraries[sender.tag].title)?"
        alert.addButton(withTitle: "No")
        alert.addButton(withTitle: "Yes")
        alert.alertStyle = .critical
        if alert.runModal() == NSApplication.ModalResponse.alertSecondButtonReturn{
            appdelegate?.libraryManager.uninstallLibrary(libName: (appdelegate!.libraryManager.libraries[sender.tag].title))
        }
    }
    
    @IBAction func addButtonPressed(_ sender: NSButton) {
        sender.menu?.popUp(positioning: sender.menu?.items.first, at: sender.frame.origin, in: self.view)
    }
    
    
    @objc func showInFinder(_ sender: NSButton){
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: (FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?.appendingPathComponent(Bundle.main.bundleIdentifier ?? "com.cloud31.Fragment").appendingPathComponent("FragmentLibraries").path)!)
    }
}

class LibraryCell: NSTableCellView{
    @IBOutlet weak var titleLabel: NSTextField!
    @IBOutlet weak var authorLabel: NSTextField!
    @IBOutlet weak var descriptionLabel: NSTextField!
    @IBOutlet weak var statusButton: NSButton!
    
    @IBAction func statusButtonClicked(_ sender: Any) {
        (sender as? NSButton)?.menu?.popUp(positioning: (sender as? NSButton)?.menu?.items.first, at: ((sender as? NSButton)?.frame.origin)!, in: self)
    }
    
}

class OnlineLibrariesManagerViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource{
    @IBOutlet weak var onlineLibrariesTableView: NSTableView!
    var availableLibs: [ManifestEntry] = []
    var libIsInstalled: [Bool] = []
    var delegate: OnlineLibrariesPanelDelegate?
    override func viewDidLoad() {
        onlineLibrariesTableView.delegate = self
        onlineLibrariesTableView.dataSource = self
        (NSApplication.shared.delegate as! AppDelegate).libraryManager.queryManifest{res in
            self.availableLibs = res
            for lib in res{
                var found: Bool = false
                DispatchQueue.main.async {
                    for ilib in (NSApplication.shared.delegate as! AppDelegate).libraryManager.libraries{
                        if lib.libURL == ilib.remoteURL {found = true}
                    }
                    self.libIsInstalled.append(found)
                }
            }
            DispatchQueue.main.async {
                self.onlineLibrariesTableView.reloadData()
            }
        }
    }
    func numberOfRows(in tableView: NSTableView) -> Int {
        return availableLibs.count
    }
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "onlineLibraryCell"), owner: nil) as? LibraryCell {
            cell.titleLabel.stringValue = availableLibs[row].libTitle
            cell.authorLabel.stringValue = "by \(availableLibs[row].libAuthor)"
            cell.descriptionLabel.stringValue = availableLibs[row].libDescription
            if #available(OSX 10.16, *) {
                cell.statusButton.image = libIsInstalled[row] ? NSImage(named: "SF_checkmark_square_fill")?.resized(to: NSSize(width: 12, height: 12)) : NSImage(named: "SF_arrow_down_to_line_alt")?.tinting(with: .systemGreen)
            } else {
                // Fallback on earlier versions
            }
            cell.statusButton.attributedTitle = NSAttributedString(string: libIsInstalled[row] ? "Installed" : "Download", attributes: [NSAttributedString.Key.foregroundColor: libIsInstalled[row] ? NSColor.secondaryLabelColor : NSColor.systemGreen, NSAttributedString.Key.font: NSFont.systemFont(ofSize: NSFont.systemFontSize, weight: .bold)])
            cell.statusButton.target = self
            cell.statusButton.action = #selector(downloadLib(_:))
            cell.statusButton.tag = row
            var fragments: [String] = ["Included:"]
            for fragment in availableLibs[row].libFragmentList{
                fragments.append(fragment)
            }
            cell.toolTip = fragments.joined(separator: "\n")
            return cell
        }
        return nil
    }
    @objc func downloadLib(_ sender: NSButton){
        let libManager = (NSApplication.shared.delegate as! AppDelegate).libraryManager
        let remoteURL = URL(string: availableLibs[sender.tag].libURL)!
        let data = try! Data(contentsOf: remoteURL)
        let localURL = libManager.getLibLocalURLFromName(remoteURL.deletingPathExtension().lastPathComponent)
        try! data.write(to: localURL)
        let (valid, validLib) = libManager.libIsValid(localURL: localURL)
        if valid{
            libManager.loadValidatedLibContents(lib: validLib!)
            libIsInstalled[sender.tag] = true
            onlineLibrariesTableView.reloadData()
            (NSApplication.shared.delegate as! AppDelegate).prepareLibsForUse()
            delegate?.libsWereChanged(self)
        }
    }
    @IBAction func closeButtonPressed(_ sender: Any) {
        self.dismiss(self)
    }
    
}

protocol OnlineLibrariesPanelDelegate{
    func libsWereChanged(_ sender: OnlineLibrariesManagerViewController)
}
