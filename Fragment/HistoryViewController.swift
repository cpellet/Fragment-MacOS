//
//  HistoryViewController.swift
//  Fragment
//
//  Created by Cyrus Pellet on 25/08/2020.
//

import Cocoa
import UserDefault
import iosMath

class HistoryViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource {
    @UserDefault("mathDisplayProblem")
    var userSettingsMathsDisplayProblem: Bool?
    var historyStack: [PythonTaskRunner.TaskResult] = []
    var delegate: HistoryViewControllerDelegate?
    @IBOutlet weak var historyTableView: NSTableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        historyTableView.delegate = self
        historyTableView.dataSource = self
        historyTableView.backgroundColor = .clear
    }
    func numberOfRows(in tableView: NSTableView) -> Int {
        return historyStack.count
    }
    func tableViewSelectionDidChange(_ notification: Notification) {
        guard historyTableView.selectedRow != -1 else {return}
        delegate?.didSelectHistoryElement(controller: self, element: historyStack[historyTableView.selectedRow])
        historyTableView.deselectAll(self)
    }
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "historyCell"), owner: nil) as? HistoryCell {
            if historyStack[row].prettyResult != nil {
                cell.mathView.latex = userSettingsMathsDisplayProblem! && historyStack[row].prettyQuery != nil ? "\(historyStack[row].prettyQuery!) = \(historyStack[row].prettyResult!)" : historyStack[row].prettyResult
                cell.mathView.textAlignment = .center
                cell.mathView.textColor = .labelColor
                cell.mathView.fontSize = 14.0
            }
            return cell
        }
        return nil
    }
    func updateItems(items: [PythonTaskRunner.TaskResult]){
        historyStack = items
        if(historyTableView != nil){
            historyTableView.reloadData()
        }
        let newSize = NSSize(width: self.view.frame.width, height: historyTableView.fittingSize.height+5.0)
        delegate?.wantToChangeSize(controller: self, size: newSize)
        preferredContentSize = newSize
    }
}

class HistoryCell: NSTableCellView{
    @IBOutlet weak var mathView: MTMathUILabel!
}

extension HistoryViewController{
    static func freshController() -> HistoryViewController{
        let storyboard = NSStoryboard.main
        let identifier = NSStoryboard.SceneIdentifier("hvc")
        guard let viewcontroller = storyboard?.instantiateController(withIdentifier: identifier) as? HistoryViewController else{
            fatalError("Could not find historyviewcontroller in main storyboard!")
        }
        return viewcontroller
    }
}

protocol HistoryViewControllerDelegate{
    func didSelectHistoryElement(controller: HistoryViewController, element: PythonTaskRunner.TaskResult)
    func wantToChangeSize(controller: HistoryViewController, size: NSSize)
}
