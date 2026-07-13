import Foundation
import ExternalAccessory

class PrinterConnectionManager {
    
    private var currentConnection: (NSObject & ZebraPrinterConnection)?
    
    func getConnection() -> (NSObject & ZebraPrinterConnection)? {
        return currentConnection
    }
    
    func getOrOpenConnection(options: [String: Any]?, error: inout Error?) -> (NSObject & ZebraPrinterConnection)? {
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
        } else if let lastAddress = UserDefaults.standard.string(forKey: "ZebraPrintLastAddress") {
            // Auto-reconnect
            let lastType = UserDefaults.standard.string(forKey: "ZebraPrintLastType") ?? "bluetooth"
            do {
                let tempConn = try createConnection(address: lastAddress, type: lastType, port: 9100)
                tempConn.open()
                return tempConn
            } catch let err {
                error = err
                return nil
            }
        } else {
            error = NSError(domain: "ZebraPrint", code: 1, userInfo: [NSLocalizedDescriptionKey: "No active connection and no address provided."])
            return nil
        }
    }
    
    func closeImplicitConnection(_ connection: (NSObject & ZebraPrinterConnection)?) {
        if let conn = connection, conn !== currentConnection {
            conn.close()
        }
    }
    
    func connect(options: [String: Any], callbackId: String, commandDelegate: CDVCommandDelegate) {
        let type = (options["type"] as? String ?? "bluetooth").lowercased()
        let port = options["port"] as? Int ?? 9100
        let address: String
        if let addr = options["address"] as? String {
            address = addr
        } else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Address is required to connect")
            commandDelegate.send(pluginResult, callbackId: callbackId)
            return
        }
        
        if let conn = currentConnection, conn.isConnected() {
            conn.close()
        }
        
        do {
            currentConnection = try createConnection(address: address, type: type, port: port)
            let success = currentConnection?.open() ?? false
            
            if success {
                UserDefaults.standard.set(address, forKey: "ZebraPrintLastAddress")
                UserDefaults.standard.set(type, forKey: "ZebraPrintLastType")
                
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
    
    private func createConnection(address: String, type: String, port: Int) throws -> NSObject & ZebraPrinterConnection {
        switch type.lowercased() {
        case "tcp", "network":
            #if targetEnvironment(simulator)
            return TcpPrinterConnection(address: address, andWithPort: port)
            #else
            return TcpPrinterConnection(address: address, andWithPort: port)
            #endif
        case "bluetooth":
            #if targetEnvironment(simulator)
            throw NSError(domain: "ZebraPrint", code: 4, userInfo: [NSLocalizedDescriptionKey: "Bluetooth/MFi is not supported in Simulator. Please test on a physical device."])
            #else
            if let conn = MfiBtPrinterConnection(serialNumber: address) {
                return conn
            }
            throw NSError(domain: "ZebraPrint", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to initialize MfiBtPrinterConnection for serial: \(address)"])
            #endif
        default:
            #if targetEnvironment(simulator)
            // Default to TCP in simulator for convenience
            return TcpPrinterConnection(address: address, andWithPort: port)
            #else
            if let conn = MfiBtPrinterConnection(serialNumber: address) {
                return conn
            }
            throw NSError(domain: "ZebraPrint", code: 2, userInfo: [NSLocalizedDescriptionKey: "Unsupported connection type: \(type)"])
            #endif
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
