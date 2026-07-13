import Foundation

class PrintJobManager {
    
    // Native Print Queue to prevent overlapping prints
    private let printQueue = DispatchQueue(label: "com.zebraprint.printqueue", qos: .userInitiated)
    
    private func checkPrinterStatus(_ printer: (NSObject & ZebraPrinter)?) throws {
        guard let printer = printer else { return }
        if let status = try? printer.getCurrentStatus(), !status.isReadyToPrint {
            if status.isPaperOut {
                throw NSError(domain: "ZebraPrint", code: 1, userInfo: [NSLocalizedDescriptionKey: "ERROR_PAPER_OUT"])
            } else if status.isHeadOpen {
                throw NSError(domain: "ZebraPrint", code: 1, userInfo: [NSLocalizedDescriptionKey: "ERROR_HEAD_OPEN"])
            } else if status.isPaused {
                throw NSError(domain: "ZebraPrint", code: 1, userInfo: [NSLocalizedDescriptionKey: "ERROR_PAUSED"])
            } else if status.isReceiveBufferFull {
                throw NSError(domain: "ZebraPrint", code: 1, userInfo: [NSLocalizedDescriptionKey: "ERROR_BUFFER_FULL"])
            } else if status.isRibbonOut {
                throw NSError(domain: "ZebraPrint", code: 1, userInfo: [NSLocalizedDescriptionKey: "ERROR_RIBBON_OUT"])
            } else {
                throw NSError(domain: "ZebraPrint", code: 1, userInfo: [NSLocalizedDescriptionKey: "ERROR_PRINTER_NOT_READY"])
            }
        }
    }
    
