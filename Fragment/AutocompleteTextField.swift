//
//  AutocompleteTextField.swift
//  Fragment
//
//  Created by Cyrus Pellet on 22/08/2020.
//

import Cocoa

class AutocompleteTextField: NSTextField, AutocompletionViewControllerDelegate {
    let autocompletionPopover = NSPopover()
    let contentController = AutocompletionViewController.freshController()
    let taskRunner: PythonTaskRunner?
    let libm: FragmentLibraryManager?
    var activeFragment: Fragment?
    required init?(coder: NSCoder) {
        taskRunner = (NSApplication.shared.delegate as! AppDelegate).taskRunner
        libm = (NSApplication.shared.delegate as! AppDelegate).libraryManager
        super.init(coder: coder)
        contentController.delegate = self
        autocompletionPopover.contentViewController = contentController
        autocompletionPopover.contentSize = NSSize(width: self.bounds.width, height: 100)
    }
    func notifyTextChanged(showSuggestions: Bool, completion: @escaping(_ result: PythonTaskRunner.TaskResult?)->Void){
        let args = stringValue.split(separator: " ")
        if args.count > 1 {
            for fragment in libm!.loadedFragments{
                if fragment.title == args[0]{
                    completion(taskRunner?.runQuery(fragment: fragment, stringQuery: stringValue))
                }
            }
        }
        guard stringValue.count > 0 && !stringValue.contains(" ") else {
            if autocompletionPopover.isShown{autocompletionPopover.close()}
            return
        }
        if showSuggestions{
            contentController.updateSuggestions(for: stringValue)
            if(!autocompletionPopover.isShown){
                autocompletionPopover.show(relativeTo: self.bounds, of: self, preferredEdge: NSRectEdge.minY)
                self.becomeFirstResponder()
                self.currentEditor()?.selectedRange = .init()
                self.currentEditor()?.moveToEndOfDocument(self)
            }
        }
    }
    func selectedInsertionFragment(_ sender: AutocompletionViewController, fragment: String) {
        self.stringValue = fragment
        autocompletionPopover.close()
        if let spaceRange = fragment.range(of: " "){
            var fgcpy = fragment
            fgcpy.removeSubrange(fragment.startIndex..<spaceRange.upperBound)
            self.currentEditor()?.selectedRange = NSRange(fragment.range(of: fgcpy)!, in: fragment)
        }else{
            self.currentEditor()?.selectedRange = .init()
            self.currentEditor()?.moveToEndOfDocument(self)
        }
    }
    func wantToChangeFrame(_ sender: AutocompletionViewController, size: NSSize) {
        autocompletionPopover.contentSize = size
    }
    override func keyUp(with event: NSEvent) {
        if(autocompletionPopover.isShown){
            if event.keyCode == 0x7D {contentController.selectNext(); return}
            if event.keyCode == 0x7E {contentController.selectPrevious(); return}
            if event.keyCode == 0x24 {contentController.insertCurrent(); return}
            if event.keyCode == 0x30 {contentController.insertCurrent(); return}
        }
        super.keyUp(with: event)
    }
}

class AutocompletionViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource{
    @IBOutlet weak var completionsTableView: NSTableView!
    @IBOutlet weak var noCompletionsFoundLabel: NSTextField!
    var delegate: AutocompletionViewControllerDelegate?
    var libm: FragmentLibraryManager?
    var completions: [Fragment] = []
    var currString = ""
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        libm = (NSApplication.shared.delegate as! AppDelegate).libraryManager
        completions = libm!.loadedFragments
    }
    override func viewDidLoad() {
        completionsTableView.delegate = self
        completionsTableView.dataSource = self
        completionsTableView.backgroundColor = .clear
    }
    func numberOfRows(in tableView: NSTableView) -> Int {
        return completions.count
    }
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "suggestionCell"), owner: nil) as? NSTableCellView {
            let boldAttr = [NSAttributedString.Key.font: NSFont.boldSystemFont(ofSize: cell.textField!.font!.pointSize)]
            if let matchRange: Range = completions[row].title.lowercased().range(of: currString.lowercased()) {
                    let matchRangeStart: Int = completions[row].title.distance(from: completions[row].title.startIndex, to: matchRange.lowerBound)
                    let matchRangeEnd: Int = completions[row].title.distance(from: completions[row].title.startIndex, to: matchRange.upperBound)
                    let matchRangeLength: Int = matchRangeEnd - matchRangeStart
                    let newLabelText = NSMutableAttributedString(string: completions[row].title)
                    newLabelText.setAttributes(boldAttr, range: NSMakeRange(matchRangeStart, matchRangeLength))
                newLabelText.append(NSAttributedString(string: " : \(completions[row].description)", attributes: [NSAttributedString.Key.foregroundColor:NSColor.secondaryLabelColor, NSAttributedString.Key.font:NSFont.systemFont(ofSize: 12)]))
                cell.textField!.attributedStringValue = newLabelText
            }
            return cell
        }
        return nil
    }
    override func viewDidAppear() {
        if completions.count == 0 {
            noCompletionsFoundLabel.isHidden = false
            let newSize = NSSize(width: self.view.frame.width, height: 20.0)
            delegate?.wantToChangeFrame(self, size: newSize)
            preferredContentSize = newSize
        }else{
            noCompletionsFoundLabel.isHidden = true
            let newSize = NSSize(width: self.view.frame.width, height: completionsTableView.fittingSize.height+5.0)
            delegate?.wantToChangeFrame(self, size: newSize)
            preferredContentSize = newSize
        }
        completionsTableView.selectRowIndexes([0], byExtendingSelection: false)
    }
    func updateSuggestions(for input: String){
        currString = input
        completions = []
        for fragment in libm!.loadedFragments{
            if fragment.title.contains(input){
                completions.append(fragment)
            }
        }
        if completionsTableView != nil{
            completionsTableView.reloadData()
            completionsTableView.selectRowIndexes([0], byExtendingSelection: false)
        }
    }
    func selectNext(){
        completionsTableView.selectRowIndexes([completionsTableView.selectedRow + 1], byExtendingSelection: false)
    }
    func selectPrevious(){
        completionsTableView.selectRowIndexes([completionsTableView.selectedRow - 1], byExtendingSelection: false)
    }
    func insertCurrent(){
        guard completionsTableView.selectedRow != -1 else {return}
        delegate?.selectedInsertionFragment(self, fragment: completions[completionsTableView.selectedRow].usageTemplate)
    }
}

protocol AutocompletionViewControllerDelegate{
    func selectedInsertionFragment(_ sender: AutocompletionViewController, fragment: String)
    func wantToChangeFrame(_ sender: AutocompletionViewController, size: NSSize)
}

extension AutocompletionViewController{
    static func freshController() -> AutocompletionViewController{
        let storyboard = NSStoryboard.main
        let identifier = NSStoryboard.SceneIdentifier("avc")
        guard let viewcontroller = storyboard?.instantiateController(withIdentifier: identifier) as? AutocompletionViewController else{
            fatalError("Could not find autocompletionviewcontroller in main storyboard!")
        }
        return viewcontroller
    }
}
