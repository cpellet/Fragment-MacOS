//
//  ViewController.swift
//  Fragment
//
//  Created by Cyrus Pellet on 22/08/2020.
//

import Cocoa
import iosMath
import Sparkle
import UserDefault

class ViewController: NSViewController, NSTextFieldDelegate, HistoryViewControllerDelegate {
    
    @IBOutlet weak var inputField: AutocompleteTextField!
    @IBOutlet weak var mathLabel: MTMathUILabel!
    @IBOutlet weak var settingsButton: NSButton!
    var libraryManagerWindow: NSWindow?
    var historyPopover = NSPopover()
    var historyStack: [PythonTaskRunner.TaskResult] = []
    var prevRes: String = ""
    
    //User prefs settings
    @UserDefault("showSuggestionsWhenTyping")
    var userSettingsShowSuggestionsWhenTyping: Bool?
    @UserDefault("copyResponseToClipboard")
    var userSettingsCopyResponseToClipboard: Bool?
    @UserDefault("mathDisplayProblem")
    var userSettingsMathsDisplayProblem: Bool?

    override func viewDidLoad() {
        super.viewDidLoad()
        inputField.delegate = self
        mathLabel.textAlignment = .center
        mathLabel.labelMode = .display
        mathLabel.textColor = .labelColor
        initSettings()
        setupSettingsButtonMenu()
    }
    