    func printPdf(options: [String: Any], connectionManager: PrinterConnectionManager, callbackId: String, commandDelegate: CDVCommandDelegate) {
        printQueue.async {
            var connectionError: Error?
            guard let connection = connectionManager.getOrOpenConnection(options: options, error: &connectionError) else {
                let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Connection failed: \(connectionError?.localizedDescription ?? "Unknown")")
                commandDelegate.send(pluginResult, callbackId: callbackId)
                return
            }
            
            defer { connectionManager.closeImplicitConnection(connection) }
            
            var filePathToPrint: String = ""
            var tempFileUrl: URL? = nil
            
            if let base64String = options["base64"] as? String {
                guard let pdfData = Data(base64Encoded: base64String, options: .ignoreUnknownCharacters) else {
                    let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Invalid base64 string")
                    commandDelegate.send(pluginResult, callbackId: callbackId)
                    return
                }
                
                let tempDir = FileManager.default.temporaryDirectory
                let fileName = "print_\(UUID().uuidString).pdf"
                tempFileUrl = tempDir.appendingPathComponent(fileName)
                
                do {
                    try pdfData.write(to: tempFileUrl!)
                    filePathToPrint = tempFileUrl!.path
                } catch {
                    let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Failed to write temp PDF file")
                    commandDelegate.send(pluginResult, callbackId: callbackId)
                    return
                }
            } else if var filePath = options["filePath"] as? String {
                if filePath.hasPrefix("file://") {
                    filePath = String(filePath.dropFirst(7))
                }
                filePathToPrint = filePath
            } else {
                let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "filePath or base64 is required")
                commandDelegate.send(pluginResult, callbackId: callbackId)
                return
            }
            
            defer {
                if let url = tempFileUrl {
                    try? FileManager.default.removeItem(at: url)
                }
            }
            
            do {
                let printer = try ZebraPrinterFactory.getInstance(connection)
                try self.checkPrinterStatus(printer)
                
                try printer?.getFileUtil().sendFileContents(filePathToPrint)
                
                let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: "PDF printed successfully")
                commandDelegate.send(pluginResult, callbackId: callbackId)
            } catch let err {
                let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Printer error: \(err.localizedDescription)")
                commandDelegate.send(pluginResult, callbackId: callbackId)
            }
        }
    }
    
    func printZpl(options: [String: Any], connectionManager: PrinterConnectionManager, callbackId: String, commandDelegate: CDVCommandDelegate) {
        printQueue.async {
            var error: Error?
            guard let connection = connectionManager.getOrOpenConnection(options: options, error: &error) else {
                let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Connection failed: \(error?.localizedDescription ?? "Unknown")")
                commandDelegate.send(pluginResult, callbackId: callbackId)
                return
            }
            
            defer { connectionManager.closeImplicitConnection(connection) }
            
            guard let zpl = options["zpl"] as? String, let data = zpl.data(using: .utf8) else {
                let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "zpl string is required")
                commandDelegate.send(pluginResult, callbackId: callbackId)
                return
            }
            
            do {
                if let printer = try? ZebraPrinterFactory.getInstance(connection) {
                    try self.checkPrinterStatus(printer)
                }
                
                var writeError: NSError?
                connection.write(data, error: &writeError)
                if let err = writeError {
                    throw err
                }
                let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: "ZPL printed successfully")
                commandDelegate.send(pluginResult, callbackId: callbackId)
            } catch let err {
                let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Error printing ZPL: \(err.localizedDescription)")
                commandDelegate.send(pluginResult, callbackId: callbackId)
            }
        }
    }
    
    func printCpcl(options: [String: Any], connectionManager: PrinterConnectionManager, callbackId: String, commandDelegate: CDVCommandDelegate) {
        printQueue.async {
            var error: Error?
            guard let connection = connectionManager.getOrOpenConnection(options: options, error: &error) else {
                let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Connection failed: \(error?.localizedDescription ?? "Unknown")")
                commandDelegate.send(pluginResult, callbackId: callbackId)
                return
            }
            
            defer { connectionManager.closeImplicitConnection(connection) }
            
            guard let cpcl = options["cpcl"] as? String, let data = cpcl.data(using: .utf8) else {
                let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "cpcl string is required")
                commandDelegate.send(pluginResult, callbackId: callbackId)
                return
            }
            
            do {
                if let printer = try? ZebraPrinterFactory.getInstance(connection) {
                    try self.checkPrinterStatus(printer)
                }
                
                var writeError: NSError?
                connection.write(data, error: &writeError)
                if let err = writeError {
                    throw err
                }
                let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: "CPCL printed successfully")
                commandDelegate.send(pluginResult, callbackId: callbackId)
            } catch let err {
                let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Error printing CPCL: \(err.localizedDescription)")
                commandDelegate.send(pluginResult, callbackId: callbackId)
            }
        }
    }
    
    func printRaw(options: [String: Any], connectionManager: PrinterConnectionManager, callbackId: String, commandDelegate: CDVCommandDelegate) {
        printQueue.async {
            var error: Error?
            guard let connection = connectionManager.getOrOpenConnection(options: options, error: &error) else {
                let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Connection failed: \(error?.localizedDescription ?? "Unknown")")
                commandDelegate.send(pluginResult, callbackId: callbackId)
                return
            }
            
            defer { connectionManager.closeImplicitConnection(connection) }
            
            guard let base64Data = options["data"] as? String, let data = Data(base64Encoded: base64Data) else {
                let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Valid base64 data string is required")
                commandDelegate.send(pluginResult, callbackId: callbackId)
                return
            }
            
            do {
                if let printer = try? ZebraPrinterFactory.getInstance(connection) {
                    try self.checkPrinterStatus(printer)
                }
                
                var writeError: NSError?
                connection.write(data, error: &writeError)
                if let err = writeError {
                    throw err
                }
                let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: "Raw data printed successfully")
                commandDelegate.send(pluginResult, callbackId: callbackId)
            } catch let err {
                let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Error printing raw data: \(err.localizedDescription)")
                commandDelegate.send(pluginResult, callbackId: callbackId)
            }
        }
    }
    
    func getStatus(options: [String: Any], connectionManager: PrinterConnectionManager, callbackId: String, commandDelegate: CDVCommandDelegate) {
        printQueue.async {
            var error: Error?
            guard let connection = connectionManager.getOrOpenConnection(options: options, error: &error) else {
                let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Connection failed: \(error?.localizedDescription ?? "Unknown")")
                commandDelegate.send(pluginResult, callbackId: callbackId)
                return
            }
            
            defer { connectionManager.closeImplicitConnection(connection) }
            
            do {
                let printer = try ZebraPrinterFactory.getInstance(connection)
                
                if let printerStatus = try? printer?.getCurrentStatus() {
                    var statusDict: [String: Any] = [:]
                    statusDict["isReadyToPrint"] = printerStatus.isReadyToPrint
                    statusDict["isPaused"] = printerStatus.isPaused
                    statusDict["isHeadOpen"] = printerStatus.isHeadOpen
                    statusDict["isPaperOut"] = printerStatus.isPaperOut
                    statusDict["isRibbonOut"] = printerStatus.isRibbonOut
                    statusDict["labelsRemainingInBatch"] = printerStatus.labelsRemainingInBatch
                    
                    let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: statusDict)
                    commandDelegate.send(pluginResult, callbackId: callbackId)
                } else {
                    let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Error getting status")
                    commandDelegate.send(pluginResult, callbackId: callbackId)
                }
            } catch let err {
                let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Printer error: \(err.localizedDescription)")
                commandDelegate.send(pluginResult, callbackId: callbackId)
            }
        }
    }
    
    func getSetting(variable: String, connectionManager: PrinterConnectionManager, callbackId: String, commandDelegate: CDVCommandDelegate) {
        printQueue.async {
            guard let connection = connectionManager.getConnection() else {
                let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "No active printer connection")
                commandDelegate.send(pluginResult, callbackId: callbackId)
                return
            }
            
            defer { connectionManager.closeImplicitConnection(connection) }
            
            var value = ""
            do {
                value = try SGD.get(variable, withPrinterConnection: connection)
            } catch let err {
                let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "SGD get error: \(err.localizedDescription)")
                commandDelegate.send(pluginResult, callbackId: callbackId)
                return
            }
            
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: value)
            commandDelegate.send(pluginResult, callbackId: callbackId)
        }
    }
    
    func setSetting(variable: String, value: String, connectionManager: PrinterConnectionManager, callbackId: String, commandDelegate: CDVCommandDelegate) {
        printQueue.async {
            guard let connection = connectionManager.getConnection() else {
                let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "No active printer connection")
                commandDelegate.send(pluginResult, callbackId: callbackId)
                return
            }
            
            do {
                try SGD.set(variable, withValue: value, andWithPrinterConnection: connection)
                let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: "Success")
                commandDelegate.send(pluginResult, callbackId: callbackId)
            } catch let err {
                let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "SGD set error: \(err.localizedDescription)")
                commandDelegate.send(pluginResult, callbackId: callbackId)
            }
        }
    }
}
