import Foundation

@objc(ZebraPrintPlugin) class ZebraPrintPlugin: CDVPlugin {
    
    lazy var discoveryManager = PrinterDiscoveryManager()
    lazy var connectionManager = PrinterConnectionManager()
    lazy var printJobManager = PrintJobManager()

    override func pluginInitialize() {
        super.pluginInitialize()
        // Initialization if needed
    }

    @objc(discover:)
    func discover(command: CDVInvokedUrlCommand) {
        let options = command.arguments.first as? [String: Any] ?? [:]
        
        self.commandDelegate.run(inBackground: {
            self.discoveryManager.discover(options: options, callbackId: command.callbackId, commandDelegate: self.commandDelegate)
        })
    }

    @objc(connect:)
    func connect(command: CDVInvokedUrlCommand) {
        let options = command.arguments.first as? [String: Any] ?? [:]
        
        self.commandDelegate.run(inBackground: {
            self.connectionManager.connect(options: options, callbackId: command.callbackId, commandDelegate: self.commandDelegate)
        })
    }

    @objc(disconnect:)
    func disconnect(command: CDVInvokedUrlCommand) {
        self.commandDelegate.run(inBackground: {
            self.connectionManager.disconnect(callbackId: command.callbackId, commandDelegate: self.commandDelegate)
        })
    }

    @objc(isConnected:)
    func isConnected(command: CDVInvokedUrlCommand) {
        self.commandDelegate.run(inBackground: {
            self.connectionManager.isConnected(callbackId: command.callbackId, commandDelegate: self.commandDelegate)
        })
    }

    @objc(printPdf:)
    func printPdf(command: CDVInvokedUrlCommand) {
        let options = command.arguments.first as? [String: Any] ?? [:]
        
        self.commandDelegate.run(inBackground: {
            self.printJobManager.printPdf(options: options, connectionManager: self.connectionManager, callbackId: command.callbackId, commandDelegate: self.commandDelegate)
        })
    }

    @objc(printZpl:)
    func printZpl(command: CDVInvokedUrlCommand) {
        let options = command.arguments.first as? [String: Any] ?? [:]
        
        self.commandDelegate.run(inBackground: {
            self.printJobManager.printZpl(options: options, connectionManager: self.connectionManager, callbackId: command.callbackId, commandDelegate: self.commandDelegate)
        })
    }

    @objc(printCpcl:)
    func printCpcl(command: CDVInvokedUrlCommand) {
        let options = command.arguments.first as? [String: Any] ?? [:]
        
        self.commandDelegate.run(inBackground: {
            self.printJobManager.printCpcl(options: options, connectionManager: self.connectionManager, callbackId: command.callbackId, commandDelegate: self.commandDelegate)
        })
    }

    @objc(printRaw:)
    func printRaw(command: CDVInvokedUrlCommand) {
        let options = command.arguments.first as? [String: Any] ?? [:]
        
        self.commandDelegate.run(inBackground: {
            self.printJobManager.printRaw(options: options, connectionManager: self.connectionManager, callbackId: command.callbackId, commandDelegate: self.commandDelegate)
        })
    }

    @objc(getStatus:)
    func getStatus(command: CDVInvokedUrlCommand) {
        let options = command.arguments.first as? [String: Any] ?? [:]
        
        self.commandDelegate.run(inBackground: {
            self.printJobManager.getStatus(options: options, connectionManager: self.connectionManager, callbackId: command.callbackId, commandDelegate: self.commandDelegate)
        })
    }

    @objc(getSetting:)
    func getSetting(command: CDVInvokedUrlCommand) {
        let variable = command.arguments[0] as? String ?? ""
        
        self.commandDelegate.run(inBackground: {
            self.printJobManager.getSetting(variable: variable, connectionManager: self.connectionManager, callbackId: command.callbackId, commandDelegate: self.commandDelegate)
        })
    }

    @objc(setSetting:)
    func setSetting(command: CDVInvokedUrlCommand) {
        let variable = command.arguments[0] as? String ?? ""
        let value = command.arguments[1] as? String ?? ""
        
        self.commandDelegate.run(inBackground: {
            self.printJobManager.setSetting(variable: variable, value: value, connectionManager: self.connectionManager, callbackId: command.callbackId, commandDelegate: self.commandDelegate)
        })
    }
}
