var exec = require('cordova/exec');

/**
 * Helper function to support both Promise and Callback paradigms.
 * If callbacks are provided, they are called. Otherwise, a Promise is returned.
 * @param {string} action The name of the action to execute in the native plugin.
 * @param {Array} args The arguments to pass to the native plugin.
 * @param {Function} [successCallback] Optional success callback.
 * @param {Function} [errorCallback] Optional error callback.
 * @returns {Promise|void} A Promise if no callbacks are provided, otherwise void.
 */
function execPromise(action, args, successCallback, errorCallback) {
    if (typeof successCallback === 'function' || typeof errorCallback === 'function') {
        exec(successCallback, errorCallback, 'ZebraPrint', action, args);
    } else {
        return new Promise(function(resolve, reject) {
            exec(resolve, reject, 'ZebraPrint', action, args);
        });
    }
}

/**
 * Unified Cordova Plugin for Zebra Printers.
 * Supports native PDF, ZPL, and CPCL printing on Android and iOS.
 */
var ZebraPrint = {

    // ==========================================
    // MODERN API (Promises & Callbacks supported)
    // ==========================================

    /**
     * Discovers available Zebra printers via Bluetooth or Network.
     * @param {Object|string} options Options object (e.g. { bluetooth: true }) or string ('bluetooth').
     * @param {Function} [success] Optional success callback.
     * @param {Function} [error] Optional error callback.
     * @returns {Promise<Array>} Resolves with an array of discovered printers.
     */
    discover: function(options, success, error) {
        return execPromise('discover', [options], success, error);
    },

    /**
     * Connects to a Zebra printer.
     * @param {Object} options Printer connection options (e.g. { address: 'MAC', type: 'bluetooth' }).
     * @param {Function} [success] Optional success callback.
     * @param {Function} [error] Optional error callback.
     * @returns {Promise<string>} Resolves when connection is successful.
     */
    connect: function(options, success, error) {
        return execPromise('connect', [options], success, error);
    },

    /**
     * Disconnects from the currently connected printer.
     * @param {Function} [success] Optional success callback.
     * @param {Function} [error] Optional error callback.
     * @returns {Promise<string>} Resolves when disconnected.
     */
    disconnect: function(success, error) {
        return execPromise('disconnect', [], success, error);
    },

    /**
     * Checks if a printer is currently connected.
     * @param {Function} [success] Optional success callback.
     * @param {Function} [error] Optional error callback.
     * @returns {Promise<boolean>} Resolves with the connection status.
     */
    isConnected: function(success, error) {
        return execPromise('isConnected', [], success, error);
    },

    /**
     * Prints a PDF document natively (Requires PDF Direct on printer).
     * @param {Object|string} options Base64 string, file path, or options object { base64: '...' }.
     * @param {Function} [success] Optional success callback.
     * @param {Function} [error] Optional error callback.
     * @returns {Promise<string>} Resolves when the print job is successfully sent.
     */
    printPdf: function(options, success, error) {
        var opts = options;
        if (typeof options === 'string') {
            if (options.indexOf('data:') === 0) {
                var parts = options.split(',');
                opts = { base64: parts.length > 1 ? parts[1] : options };
            } else if (options.indexOf('JVBER') === 0 || options.length > 500) {
                opts = { base64: options };
            } else {
                opts = { filePath: options };
            }
        }
        return execPromise('printPdf', [opts], success, error);
    },
    printPDF: function(options, success, error) { return this.printPdf(options, success, error); },

    /**
     * Prints ZPL code to the printer.
     * @param {Object|string} options ZPL string or options object { zpl: '...' }.
     * @param {Function} [success] Optional success callback.
     * @param {Function} [error] Optional error callback.
     * @returns {Promise<string>} Resolves when the print job is sent.
     */
    printZpl: function(options, success, error) {
        var opts = typeof options === 'string' ? { zpl: options } : options;
        return execPromise('printZpl', [opts], success, error);
    },
    printZPL: function(options, success, error) { return this.printZpl(options, success, error); },

    /**
     * Prints CPCL code to the printer.
     * @param {Object|string} options CPCL string or options object { cpcl: '...' }.
     * @param {Function} [success] Optional success callback.
     * @param {Function} [error] Optional error callback.
     * @returns {Promise<string>} Resolves when the print job is sent.
     */
    printCpcl: function(options, success, error) {
        var opts = typeof options === 'string' ? { cpcl: options } : options;
        return execPromise('printCpcl', [opts], success, error);
    },
    printCPCL: function(options, success, error) { return this.printCpcl(options, success, error); },

    /**
     * Retrieves the current hardware status of the printer.
     * @param {Object} [options] Optional parameters.
     * @param {Function} [success] Optional success callback.
     * @param {Function} [error] Optional error callback.
     * @returns {Promise<Object>} Resolves with printer status details.
     */
    getStatus: function(options, success, error) {
        if (typeof options === 'function') {
            error = success;
            success = options;
            options = {};
        }
        return execPromise('getStatus', [options || {}], success, error);
    },



    // ==========================================
    // LEGACY API (Backwards Compatibility Layer)
    // For `cordova-plugin-zebra-print-pdf`
    // ==========================================

    /**
     * Legacy echo command.
     */
    echo: function(echoString, successCallback, errorCallback) {
        if (typeof successCallback === 'function') {
            successCallback(echoString);
        }
    },

    /**
     * Legacy method to get printer name. Maps to discovery.
     */
    getPrinterName: function(MACAddress, successCallback, errorCallback) {
        this.discover('bluetooth', function(printers) {
            var found = printers.find(function(p) { return p.address === MACAddress; });
            if (found && successCallback) {
                successCallback(found.name);
            } else if (errorCallback) {
                errorCallback('Printer not found');
            }
        }, errorCallback);
    },

    /**
     * Legacy method to get Mac Address by name. Maps to discovery.
     */
    getMacAddress: function(printerName, successCallback, errorCallback) {
        this.discover('bluetooth', function(printers) {
            var found = printers.find(function(p) { return p.name === printerName; });
            if (found && successCallback) {
                successCallback(found.address);
            } else if (errorCallback) {
                errorCallback('Printer not found');
            }
        }, errorCallback);
    },

    /**
     * Legacy method to get connected bluetooth devices.
     * Our modern equivalent is `discover('bluetooth')`.
     */
    getListConnectedBluetoothDevices: function(successCallback, errorCallback) {
        this.discover('bluetooth', function(printers) {
            if (successCallback) {
                var legacyPrinters = printers.map(function(p) {
                    return { name: p.name, macaddress: p.address };
                });
                if (typeof printers === "string") {
                    legacyPrinters = printers.map(function(p) {
                        return { name: p.name, macaddress: p.macaddress };
                    });
                }
                successCallback(JSON.stringify(legacyPrinters));
            }
        }, errorCallback);
    },

    /**
     * Legacy print method. Automates connect -> print -> disconnect flow.
     */
    sendFile: function(MACAddress, pdfPath, successCallback, errorCallback) {
        var self = this;
        this.connect({ address: MACAddress, type: 'bluetooth' }, function() {
            self.printPdf(pdfPath, function(res) {
                self.disconnect(function() {
                    if (successCallback) successCallback(res);
                }, errorCallback);
            }, function(err) {
                self.disconnect();
                if (errorCallback) errorCallback(err);
            });
        }, errorCallback);
    }
};

module.exports = ZebraPrint;
