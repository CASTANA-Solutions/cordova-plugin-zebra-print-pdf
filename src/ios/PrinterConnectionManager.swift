import Foundation
import ExternalAccessory

class PrinterConnectionManager {
    
    private var currentConnection: ZebraPrinterConnection?
    
    func getConnection() -> ZebraPrinterConnection? {
        return currentConnection
    }
    
    func getOrOpenConnection(options: [String: Any]?, error: inout Error?) -> ZebraPrinterConnection? {
        if let opts = options, let address = opts["address"] as? String {
            // Implicit connect
            do {
                let tempConn = try createConnection(address: address, type: opts["type"] as? String ?? "bluetooth", port: opts["port"] as? Int ?? 9100)
                tempConn.open()
                return tempConn
            } catch let err {
                error = err
                return nil
            }
        } else if let conn = currentConnection, conn.isConnected() {
            return conn
        } else {
            error = NSError(domain: "ZebraPrint", code: 1, userInfo: [NSLocalizedDescriptionKey: "No active connection and no address provided."])
            return nil
        }
    }
    
    func closeImplicitConnection(_ connection: ZebraPrinterConnection?) {
        if let conn = connection, conn !== currentConnection {
            conn.close()
        }
    }
    
    func connect(options: [String: Any], callbackId: String, commandDelegate: CDVCommandDelegate) {
        guard let address = options["address"] as? String else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Address is required to connect")
            commandDelegate.send(pluginResult, callbackId: callbackId)
            return
        }
        
        let type = options["type"] as? String ?? "bluetooth"
        let port = options["port"] as? Int ?? 9100
        
        if let conn = currentConnection, conn.isConnected() {
            conn.close()
        }
        
        do {
            currentConnection = try createConnection(address: address, type: type, port: port)
            let success = currentConnection?.open() ?? false
            
            if success {
                let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: "Connected to \(address)")
                commandDelegate.send(pluginResult, callbackId: callbackId)
            } else {
                currentConnection = nil
                let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Failed to open connection")
                commandDelegate.send(pluginResult, callbackId: callbackId)
            }
        } catch let err {
            currentConnection = nil
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Connection failed: \(err.localizedDescription)")
            commandDelegate.send(pluginResult, callbackId: callbackId)
        }
    }
    
    private func createConnection(address: String, type: String, port: Int) throws -> ZebraPrinterConnection {
        switch type.lowercased() {
        case "tcp", "network":
            return TcpPrinterConnection(address: address, andWithPort: Int(port))
        case "bluetooth":
            // address should be the serialNumber for MFi Bluetooth
            if let conn = MfiBtPrinterConnection(serialNumber: address) {
                return conn
            }
            throw NSError(domain: "ZebraPrint", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to initialize MfiBtPrinterConnection for serial: \(address)"])
        default:
            if let conn = MfiBtPrinterConnection(serialNumber: address) {
                return conn
            }
            throw NSError(domain: "ZebraPrint", code: 2, userInfo: [NSLocalizedDescriptionKey: "Unsupported connection type: \(type)"])
        }
    }
    
    func disconnect(callbackId: String?, commandDelegate: CDVCommandDelegate?) {
        if let conn = currentConnection {
            conn.close()
            currentConnection = nil
            if let cbId = callbackId, let delegate = commandDelegate {
                let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: "Disconnected")
                delegate.send(pluginResult, callbackId: cbId)
            }
        } else {
            if let cbId = callbackId, let delegate = commandDelegate {
                let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: "Already disconnected")
                delegate.send(pluginResult, callbackId: cbId)
            }
        }
    }
    
    func isConnected(callbackId: String, commandDelegate: CDVCommandDelegate) {
        let connected = currentConnection?.isConnected() ?? false
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: ["connected": connected])
        commandDelegate.send(pluginResult, callbackId: callbackId)
    }
}
