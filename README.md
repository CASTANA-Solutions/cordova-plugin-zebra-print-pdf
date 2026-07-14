# cordova-plugin-zebra-print-pdf

A unified, modern Cordova plugin for Zebra printers. Supports PDF, ZPL, CPCL and RAW printing via Bluetooth and Network (TCP/WiFi) on Android and iOS.

### Legacy information

Current version is a complete rework. Last legacy version: 1.2.6

---

[Deutsch](#deutsch) | [English](#english)

---

<a name="english"></a>
## English

### Features

- **Modern Promise-based API**: Full support for `async/await`.
- **Legacy Compatibility**: Fully backwards compatible with the old `cordova.plugins.ZebraPrintManager` callback syntax.
- **Cross-platform**: Unified API for Android and iOS.
- **Connections**: Bluetooth (Classic & MFi), TCP/WiFi.
- **Print Formats**:
  - PDF Direct (Requires Zebra printer with Link-OS v6.3+ and PDF Direct Virtual Device enabled). Supports printing both local files and Base64 strings.
  - ZPL
  - CPCL
  - Raw (Base64)
- **Status Monitoring**: Paper out, paused, head open, etc.
- **Configuration**: Send and receive SGD (Set-Get-Do) commands.
- **Discovery**: Search for printers on the network or via Bluetooth.

### Installation

```bash
cordova plugin add cordova-plugin-zebra-print-julian
```

**IMPORTANT:** This plugin requires the *Zebra Link-OS Multiplatform SDK*. You must add the SDK files manually if you fork the source:
1. Download the SDK from Zebra.
2. Copy `ZSDK_ANDROID_API.jar` to `src/android/libs/` in the plugin folder.
3. Copy `ZSDK_API.xcframework` to `src/ios/libs/` in the plugin folder.
*(Note: If you install via NPM, the SDK is already bundled inside the package!)*

### API Reference (Modern Async/Await)

All modern methods are available in the global `window.ZebraPrint` object and return a Promise.

#### Discover Printers

```javascript
try {
    const printers = await window.ZebraPrint.discover({
        bluetooth: true, // Optional, default: true
        network: true,   // Optional, default: true
        timeout: 5000    // Optional, in ms, default: 5000
    });
    console.log("Found printers:", printers);
} catch (error) {
    console.error("Discovery failed:", error);
}
```

#### Connect & Disconnect

```javascript
// Connect
try {
    await window.ZebraPrint.connect({
        address: "AA:BB:CC:DD:EE:FF", // MAC or IP or Serial Number (iOS MFi)
        type: "bluetooth",            // "bluetooth" or "tcp"
        port: 9100                    // Only relevant for tcp
    });
    console.log("Connected!");
} catch (error) {
    console.error("Connection failed", error);
}

// Disconnect
await window.ZebraPrint.disconnect();

// Check connection status
const result = await window.ZebraPrint.isConnected();
console.log("Connected:", result.connected); // true/false
```

#### Printing

```javascript
// Print PDF (File Path)
await window.ZebraPrint.printPdf({
    filePath: "/path/to/local/file.pdf"
});

// Print PDF (Base64 String)
await window.ZebraPrint.printPdf({
    base64: "JVBERi0xLjQK..." // Raw Base64 string without data URI prefix
});

// Print ZPL
await window.ZebraPrint.printZpl({
    zpl: "^XA^FO50,50^A0N,50,50^FDHello Zebra!^FS^XZ"
});

// Print CPCL
await window.ZebraPrint.printCpcl({
    cpcl: "! 0 200 200 210 1\r\nTEXT 4 0 30 40 Hello World\r\nPRINT\r\n"
});
```

#### Status & Settings

```javascript
const status = await window.ZebraPrint.getStatus();
console.log("Ready?", status.isReadyToPrint);
console.log("Paper out?", status.isPaperOut);

// Read SGD
const value = await window.ZebraPrint.getSetting("device.friendly_name");
console.log("Printer name:", value);

// Set SGD
await window.ZebraPrint.setSetting("device.friendly_name", "MyPrinter");
```

### Legacy API (Backwards Compatibility)

If you are migrating from the old `cordova-plugin-zebra-print-pdf`, this plugin serves as a **drop-in replacement**. You don't need to change any Javascript code in your app!

It exposes the old API under `cordova.plugins.zebraPrintPdf` for full backwards compatibility:

```javascript
// Get list of connected devices (Returns a JSON String of an array with objects: [{ name: "...", macaddress: "..." }])
cordova.plugins.zebraPrintPdf.getListConnectedBluetoothDevices(function(devices) {
    var deviceList = JSON.parse(devices);
    console.log(deviceList);
});

// Get printer name from MAC Address
cordova.plugins.zebraPrintPdf.getPrinterName("AA:BB:CC:DD:EE:FF", function(name) { ... });

// Get MAC Address from printer name
cordova.plugins.zebraPrintPdf.getPrinterMacAddress("Zebra Printer", function(mac) { ... });

// Print a PDF file directly via Bluetooth (connects, prints, and disconnects automatically)
cordova.plugins.zebraPrintPdf.sendFile("AA:BB:CC:DD:EE:FF", "file:///path/to/file.pdf", successCallback, errorCallback);
```

---

<a name="deutsch"></a>
## Deutsch

### Features

- **Moderne Promise-basierte API**: Volle Unterstützung für `async/await`.
- **Legacy Kompatibilität**: Vollständig rückwärtskompatibel mit der alten `cordova.plugins.ZebraPrintManager` Callbacks-Syntax.
- **Plattformübergreifend**: Einheitliche API für Android und iOS.
- **Verbindungen**: Bluetooth (Classic & MFi), TCP/WiFi.
- **Druckformate**:
  - PDF Direct (erfordert Zebra-Drucker mit Link-OS v6.3+ und aktiviertem PDF Direct Virtual Device). Unterstützt den Druck von lokalen Dateien als auch von Base64-Strings.
  - ZPL
  - CPCL
  - Raw (Base64)
- **Statusabfrage**: Papierstatus, Pausenstatus, offener Druckkopf etc.
- **Konfiguration**: SGD (Set-Get-Do) Befehle senden und empfangen.
- **Discovery**: Drucker im Netzwerk oder über Bluetooth suchen.

### Installation

```bash
cordova plugin add cordova-plugin-zebra-print-julian
```

**WICHTIG:** Das Plugin benötigt das *Zebra Link-OS Multiplatform SDK*. Du musst die SDK-Dateien manuell hinzufügen, wenn du den Source Code clonst:
1. Lade das SDK von Zebra herunter.
2. Kopiere `ZSDK_ANDROID_API.jar` nach `src/android/libs/`.
3. Kopiere `ZSDK_API.xcframework` nach `src/ios/libs/`.
*(Hinweis: Bei Installation über NPM ist das SDK bereits im Paket enthalten!)*

### API Referenz (Modernes Async/Await)

Alle modernen Methoden befinden sich im globalen Objekt `window.ZebraPrint` und geben ein Promise zurück.

#### Drucker suchen (Discovery)

```javascript
try {
    const printers = await window.ZebraPrint.discover({
        bluetooth: true, // Optional, default: true
        network: true,   // Optional, default: true
        timeout: 5000    // Optional, in ms, default: 5000
    });
    console.log("Gefundene Drucker:", printers);
} catch (error) {
    console.error("Suche fehlgeschlagen:", error);
}
```

#### Verbinden & Trennen

```javascript
// Verbinden
try {
    await window.ZebraPrint.connect({
        address: "AA:BB:CC:DD:EE:FF", // MAC oder IP oder Seriennummer (iOS MFi)
        type: "bluetooth",            // "bluetooth" oder "tcp"
        port: 9100                    // Nur für tcp relevant
    });
    console.log("Verbunden!");
} catch (error) {
    console.error("Fehler beim Verbinden", error);
}

// Trennen
await window.ZebraPrint.disconnect();

// Prüfen ob verbunden
const result = await window.ZebraPrint.isConnected();
console.log("Verbunden:", result.connected); // true/false
```

#### Drucken

```javascript
// PDF Drucken (Dateipfad)
await window.ZebraPrint.printPdf({
    filePath: "/pfad/zur/lokalen/datei.pdf"
});

// PDF Drucken (Base64 String)
await window.ZebraPrint.printPdf({
    base64: "JVBERi0xLjQK..." // Reiner Base64-String ohne Data-URI-Präfix
});

// ZPL Drucken
await window.ZebraPrint.printZpl({
    zpl: "^XA^FO50,50^A0N,50,50^FDHallo Zebra!^FS^XZ"
});
```

#### Status & Einstellungen

```javascript
const status = await window.ZebraPrint.getStatus();
console.log("Bereit?", status.isReadyToPrint);
console.log("Papier leer?", status.isPaperOut);

// SGD Lesen
const value = await window.ZebraPrint.getSetting("device.friendly_name");
console.log("Druckername:", value);

// SGD Setzen
await window.ZebraPrint.setSetting("device.friendly_name", "MeinDrucker");
```

### Legacy API (Rückwärtskompatibilität)

Wenn du von dem alten `cordova-plugin-zebra-print-pdf` migrierst, dient dieses Plugin als direkter **Drop-in Replacement**. Du musst deinen existierenden Javascript-Code in der App nicht anpassen!

Es stellt die alte API weiterhin unter `cordova.plugins.zebraPrintPdf` zur Verfügung:

```javascript
// Liste verbundener Geräte abrufen (Gibt einen JSON-String zurück: [{ name: "...", macaddress: "..." }])
cordova.plugins.zebraPrintPdf.getListConnectedBluetoothDevices(function(devices) {
    var deviceList = JSON.parse(devices);
    console.log(deviceList);
});

// Druckernamen anhand der MAC-Adresse abfragen
cordova.plugins.zebraPrintPdf.getPrinterName("AA:BB:CC:DD:EE:FF", function(name) { ... });

// MAC-Adresse anhand des Druckernamens abfragen
cordova.plugins.zebraPrintPdf.getPrinterMacAddress("Zebra Drucker", function(mac) { ... });

// Ein PDF direkt per Bluetooth drucken (verbindet, druckt und trennt automatisch)
cordova.plugins.zebraPrintPdf.sendFile("AA:BB:CC:DD:EE:FF", "file:///pfad/zur/datei.pdf", successCallback, errorCallback);
```
