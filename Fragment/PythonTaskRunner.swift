//
//  PythonTaskRunner.swift
//  Fragment
//
//  Created by Cyrus Pellet on 22/08/2020.
//

import Cocoa
import PythonKit

class PythonTaskRunner: NSObject {
    var main: PythonObject?
    var activeLibs: [String] = []
    override init() {
        super.init()
        PythonLibrary.useVersion(2)
        self.main = Python.import("__main__")
    }
    func importLib(libName: String){
        guard !activeLibs.contains(libName) else {return}
        if Python.import(libName) == nil{
            let bashreq = self.shell(launchPath: "/usr/local/bin/pip", arguments: ["install", "\(libName)","--no-warn-script-location"])
            if !bashreq!.contains("Successfully installed"){
                print("􀢃 \(libName) dependency installation failed!")
            }else{Python.execute("from \(libName) import *");print("􀄵 \(libName) was installed successfully");activeLibs.append(libName)}
        }else{Python.execute("from \(libName) import *");print("􀄵 \(libName) was imported successfully");activeLibs.append(libName)}
    }
    func execute(execCommand: String, useExec: Bool? = false)->String?{
        guard !execCommand.lowercased().contains("import") || !execCommand.lowercased().contains("print") else {return nil}
        Python.execute("""
            def evaluate(string):
                return eval(string)
            """)
        Python.execute("""
            def execfunc(string):
                return f_out
            """)
        if useExec! {Python.execute("exec(\(execCommand))")}
        let outcome = main![dynamicMember:useExec! ? "execfunc" : "evaluate"](execCommand)
        if outcome == nil {return nil}
        return outcome!.description
    }
    func runQuery(fragment: Fragment, stringQuery: String)->TaskResult{
        var res = TaskResult(result: "<error>")
        let args = Array(stringQuery.split(separator: " ").dropFirst())
        Python.execute("fa=[\(args.joined(separator: ","))]")
        if fragment.resEvalString.contains("="){runCodeDirectly(code: fragment.resEvalString.replacingOccurrences(of: "%%A1", with: args[0]))}
        res.result = execute(execCommand: fragment.resEvalString.replacingOccurrences(of: "%%A1", with: args[0]))
        res.prettyQuery = execute(execCommand: fragment.probEvalString!, useExec: true)?.replacingOccurrences(of: "oo", with: "\\infty")
        if fragment.dispEvalString != nil && res.result != nil{
            res.prettyResult = execute(execCommand: fragment.dispEvalString!.replacingOccurrences(of: "%%R", with: res.result!))
            print(res.prettyResult)
        }
        return res
    }
    func runCodeDirectly(code: String){
        guard !code.lowercased().contains("import") || !code.lowercased().contains("print") || !code.lowercased().contains("os") else {return}
        Python.execute(code)
    }
    struct TaskResult{
        var result: String?
        var prettyResult: String?
        var prettyQuery: String?
        var query: String?
    }
    
    @discardableResult
    func shell(launchPath: String, arguments: [String]) -> String?
    {
        let task = Process()
        task.launchPath = launchPath
        task.arguments = arguments

        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: String.Encoding.utf8)

        return output
    }
}
