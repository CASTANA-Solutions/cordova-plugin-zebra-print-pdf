var exec = require('cordova/exec');

exports.echo = function(echoString, successCallback, errorCallback) {
    cordova.exec(successCallback, errorCallback, 'ZebraPrintPdf', 'echo', [echoString]);
};

exports.discoverPrinters = function(successCallback, errorCallback) {
    cordova.exec(successCallback, errorCallback, 'ZebraPrintPdf', 'discoverPrinters', []);
};

exports.printImage = function(base64, MACAddress, speed, time, number, successCallback, errorCallback) {
    cordova.exec(successCallback, errorCallback, 'ZebraPrintPdf', 'printImage', [base64, MACAddress, speed, time, number]);
};

exports.getPrinterName = function(MACAddress, successCallback, errorCallback) {
    cordova.exec(successCallback, errorCallback, 'ZebraPrintPdf', 'getPrinterName', [MACAddress]);
};

exports.sendFile = function(MACAddress, pdfPath, successCallback, errorCallback) {
    cordova.exec(successCallback, errorCallback, 'ZebraPrintPdf', 'sendFile', [MACAddress, pdfPath]);
};

exports.getMacAddress = function(printerName, successCallback, errorCallback) {
    cordova.exec(successCallback, errorCallback, 'ZebraPrintPdf', 'getPrinterMacAddress', [printerName]);
};