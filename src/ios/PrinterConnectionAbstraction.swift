import Foundation

// Unified connection protocol used by the app, so we can run on Simulator without MFi.
protocol PrinterConnection: AnyObject {
    @discardableResult func open() -> Bool
    func close()
    func isConnected() -> Bool
    func write(_ data: Data, error: NSErrorPointer)
}

// If the Zebra SDK is available, make its connection types conform to PrinterConnection.
#if canImport(ZSDKDeveloperKit)
import ZSDKDeveloperKit
#endif
#if canImport(ZebraSDK)
import ZebraSDK
#endif
#if canImport(ZSDKDeveloperKit) || canImport(ZebraSDK)
extension TcpPrinterConnection: PrinterConnection {}
extension MfiBtPrinterConnection: PrinterConnection {}
#endif

#if canImport(Network)
import Network
#endif

#if targetEnvironment(simulator)
#if canImport(Network)
// A simple TCP connection implementation for Simulator testing.
final class NWPrinterConnection: PrinterConnection {
    private let host: NWEndpoint.Host
    private let port: NWEndpoint.Port
    private var connection: NWConnection?
    private var connected = false

    init?(host: String, port: Int) {
        guard let nwPort = NWEndpoint.Port(rawValue: UInt16(port)) else { return nil }
        self.host = NWEndpoint.Host(host)
        self.port = nwPort
    }

    @discardableResult
    func open() -> Bool {
        let conn = NWConnection(host: host, port: port, using: .tcp)
        connection = conn
        let group = DispatchGroup()
        group.enter()
        conn.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                self?.connected = true
                group.leave()
            case .failed(_), .cancelled:
                self?.connected = false
                group.leave()
            default:
                break
            }
        }
        conn.start(queue: .global(qos: .userInitiated))
        // Wait briefly for readiness (up to 2s) for a simple synchronous open()
        let result = group.wait(timeout: .now() + 2)
        if result == .timedOut {
            // Keep connection running; report not yet connected
            return false
        }
        return connected
    }

    func close() {
        connection?.cancel()
        connection = nil
        connected = false
    }

    func isConnected() -> Bool {
        connected
    }
    
    func write(_ data: Data, error: NSErrorPointer) {
        let group = DispatchGroup()
        group.enter()
        connection?.send(content: data, completion: .contentProcessed({ err in
            if let err = err {
                error?.pointee = err as NSError
            }
            group.leave()
        }))
        group.wait(timeout: .now() + 2)
    }
}
#endif
#endif


