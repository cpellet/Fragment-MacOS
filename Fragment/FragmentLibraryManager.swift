//
//  FragmentLibraryManager.swift
//  Fragment
//
//  Created by Cyrus Pellet on 22/08/2020.
//

import Cocoa
import Keychain
import Checksum
import UserDefault
import CryptoKit

class FragmentLibraryManager: NSObject {
    
    let librariesUrl = (FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?.appendingPathComponent(Bundle.main.bundleIdentifier ?? "com.cloud31.Fragment").appendingPathComponent("FragmentLibraries"))!
        
    var libraries: [FragmentLibrary] = []
    var loadedFragments: [Fragment] = []
        
    @Keychain("libkey")
    var key: String?
    
    @UserDefault("libPathsInUse")
    var startupLibs: [String]?
    var libsToInit: [String] = []
    
    override init() {
        super.init()
        if key == nil {key = "\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0"}
        if startupLibs == nil{ startupLibs = ["https://fragment-161bd.web.app/packages/libraries/Core.flib"]}
        libsToInit.append(contentsOf: startupLibs!)
        loadOfflineLibs()
        for lib in libsToInit{
            fixLibFromURL(libURL: URL(string: lib)!)
        }
        checkForLibUpdates()
    }
    
    func loadOfflineLibs(){
        if !FileManager.default.fileExists(atPath: librariesUrl.path){
            do{try FileManager.default.createDirectory(at: librariesUrl, withIntermediateDirectories: true, attributes: nil)}catch{popUpError(title: "Could not create library directory!", message: "Please check file permissions on your system")}
        }
        for dir in FileManager.default.subpaths(atPath: librariesUrl.path)!{
            if dir.contains(".flib"){
                let (valid, validLib) = libIsValid(localURL: librariesUrl.appendingPathComponent(dir))
                if valid {loadValidatedLibContents(lib: validLib!)}
            }
        }
    }
    
    func libIsValid(localURL: URL)->(Bool, FragmentLibrary?){
        guard FileManager.default.fileExists(atPath: localURL.path) else {print("􀢃 Error loading \(localURL.path): File doesn't exist"); return (false, nil)}
        guard localURL.pathExtension == "flib" else {print("􀢃 Error loading \(localURL.path): Invalid path extension");return(false, nil)}
        do{
            let rawData = try Data(contentsOf: localURL)
            let box = try AES.GCM.SealedBox(combined: rawData)
            let decodedData = try AES.GCM.open(box, using: SymmetricKey(data: (key?.data(using: .utf8))!))
            let jsonDecoder = JSONDecoder()
            let res = try jsonDecoder.decode(FragmentLibrary.self, from: decodedData)
            guard res.description != "", res.title != "", res.author != "", res.fragments.count != 0 else {print("􀢃 Error loading \(localURL.path): Contents missing"); return (false, nil)}
            return (true, res)
        }catch {print("􀢃 Error loading \(localURL.path): Decoding failed"); return (false, nil)}
    }
    
    func reloadAllLibs(){
        libraries = []
        loadedFragments = []
        loadOfflineLibs()
    }
    
    func loadValidatedLibContents(lib: FragmentLibrary){
        libraries.append(lib)
        loadedFragments.append(contentsOf: lib.fragments)
        for i in 0..<libsToInit.count{
            guard i < libsToInit.count else {print("􀁢 Loaded \(lib.title)");return}
            if libsToInit[i].contains("\(lib.title).flib"){libsToInit.remove(at: i)}
        }
        print("􀁢 Loaded \(lib.title)")
    }
    
    func getLibNameFromURL(_ url: String)->String{
        return url.replacingOccurrences(of: ".flib", with: "").components(separatedBy: "/").last ?? "error"
    }
    func getLibLocalURLFromName(_ name: String)->URL{
        return librariesUrl.appendingPathComponent(name).appendingPathExtension("flib")
    }
    
    func uninstallLibrary(libName: String){
        do{
            try FileManager.default.removeItem(atPath: getLibLocalURLFromName(libName).path)
            for i in 0..<libraries.count{
                if libraries[i].title == libName{
                    libraries.remove(at: i)
                }
            }
            reloadAllLibs()
        }catch{print(error)}
    }
    
