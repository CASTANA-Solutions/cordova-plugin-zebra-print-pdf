import Foundation

class PrintJobManager {
    
    func printPdf(options: [String: Any], connectionManager: PrinterConnectionManager, callbackId: String, commandDelegate: CDVCommandDelegate) {
        var error: Error?
        guard let connection = connectionManager.getOrOpenConnection(options: options, error: &error) else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Connection failed: \(error?.localizedDescription ?? "Unknown")")
            commandDelegate.send(pluginResult, callbackId: callbackId)
            return
        }
        
        defer { connectionManager.closeImplicitConnection(connection) }
        
        guard var filePath = options["filePath"] as? String else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "filePath is required")
            commandDelegate.send(pluginResult, callbackId: callbackId)
            return
        }
        
        if filePath.hasPrefix("file://") {
            filePath = String(filePath.dropFirst(7))
        }
        
        do {
            let printer = try ZebraPrinterFactory.getInstance(connection)
            
            var printError: NSError?
            let success = printer.getFileUtil().sendFileContents(filePath, error: &printError)
            
            if success {
                let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: "PDF printed successfully")
                commandDelegate.send(pluginResult, callbackId: callbackId)
            } else {
                let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Error printing PDF: \(printError?.localizedDescription ?? "Unknown error")")
                commandDelegate.send(pluginResult, callbackId: callbackId)
            }
        } catch let err {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Printer error: \(err.localizedDescription)")
            commandDelegate.send(pluginResult, callbackId: callbackId)
        }
    }
    
    func printZpl(options: [String: Any], connectionManager: PrinterConnectionManager, callbackId: String, commandDelegate: CDVCommandDelegate) {
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
        
        var writeError: NSError?
        connection.write(data, error: &writeError)
        
        if let err = writeError {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Error printing ZPL: \(err.localizedDescription)")
            commandDelegate.send(pluginResult, callbackId: callbackId)
        } else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: "ZPL printed successfully")
            commandDelegate.send(pluginResult, callbackId: callbackId)
        }
    }
    
    func printCpcl(options: [String: Any], connectionManager: PrinterConnectionManager, callbackId: String, commandDelegate: CDVCommandDelegate) {
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
        
        var writeError: NSError?
        connection.write(data, error: &writeError)
        
        if let err = writeError {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Error printing CPCL: \(err.localizedDescription)")
            commandDelegate.send(pluginResult, callbackId: callbackId)
        } else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: "CPCL printed successfully")
            commandDelegate.send(pluginResult, callbackId: callbackId)
        }
    }
    
    func printRaw(options: [String: Any], connectionManager: PrinterConnectionManager, callbackId: String, commandDelegate: CDVCommandDelegate) {
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
        
        var writeError: NSError?
        connection.write(data, error: &writeError)
        
        if let err = writeError {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Error printing raw data: \(err.localizedDescription)")
            commandDelegate.send(pluginResult, callbackId: callbackId)
        } else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: "Raw data printed successfully")
            commandDelegate.send(pluginResult, callbackId: callbackId)
        }
    }
    
    func getStatus(options: [String: Any], connectionManager: PrinterConnectionManager, callbackId: String, commandDelegate: CDVCommandDelegate) {
        var error: Error?
        guard let connection = connectionManager.getOrOpenConnection(options: options, error: &error) else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Connection failed: \(error?.localizedDescription ?? "Unknown")")
            commandDelegate.send(pluginResult, callbackId: callbackId)
            return
        }
        
        defer { connectionManager.closeImplicitConnection(connection) }
        
        do {
            let printer = try ZebraPrinterFactory.getInstance(connection)
            var statusError: NSError?
            
            if let printerStatus = printer.getCurrentStatus(&statusError) {
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
                let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Error getting status: \(statusError?.localizedDescription ?? "Unknown error")")
                commandDelegate.send(pluginResult, callbackId: callbackId)
            }
        } catch let err {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Printer error: \(err.localizedDescription)")
            commandDelegate.send(pluginResult, callbackId: callbackId)
        }
    }
    
    func getSetting(variable: String, connectionManager: PrinterConnectionManager, callbackId: String, commandDelegate: CDVCommandDelegate) {
        var error: Error?
        guard let connection = connectionManager.getOrOpenConnection(options: nil, error: &error) else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Connection failed: \(error?.localizedDescription ?? "Unknown")")
            commandDelegate.send(pluginResult, callbackId: callbackId)
            return
        }
        
        defer { connectionManager.closeImplicitConnection(connection) }
        
        var sgdError: NSError?
        let value = SGD.get(variable, withPrinterConnection: connection, error: &sgdError)
        
        if let err = sgdError {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Error getting setting: \(err.localizedDescription)")
            commandDelegate.send(pluginResult, callbackId: callbackId)
        } else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: value)
            commandDelegate.send(pluginResult, callbackId: callbackId)
        }
    }
    
    func setSetting(variable: String, value: String, connectionManager: PrinterConnectionManager, callbackId: String, commandDelegate: CDVCommandDelegate) {
        var error: Error?
        guard let connection = connectionManager.getOrOpenConnection(options: nil, error: &error) else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Connection failed: \(error?.localizedDescription ?? "Unknown")")
            commandDelegate.send(pluginResult, callbackId: callbackId)
            return
        }
        
        defer { connectionManager.closeImplicitConnection(connection) }
        
        var sgdError: NSError?
        let success = SGD.set(variable, withValue: value, andWithPrinterConnection: connection, error: &sgdError)
        
        if let err = sgdError, !success {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Error setting setting: \(err.localizedDescription)")
            commandDelegate.send(pluginResult, callbackId: callbackId)
        } else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: "Setting updated")
            commandDelegate.send(pluginResult, callbackId: callbackId)
        }
    }
}
