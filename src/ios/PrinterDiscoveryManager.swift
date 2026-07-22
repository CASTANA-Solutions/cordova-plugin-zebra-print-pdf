import Foundation
import ExternalAccessory

class PrinterDiscoveryManager {
    
    func discover(options: [String: Any], callbackId: String, commandDelegate: CDVCommandDelegate) {
        let useBluetooth = options["bluetooth"] as? Bool ?? true
        let useNetwork = options["network"] as? Bool ?? true
        
        var foundPrinters: [[String: Any]] = []
        let dispatchGroup = DispatchGroup()
        
        if useBluetooth {
            let sam = EAAccessoryManager.shared()
            let connectedAccessories = sam.connectedAccessories
            
            for accessory in connectedAccessories {
                if accessory.protocolStrings.contains("com.zebra.rawport") {
                    var printer: [String: Any] = [:]
                    printer["name"] = accessory.name
                    printer["address"] = accessory.serialNumber
                    printer["type"] = "bluetooth"
                    printer["serialNumber"] = accessory.serialNumber
                    printer["model"] = accessory.modelNumber
                    printer["isConnected"] = false
                    
                    foundPrinters.append(printer)
                }
            }
        }
        
        if useNetwork {
            dispatchGroup.enter()
            
            DispatchQueue.global().async {
                var error: NSError?
                if let discoveredPrinters = NetworkDiscoverer.localBroadcast(&error) as? [DiscoveredPrinter] {
                    for dp in discoveredPrinters {
                        var printer: [String: Any] = [:]
                        printer["address"] = dp.address

                        let dataMap = dp.discoveryDataMap as? [String: String] ?? [:]
                        printer["name"] = dataMap["FRIENDLY_NAME"] ?? dataMap["PRODUCT_NAME"] ?? dp.address
                        printer["type"] = "network"
                        printer["serialNumber"] = dataMap["SYSTEM_NAME"]
                        printer["model"] = dataMap["HARDWARE_COMPATIBILITY"]
                        printer["isConnected"] = false

                        objc_sync_enter(self)
                        foundPrinters.append(printer)
                        objc_sync_exit(self)
                    }
                }
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .global()) {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus.ok, messageAs: foundPrinters)
            commandDelegate.send(pluginResult, callbackId: callbackId)
        }
    }
}