    func queryManifest(completion: @escaping(_ res: [ManifestEntry])->Void){
        let manifestURL = URL(string: "https://fragment-161bd.web.app/packages/libraries/manifest.json")
        let task = URLSession.shared.dataTask(with: manifestURL!, completionHandler: {(data, response, error) in
            let jsonDecoder = JSONDecoder()
            let res = try! jsonDecoder.decode([ManifestEntry].self, from: data!)
            completion(res)
        })
        task.resume()
    }
    
    func generateLibraryFile(lib: FragmentLibrary){
        let jsonEncoder = JSONEncoder()
        let jsonData = try! jsonEncoder.encode(lib)
        let encodedData = try! AES.GCM.seal(jsonData, using: SymmetricKey(data: (key?.data(using: .utf8))!))
        try! encodedData.combined?.write(to: FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask)[0].appendingPathComponent(lib.title).appendingPathExtension("flib"))
    }
    
    func fixLibFromURL(libURL: URL){
        print("􀥎 Attempting to fix unloaded lib: \(libURL.lastPathComponent)")
        do{
            let data = try Data(contentsOf: libURL)
            let localURL = getLibLocalURLFromName(libURL.deletingPathExtension().lastPathComponent)
            if FileManager.default.fileExists(atPath: localURL.path){
                try FileManager.default.removeItem(at: localURL)
            }
            try data.write(to: localURL)
            let (valid, validLib) = libIsValid(localURL: localURL)
            if valid{
                loadValidatedLibContents(lib: validLib!)
            }else{print("􀢃 Could not fix unloaded lib: \(libURL.lastPathComponent)"); return}
        }catch{
            print("􀢃 Could not fix unloaded lib: \(libURL.lastPathComponent)")
        }
    }
    
    func checkForLibUpdates(){
        DispatchQueue.global(qos: .background).async {
            var libMD5: [String:String] = [:]
            self.queryManifest(){res in
                for qlib in res{
                    libMD5[qlib.libURL] = qlib.checksum
                }
                for lib in self.libraries where lib.remoteURL != ""{
                    if !(self.startupLibs?.contains(lib.remoteURL))!{self.startupLibs?.append(lib.remoteURL)}
                    let remoteData = try! Data(contentsOf: self.getLibLocalURLFromName(lib.title))
                    remoteData.checksum(algorithm: .sha256){res in
                        switch res{
                        case .success(let checksum):
                            if libMD5[lib.remoteURL]! != checksum{
                                print("􀢤 Update available for lib: \(lib.title)")
                                let data = try! Data(contentsOf: URL(string: lib.remoteURL)!)
                                let localURL = self.getLibLocalURLFromName(URL(string: lib.remoteURL)!.deletingPathExtension().lastPathComponent)
                                try! FileManager.default.removeItem(at: localURL)
                                try! data.write(to: localURL)
                                let (valid, validLib) = self.libIsValid(localURL: localURL)
                                if valid{
                                    self.loadValidatedLibContents(lib: validLib!)
                                }
                            }else{
                                print("􀇺 No updates for \(lib.title)")
                            }
                        case .failure(let error): print(error)
                        }
                    }
                }
            }
        }
    }
    
}

struct ManifestEntry: Encodable, Decodable{
    var libTitle: String
    var libURL: String
    var libAuthor: String
    var checksum: String?
    var libDescription: String
    var libFragmentList: [String]
}

struct FragmentLibrary: Encodable, Decodable{
    var title: String
    var remoteURL: String
    var author: String
    var description: String
    var updatedDate: Date
    var dependencies: [Dependency]
    var fragments: [Fragment]
    var bootstrapCode: String
}

struct Dependency: Encodable, Decodable{
    var type: DependencyType
    var name: String
    var minVersion: Double
    var manifestURL: String
}

enum DependencyType: String, Encodable, Decodable{
    case FragmentLib
    case PythonLib
}

struct Fragment: Encodable, Decodable{
    var title: String
    var description: String
    var resEvalString: String
    var dispEvalString: String?
    var probEvalString: String?
    var usageTemplate: String
}
