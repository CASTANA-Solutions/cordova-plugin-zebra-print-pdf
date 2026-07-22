import Foundation

class PrintJobManager {
    
    func printPdf(options: [String: Any], connectionManager: PrinterConnectionManager, callbackId: String, commandDelegate: CDVCommandDelegate) {
        var error: Error?
        guard let connection = connectionManager.getOrOpenConnection(options: options, error: &error) else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus.error, messageAs: "Connection failed: \(error?.localizedDescription ?? "Unknown")")
            commandDelegate.send(pluginResult, callbackId: callbackId)
            return
        }
        
        defer { connectionManager.closeImplicitConnection(connection) }
        
        guard var filePath = options["filePath"] as? String else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus.error, messageAs: "filePath is required")
            commandDelegate.send(pluginResult, callbackId: callbackId)
            return
        }
        
        if filePath.hasPrefix("file://") {
            filePath = String(filePath.dropFirst(7))
        }
        
        do {
            let printer = try ZebraPrinterFactory.getInstance(connection)

            try printer.getFileUtil().sendFileContents(filePath)
            let pluginResult = CDVPluginResult(status: CDVCommandStatus.ok, messageAs: "PDF printed successfully")
            commandDelegate.send(pluginResult, callbackId: callbackId)
        } catch let err {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus.error, messageAs: "Printer error: \(err.localizedDescription)")
            commandDelegate.send(pluginResult, callbackId: callbackId)
        }
    }
    
    func printZpl(options: [String: Any], connectionManager: PrinterConnectionManager, callbackId: String, commandDelegate: CDVCommandDelegate) {
        var error: Error?
        guard let connection = connectionManager.getOrOpenConnection(options: options, error: &error) else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus.error, messageAs: "Connection failed: \(error?.localizedDescription ?? "Unknown")")
            commandDelegate.send(pluginResult, callbackId: callbackId)
            return
        }
        
        defer { connectionManager.closeImplicitConnection(connection) }
        
        guard let zpl = options["zpl"] as? String, let data = zpl.data(using: .utf8) else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus.error, messageAs: "zpl string is required")
            commandDelegate.send(pluginResult, callbackId: callbackId)
            return
        }
        
        var writeError: NSError?
        connection.write(data, error: &writeError)
        
        if let err = writeError {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus.error, messageAs: "Error printing ZPL: \(err.localizedDescription)")
            commandDelegate.send(pluginResult, callbackId: callbackId)
        } else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus.ok, messageAs: "ZPL printed successfully")
            commandDelegate.send(pluginResult, callbackId: callbackId)
        }
    }
    
    func printCpcl(options: [String: Any], connectionManager: PrinterConnectionManager, callbackId: String, commandDelegate: CDVCommandDelegate) {
        var error: Error?
        guard let connection = connectionManager.getOrOpenConnection(options: options, error: &error) else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus.error, messageAs: "Connection failed: \(error?.localizedDescription ?? "Unknown")")
            commandDelegate.send(pluginResult, callbackId: callbackId)
            return
        }
        
        defer { connectionManager.closeImplicitConnection(connection) }
        
        guard let cpcl = options["cpcl"] as? String, let data = cpcl.data(using: .utf8) else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus.error, messageAs: "cpcl string is required")
            commandDelegate.send(pluginResult, callbackId: callbackId)
            return
        }
        
        var writeError: NSError?
        connection.write(data, error: &writeError)
        
        if let err = writeError {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus.error, messageAs: "Error printing CPCL: \(err.localizedDescription)")
            commandDelegate.send(pluginResult, callbackId: callbackId)
        } else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus.ok, messageAs: "CPCL printed successfully")
            commandDelegate.send(pluginResult, callbackId: callbackId)
        }
    }
    
    func printRaw(options: [String: Any], connectionManager: PrinterConnectionManager, callbackId: String, commandDelegate: CDVCommandDelegate) {
        var error: Error?
        guard let connection = connectionManager.getOrOpenConnection(options: options, error: &error) else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus.error, messageAs: "Connection failed: \(error?.localizedDescription ?? "Unknown")")
            commandDelegate.send(pluginResult, callbackId: callbackId)
            return
        }
        
        defer { connectionManager.closeImplicitConnection(connection) }
        
        guard let base64Data = options["data"] as? String, let data = Data(base64Encoded: base64Data) else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus.error, messageAs: "Valid base64 data string is required")
            commandDelegate.send(pluginResult, callbackId: callbackId)
            return
        }
        
        var writeError: NSError?
        connection.write(data, error: &writeError)
        
        if let err = writeError {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus.error, messageAs: "Error printing raw data: \(err.localizedDescription)")
            commandDelegate.send(pluginResult, callbackId: callbackId)
        } else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus.ok, messageAs: "Raw data printed successfully")
            commandDelegate.send(pluginResult, callbackId: callbackId)
        }
    }
    
    func getStatus(options: [String: Any], connectionManager: PrinterConnectionManager, callbackId: String, commandDelegate: CDVCommandDelegate) {
        var error: Error?
        guard let connection = connectionManager.getOrOpenConnection(options: options, error: &error) else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus.error, messageAs: "Connection failed: \(error?.localizedDescription ?? "Unknown")")
            commandDelegate.send(pluginResult, callbackId: callbackId)
            return
        }
        
        defer { connectionManager.closeImplicitConnection(connection) }
        
        do {
            let printer = try ZebraPrinterFactory.getInstance(connection)
            let printerStatus = try printer.getCurrentStatus()

            var statusDict: [String: Any] = [:]
            statusDict["isReadyToPrint"] = printerStatus.isReadyToPrint
            statusDict["isPaused"] = printerStatus.isPaused
            statusDict["isHeadOpen"] = printerStatus.isHeadOpen
            statusDict["isPaperOut"] = printerStatus.isPaperOut
            statusDict["isRibbonOut"] = printerStatus.isRibbonOut
            statusDict["labelsRemainingInBatch"] = printerStatus.labelsRemainingInBatch

            let pluginResult = CDVPluginResult(status: CDVCommandStatus.ok, messageAs: statusDict)
            commandDelegate.send(pluginResult, callbackId: callbackId)
        } catch let err {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus.error, messageAs: "Printer error: \(err.localizedDescription)")
            commandDelegate.send(pluginResult, callbackId: callbackId)
        }
    }
    
    func getSetting(variable: String, connectionManager: PrinterConnectionManager, callbackId: String, commandDelegate: CDVCommandDelegate) {
        var error: Error?
        guard let connection = connectionManager.getOrOpenConnection(options: nil, error: &error) else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus.error, messageAs: "Connection failed: \(error?.localizedDescription ?? "Unknown")")
            commandDelegate.send(pluginResult, callbackId: callbackId)
            return
        }
        
        defer { connectionManager.closeImplicitConnection(connection) }

        do {
            let value = try SGD.get(variable, withPrinterConnection: connection)
            let pluginResult = CDVPluginResult(status: CDVCommandStatus.ok, messageAs: value)
            commandDelegate.send(pluginResult, callbackId: callbackId)
        } catch let err {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus.error, messageAs: "Error getting setting: \(err.localizedDescription)")
            commandDelegate.send(pluginResult, callbackId: callbackId)
        }
    }
    
    func setSetting(variable: String, value: String, connectionManager: PrinterConnectionManager, callbackId: String, commandDelegate: CDVCommandDelegate) {
        var error: Error?
        guard let connection = connectionManager.getOrOpenConnection(options: nil, error: &error) else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus.error, messageAs: "Connection failed: \(error?.localizedDescription ?? "Unknown")")
            commandDelegate.send(pluginResult, callbackId: callbackId)
            return
        }
        
        defer { connectionManager.closeImplicitConnection(connection) }

        do {
            try SGD.set(variable, withValue: value, andWithPrinterConnection: connection)
            let pluginResult = CDVPluginResult(status: CDVCommandStatus.ok, messageAs: "Setting updated")
            commandDelegate.send(pluginResult, callbackId: callbackId)
        } catch let err {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus.error, messageAs: "Error setting setting: \(err.localizedDescription)")
            commandDelegate.send(pluginResult, callbackId: callbackId)
        }
    }
}