    func setupSettingsButtonMenu(){
        let menu = NSMenu()
        let autoSuggestionsItem = NSMenuItem(title: "Show suggestions when typing", action: #selector(toggleSuggestionsWhenTyping(_:)), keyEquivalent: "")
        autoSuggestionsItem.state = userSettingsShowSuggestionsWhenTyping! ? .on : .off
        menu.addItem(autoSuggestionsItem)
        menu.addItem(NSMenuItem(title: "Export result as image", action: #selector(saveImage(_:)), keyEquivalent: "S"))
        let copyToClipboardItem = NSMenuItem(title: "Always copy result to clipboard", action: #selector(toggleCopyResultToClipboard(_:)), keyEquivalent: "")
        copyToClipboardItem.state = userSettingsCopyResponseToClipboard! ? .on : .off
        menu.addItem(copyToClipboardItem)
        let mdisplaySubmenu = NSMenu()
        let paSubItem = NSMenuItem(title: "Problem & answer", action: #selector(enableMathDisplayProblem), keyEquivalent: "")
        paSubItem.state = userSettingsMathsDisplayProblem! ? .on : .off
        mdisplaySubmenu.addItem(paSubItem)
        let aSubItem = NSMenuItem(title: "Answer only", action: #selector(disableMathDisplayProblem), keyEquivalent: "")
        aSubItem.state = userSettingsMathsDisplayProblem! ? .off : .on
        mdisplaySubmenu.addItem(aSubItem)
        let mdisplayItem = NSMenuItem(title: "Math display", action: nil, keyEquivalent: "")
        mdisplayItem.submenu = mdisplaySubmenu
        menu.addItem(mdisplayItem)
        menu.addItem(NSMenuItem(title: "Manage libraries", action: #selector(showLibrariesPanel(_:)), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Check for updates", action: #selector(checkForUpdates), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Help", action: #selector(showHelp), keyEquivalent: "h"))
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))
        settingsButton.menu = menu
    }
    
    @objc func showLibrariesPanel(_ sender: Any){
        libraryManagerWindow = NSWindow(contentRect: .init(origin: .zero, size: .init(width: NSScreen.main!.frame.midX,height: NSScreen.main!.frame.midY)),styleMask: [.closable, .titled], backing: .buffered,defer: false)
        libraryManagerWindow!.title = "Installed libraries"
        libraryManagerWindow?.contentViewController = NSStoryboard.main?.instantiateController(identifier: "libvc", creator: nil)
        libraryManagerWindow!.center()
        libraryManagerWindow!.orderFrontRegardless()
    }
    
    @objc func showHelp(){
        // TO DO
    }
    
    @objc func checkForUpdates(){
        SUUpdater.shared()?.checkForUpdates(self)
    }
    
    @objc func enableMathDisplayProblem(){
        userSettingsMathsDisplayProblem = true
        setupSettingsButtonMenu()
        controlTextDidChange(Notification(name: Notification.Name(rawValue: "")))
    }
    
    @objc func disableMathDisplayProblem(){
        userSettingsMathsDisplayProblem = false
        setupSettingsButtonMenu()
        controlTextDidChange(Notification(name: Notification.Name(rawValue: "")))
    }
    
    @objc func toggleCopyResultToClipboard(_ sender: NSMenuItem){
        userSettingsCopyResponseToClipboard = !userSettingsCopyResponseToClipboard!
        setupSettingsButtonMenu()
    }
    
    @objc func toggleSuggestionsWhenTyping(_ sender: NSMenuItem){
        userSettingsShowSuggestionsWhenTyping = !userSettingsShowSuggestionsWhenTyping!
        setupSettingsButtonMenu()
    }
    
    func controlTextDidChange(_ obj: Notification) {
        mathLabel.latex = ""
        inputField.notifyTextChanged(showSuggestions: userSettingsShowSuggestionsWhenTyping!){result in
            if result?.result != nil && self.userSettingsCopyResponseToClipboard! {NSPasteboard.general.declareTypes([.string], owner: nil);NSPasteboard.general.setString((result?.result)!, forType: .string)}
            if result?.prettyResult != nil {
                self.mathLabel.latex = self.userSettingsMathsDisplayProblem! && result?.prettyQuery != nil ? "\(result!.prettyQuery!) = \(result!.prettyResult!)" : result!.prettyResult
                if !result!.result!.contains(self.prevRes){
                    let he = PythonTaskRunner.TaskResult(result: result?.result, prettyResult: result?.prettyResult, prettyQuery: result?.prettyQuery, query: self.inputField.stringValue)
                    self.historyStack.append(he)
                    self.prevRes = result!.result!
                }
            }
        }
    }
    
    func initSettings(){
        if userSettingsShowSuggestionsWhenTyping == nil {userSettingsShowSuggestionsWhenTyping = true}
        if userSettingsCopyResponseToClipboard == nil {userSettingsCopyResponseToClipboard = false}
        if userSettingsMathsDisplayProblem == nil {userSettingsMathsDisplayProblem = true}
    }
    
    @IBAction func historyButtonPressed(_ sender: NSButton) {
        guard historyStack.count != 0 else {return}
        if historyPopover.contentViewController == nil{
            historyPopover.contentViewController = HistoryViewController.freshController()
            (historyPopover.contentViewController as! HistoryViewController).delegate = self
        }
        if historyPopover.isShown{historyPopover.close()}else{(historyPopover.contentViewController as! HistoryViewController).updateItems(items: historyStack);historyPopover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)}
    }
    
    func didSelectHistoryElement(controller: HistoryViewController, element: PythonTaskRunner.TaskResult) {
        if inputField.stringValue == ""{
            inputField.stringValue = element.query!
        }else{
            inputField.stringValue.append(element.result!)
        }
        historyPopover.close()
    }
    
    func wantToChangeSize(controller: HistoryViewController, size: NSSize) {
        historyPopover.contentSize = size
    }
    
    @objc func saveImage(_ sender: Any?){
        let bitr: NSBitmapImageRep = view.bitmapImageRepForCachingDisplay(in: mathLabel.bounds)!
        view.cacheDisplay(in: mathLabel.bounds, to: bitr)
        let image = NSImage.init(size: NSMakeSize(mathLabel.bounds.width, mathLabel.bounds.height))
        image.addRepresentation(bitr)
        let data = bitr.representation(using: .png, properties: [:])
        let dialog = NSSavePanel()
        dialog.allowedFileTypes = ["png"]
        dialog.allowsOtherFileTypes = false
        dialog.canCreateDirectories = true
        dialog.nameFieldStringValue = "result.png"
        dialog.isExtensionHidden = false
        dialog.message = "Choose a location to save image"
        dialog.prompt = "Save"
        NSApp.activate(ignoringOtherApps: true)
        if (dialog.runModal() ==  NSApplication.ModalResponse.OK) {
            let result = dialog.url // Pathname of the file
            if (result != nil) {
                do{
                    try data!.write(to: result!, options: [])
                }catch{
                    print(error)
                }
            }
        } else {return}
    }
    
    @objc func quit(){
        NSApplication.shared.terminate(self)
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @IBAction func settingsButtonPressed(_ sender: Any) {
        settingsButton.menu?.popUp(positioning: settingsButton.menu?.items.first, at: settingsButton.frame.origin, in: self.view)
    }
    
}

extension ViewController{
    static func freshController() -> ViewController{
        let storyboard = NSStoryboard.main
        let identifier = NSStoryboard.SceneIdentifier("vc")
        guard let viewcontroller = storyboard?.instantiateController(withIdentifier: identifier) as? ViewController else{
            fatalError("Could not find viewcontroller in main storyboard!")
        }
        return viewcontroller
    }
}
