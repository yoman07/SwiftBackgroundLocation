import Foundation
import CoreLocation

struct BackgroundDebug {
    
    private static var fileUrl = { () -> URL in
        let dir: URL = FileManager.default.urls(for: FileManager.SearchPathDirectory.cachesDirectory, in: FileManager.SearchPathDomainMask.userDomainMask).last!
        
        
        return dir.appendingPathComponent("backgrounddebug.log")
    }()
    
    
    func write(string: String) {
        debugPrint(string)
        
        let data = "\(Date()) \(string) \n".data(using: String.Encoding.utf8, allowLossyConversion: false)!
        
        if FileManager.default.fileExists(atPath: BackgroundDebug.fileUrl.path) {
            let fileHandle = try! FileHandle(forWritingTo: BackgroundDebug.fileUrl)
            fileHandle.seekToEndOfFile()
            fileHandle.write(data)
            fileHandle.closeFile()
            
        } else {
            try! data.write(to: BackgroundDebug.fileUrl)
        }
        
        
    }
    
    func clear() {
        try? FileManager.default.removeItem(at: BackgroundDebug.fileUrl)
    }
    
    func print() {
        guard let data = try? String(contentsOf: BackgroundDebug.fileUrl) else { return }
        debugPrint(data)
    }
}
