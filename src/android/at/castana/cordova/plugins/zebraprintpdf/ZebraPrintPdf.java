package at.castana.cordova.plugins.zebraprintpdf;

import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.os.Looper;
import android.util.Base64;
import android.util.Log;
import android.content.Context;
import android.os.Bundle;
import android.os.Looper;
import android.os.Build;
import android.Manifest;
import android.content.pm.PackageManager;

import com.zebra.sdk.comm.BluetoothConnection;
import com.zebra.sdk.comm.Connection;
import com.zebra.sdk.comm.ConnectionException;
import com.zebra.sdk.graphics.internal.ZebraImageAndroid;
import com.zebra.sdk.printer.PrinterStatus;
import com.zebra.sdk.printer.SGD;
import com.zebra.sdk.printer.ZebraPrinter;
import com.zebra.sdk.printer.ZebraPrinterFactory;
import com.zebra.sdk.printer.ZebraPrinterLanguageUnknownException;
import com.zebra.sdk.printer.ZebraPrinterLinkOs;
import com.zebra.sdk.printer.discovery.BluetoothDiscoverer;
import com.zebra.sdk.printer.discovery.DiscoveredPrinter;
import com.zebra.sdk.printer.discovery.DiscoveryHandler;
// For sendFile
import com.zebra.sdk.comm.TcpConnection;
import com.zebra.sdk.device.ZebraIllegalArgumentException;

import org.apache.cordova.PluginResult;
import org.apache.cordova.PermissionHelper;
import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaPlugin;
import org.json.JSONArray;
import org.json.JSONObject;
import org.json.JSONException;


import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.util.Set;
import java.util.ArrayList;


public class ZebraPrintPdf extends CordovaPlugin implements DiscoveryHandler {

    private static final String LOG_TAG = "ZebraPrintPdf";
    private CallbackContext callbackContext;
    private boolean printerFound;
    private Connection thePrinterConn;
    private PrinterStatus printerStatus;
    private ZebraPrinter printer;
    private final int MAX_PRINT_RETRIES = 1;
    private int speed;
    private int time;
    private int number;
    private String action;
    private JSONArray args;

    //    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
        this.action = action;
        this.args = args;
        this.callbackContext = callbackContext;

        if (isAndroid14OrHigher()) {
            if(!PermissionHelper.hasPermission(this, Manifest.permission.BLUETOOTH_CONNECT)) {
                int SOME_RESULT_CODE = 0;
                PermissionHelper.requestPermission(this, SOME_RESULT_CODE, Manifest.permission.BLUETOOTH_CONNECT);
                return false;
            }
            if(!PermissionHelper.hasPermission(this, Manifest.permission.BLUETOOTH_SCAN)) {
                int SOME_RESULT_CODE = 0;
                PermissionHelper.requestPermission(this, SOME_RESULT_CODE, Manifest.permission.BLUETOOTH_SCAN);
                return false;
            }
        }

        return this._execute();
    }

    private boolean isAndroid14OrHigher() {
        // return Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE; // Android 14 (API 34)
        // Use numeric value instead of UPSIDE_DOWN_CAKE to avoid compilation errors
        return Build.VERSION.SDK_INT >= 34; // Android 14 (API 34)
    }

    private boolean _execute() {

        if (this.action.equals("echo")) {
            try {
                String echoString = this.args.getString(0);
                sendEcho(echoString);
            } catch (Exception e) {
                Log.e(LOG_TAG, e.getMessage());
                e.printStackTrace();
                this.callbackContext.error(e.getMessage());
            }
            return true;
        } else if (this.action.equals("getPrinterMacAddress")) {
            try {
                String printerName = this.args.getString(0);
                getPrinterMacAddress(printerName);
            } catch (Exception e) {
                Log.e(LOG_TAG, e.getMessage());
                e.printStackTrace();
                this.callbackContext.error(e.getMessage());
            }
            return true;
        } else if (this.action.equals("getPrinterName")) {
            try {
                String MACAddress = this.args.getString(0);
                getPrinterName(MACAddress);
            } catch (Exception e) {
                Log.e(LOG_TAG, e.getMessage());
                e.printStackTrace();
                this.callbackContext.error(e.getMessage());
            }
            return true;
        } else if (this.action.equals("getListConnectedBluetoothDevices")) {
            try {
                getListConnectedBluetoothDevices();
            } catch (Exception e) {
                Log.e(LOG_TAG, e.getMessage());
                e.printStackTrace();
                this.callbackContext.error(e.getMessage());
            }
            return true;
        } else if (this.action.equals("sendFile")) {
            try {
                String MACAddress = this.args.getString(0);
                String pdfPath = this.args.getString(1);
                sendFile(MACAddress, pdfPath);
            } catch (Exception e) {
                Log.e(LOG_TAG, e.getMessage());
                e.printStackTrace();
                this.callbackContext.error(e.getMessage());
            }
            return true;
        } /*else if (this.action.equals("discoverPrinters")) {
            // Not implemented
            discoverPrinters();
            return true;
        } else if (this.action.equals("printImage")) {
            // Not implemented
            try {
                JSONArray labels = this.args.getJSONArray(0);
                String MACAddress = this.args.getString(1);
                speed = this.args.getInt(2);
                time = this.args.getInt(3);
                number = this.args.getInt(4);
                for (int i = 1; i < number; i++) {
                    labels.put(labels.get(0));
                }
                sendImage(labels, MACAddress);
            } catch (IOException e) {
                Log.e(LOG_TAG, e.getMessage());
                e.printStackTrace();
            }
            return true;
        }*/
        return false;
    }

    public void onRequestPermissionResult(int requestCode, String[] permissions,
                                          int[] grantResults) {
        for (int r : grantResults) {
            if (r == PackageManager.PERMISSION_DENIED) {
                this.callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.ERROR));
                return;
            }
        }
        this._execute();
        // switch (requestCode) {
            // case SOME_INT_CODE:
            //     someFunction(this.destType, this.encodingType);
            //     break;
        // }
    }

    private void sendEcho(final String echoString) throws Exception {
        new Thread(new Runnable() {
            @Override
            public void run() {
                callbackContext.success(echoString);
            }
        }).start();
    }

    private void getPrinterName(final String macAddress) throws Exception {
        new Thread(new Runnable() {
            @Override
            public void run() {
                try {
                    String printerName = searchPrinterNameForMacAddress(macAddress);
                    if (printerName != null) {
                        Log.d(LOG_TAG, "Successfully found connected printer with name " + printerName);
                        callbackContext.success(printerName);
                    } else {
                        callbackContext.error("No printer found. If the problem persists, restart the printer.");
                    }
                } catch (Exception e) {
                    callbackContext.error(e.getMessage());
                }
            }
        }).start();
    }

    private void getPrinterMacAddress(final String printerName) throws Exception {
        new Thread(new Runnable() {
            @Override
            public void run() {
                try {
                    String macAddress = searchMacAddressForPrintername(printerName);
                    if (printerName != null) {
                        Log.d(LOG_TAG, "Successfully found connected printer with macAddress " + macAddress);
                        callbackContext.success(macAddress);
                    } else {
                        callbackContext.error("No printer found. If the problem persists, restart the printer.");
                    }
                } catch (Exception e) {
                    callbackContext.error(e.getMessage());
                }
            }
        }).start();
    }


    private String searchPrinterNameForMacAddress(String macAddress) throws Exception {
        Log.d(LOG_TAG, "Connecting with printer " + macAddress + " over bluetooth...");

        BluetoothAdapter bluetoothAdapter = BluetoothAdapter.getDefaultAdapter();
        Set<BluetoothDevice> pairedDevices = bluetoothAdapter.getBondedDevices();

        if (pairedDevices.size() > 0) {
            // There are paired devices. Get the name and address of each paired device.
            for (BluetoothDevice device : pairedDevices) {
                Log.d(LOG_TAG, "Paired device found: " + device.getName());
                if (device.getAddress().equalsIgnoreCase(macAddress)) {
                    return device.getName();
                }
            }
        }

        return null;
    }

    private String searchMacAddressForPrintername(String printerName) throws Exception {
        Log.d(LOG_TAG, "Search for printer " + printerName + " over bluetooth...");

        BluetoothAdapter bluetoothAdapter = BluetoothAdapter.getDefaultAdapter();
        Set<BluetoothDevice> pairedDevices = bluetoothAdapter.getBondedDevices();

        if (pairedDevices.size() > 0) {
            // There are paired devices. Get the name and address of each paired device.
            for (BluetoothDevice device : pairedDevices) {
                Log.d(LOG_TAG, "Paired device found: " + device.getName());
                if (device.getName().equalsIgnoreCase(printerName)) {
                    return device.getAddress();
                }
            }
        }

        return null;
    }

    private void getListConnectedBluetoothDevices() throws Exception {
        new Thread(new Runnable() {
            @Override
            public void run() {
                try {
                    String devices = searchConnectedBluetoothDevices();
                    if (devices != null) {
                        Log.d(LOG_TAG, "Successfully found connected devices " + devices);
                        callbackContext.success(devices);
                    } else {
                        callbackContext.error("No paired bluetooth devices found.");
                    }
                } catch (Exception e) {
                    callbackContext.error(e.getMessage());
                }
            }
        }).start();
    }

    private String searchConnectedBluetoothDevices() throws Exception {
        BluetoothAdapter bluetoothAdapter = BluetoothAdapter.getDefaultAdapter();
        Set<BluetoothDevice> pairedDevices = bluetoothAdapter.getBondedDevices();
        JSONArray deviceArray = new JSONArray();

        if (pairedDevices.size() > 0) {
            // Get the name and MAC-address of each paired device.
            for (BluetoothDevice device : pairedDevices) {
                Log.d(LOG_TAG, "Paired device found: " + device.getName());
                JSONObject d = new JSONObject();
                d.put("name", device.getName());
                d.put("macaddress", device.getAddress());
                deviceArray.put(d);
            }
            return deviceArray.toString();
        }

        return null;
    }

    private void sendFile(String MACAddress, String pdfPath) throws Exception {
        BluetoothAdapter bluetoothAdapter = BluetoothAdapter.getDefaultAdapter();
        if (bluetoothAdapter.isEnabled()) {
            Log.d(LOG_TAG, "Creating a bluetooth-connection for mac-address " + MACAddress);

            thePrinterConn = new BluetoothConnection(MACAddress);
            Log.d(LOG_TAG, "Opening connection...");
            thePrinterConn.open();
            ZebraPrinter printer = ZebraPrinterFactory.getInstance(thePrinterConn);
            printer.sendFileContents(pdfPath);
            Log.d(LOG_TAG, "File successfully sent...");
            callbackContext.success("File successfully sent...");

        } else {
            Log.d(LOG_TAG, "Bluetooth is disabled...");
            callbackContext.error("Bluetooth is not turned on.");
        }
        thePrinterConn.close();
    }

    @Override
    public void foundPrinter(DiscoveredPrinter discoveredPrinter) {
        Log.d(LOG_TAG, "Printer found: " + discoveredPrinter.address);
        if (!printerFound) {
            printerFound = true;
            callbackContext.success(discoveredPrinter.address);
        }
    }


    @Override
    public void discoveryFinished() {
        Log.d(LOG_TAG, "Finished searching for printers...");
        if (!printerFound) {
            callbackContext.error("No printer found. If the problem persists, restart the printer.");
        }
    }

    @Override
    public void discoveryError(String s) {
        Log.e(LOG_TAG, "An error occurred while searching for printers. Message: " + s);
        callbackContext.error(s);
    }

    // Not implemented - Start

    /*private void sendImage(final JSONArray labels, final String MACAddress) throws IOException {
        new Thread(new Runnable() {
            @Override
            public void run() {
                printLabels(labels, MACAddress);
            }
        }).start();
    }

    private void printLabels(JSONArray labels, String MACAddress) {
        try {
            boolean isConnected = openBluetoothConnection(MACAddress);
            if (isConnected) {
                initializePrinter();
                boolean isPrinterReady = getPrinterStatus(0);
                if (isPrinterReady) {

                    printLabel(labels);
                    // Sufficient waiting for the label to print before we start a new printer operation.
                    //Thread.sleep(15000);
                    //SGD.SET("device.languages", "line_print", thePrinterConn);
                    thePrinterConn.close();
                    callbackContext.success();
                } else {
                    Log.e(LOG_TAG, "Printer not ready");
                    callbackContext.error("The printer is not ready yet.");
                }

            } else {
                Log.e(LOG_TAG, "Printer not connected");
                callbackContext.error("The printer is not connected.");
            }

        } catch (ConnectionException e) {
            Log.e(LOG_TAG, "Connection exception: " + e.getMessage());

            //De connectie tussen de printer & het toestel is verloren gegaan.
            if (e.getMessage().toLowerCase().contains("broken pipe")) {
                callbackContext.error("The connection between the device and the printer was interrupted. Please try again.");

                //Geen printer gevonden via bluetooth, -1 teruggeven zodat er gezocht wordt naar nieuwe printers.
            } else if (e.getMessage().toLowerCase().contains("socket might closed")) {
                int SEARCH_NEW_PRINTERS = -1;
                callbackContext.error(SEARCH_NEW_PRINTERS);
            } else {
                callbackContext.error("There was an unknown printer error. Please restart the printer and try again.");
            }

        } catch (ZebraPrinterLanguageUnknownException e) {
            Log.e(LOG_TAG, "ZebraPrinterLanguageUnknown exception: " + e.getMessage());
            callbackContext.error("There was an unknown printer error. Please restart the printer and try again.");
        } catch (Exception e) {
            Log.e(LOG_TAG, "Exception: " + e.getMessage());
            callbackContext.error(e.getMessage());
        }
    }

    private void initializePrinter() throws ConnectionException, ZebraPrinterLanguageUnknownException {
        Log.d(LOG_TAG, "Initializing printer...");
        printer = ZebraPrinterFactory.getInstance(thePrinterConn);
        String printerLanguage = SGD.GET("device.languages", thePrinterConn);

        if (!printerLanguage.contains("zpl")) {
            // print diff
            SGD.SET("device.languages", "hybrid_xml_zpl", thePrinterConn);
            Log.d(LOG_TAG, "printer language set...");
        }
    }

    private boolean openBluetoothConnection(String MACAddress) throws ConnectionException {
        BluetoothAdapter bluetoothAdapter = BluetoothAdapter.getDefaultAdapter();

        if (bluetoothAdapter.isEnabled()) {
            Log.d(LOG_TAG, "Creating a bluetooth-connection for mac-address " + MACAddress);

            thePrinterConn = new BluetoothConnection(MACAddress);

            Log.d(LOG_TAG, "Opening connection...");
            thePrinterConn.open();
            Log.d(LOG_TAG, "connection successfully opened...");

            return true;
        } else {
            Log.d(LOG_TAG, "Bluetooth is disabled...");
            callbackContext.error("Bluetooth is not turned on.");
        }

        return false;
    }

    private void printLabel(JSONArray labels) throws Exception {
        ZebraPrinterLinkOs zebraPrinterLinkOs = ZebraPrinterFactory.createLinkOsPrinter(printer);

        for (int i = labels.length() - 1; i >= 0; i--) {
            String base64Image = labels.get(i).toString();
            byte[] decodedString = Base64.decode(base64Image, Base64.DEFAULT);

            Bitmap decodedByte = BitmapFactory.decodeByteArray(decodedString, 0, decodedString.length);
            ZebraImageAndroid zebraimage = new ZebraImageAndroid(decodedByte);

            int labelHeight = Integer.valueOf(zebraimage.getHeight());
            int labelSleep = (Integer.valueOf(labelHeight / 400) * 1000) * speed;

            Log.d(LOG_TAG, "labelHeight: " + Integer.toString(labelHeight));
            Log.d(LOG_TAG, "labelSleep: " + Integer.toString(labelSleep));


            // Set the length of the label first to prevent too small or too large a print
            if (zebraPrinterLinkOs != null && i == labels.length() - 1) {
                setLabelLength(zebraimage);
            }

            if (zebraPrinterLinkOs != null) {
                Log.d(LOG_TAG, "calling printer.printImage");
                //printer.printImage(zebraimage, 20, 20, zebraimage.getWidth(), zebraimage.getHeight(), false);
                printer.printImage(zebraimage, 0, 0, 0, 0, false);
            } else {
                Log.d(LOG_TAG, "Storing label on printer...");
                printer.storeImage("wgkimage.pcx", zebraimage, -1, -1);
                printImageTheOldWay(zebraimage);
                SGD.SET("device.languages", "line_print", thePrinterConn);
            }

            Thread.sleep(labelSleep);
            if (i > 0) {
                Thread.sleep(1000 * time);
            }
        }

        if (labels.length() == 0) {
            Log.e(LOG_TAG, "No labels for printing ...");
        }

    }

    private void printImageTheOldWay(ZebraImageAndroid zebraimage) throws Exception {

        Log.d(LOG_TAG, "Printing image...");

        String cpcl = "! 0 200 200 ";
        cpcl += zebraimage.getHeight();
        cpcl += " 1\r\n";
        // print diff
        cpcl += "PW 750\r\nTONE 0\r\nSPEED 6\r\nSETFF 203 5\r\nON - FEED FEED\r\nAUTO - PACE\r\nJOURNAL\r\n";
        //cpcl += "TONE 0\r\nJOURNAL\r\n";
        cpcl += "PCX 150 0 !<wgkimage.pcx\r\n";
        cpcl += "FORM\r\n";
        cpcl += "PRINT\r\n";
        thePrinterConn.write(cpcl.getBytes());

    }

    private boolean getPrinterStatus(int retryAttempt) throws Exception {
        try {
            printerStatus = printer.getCurrentStatus();

            if (printerStatus.isReadyToPrint) {
                Log.d(LOG_TAG, "Printer is ready to print...");
                return true;
            } else {
                if (printerStatus.isPaused) {
                    throw new Exception("Printer is paused. Please activate it first.");
                } else if (printerStatus.isHeadOpen) {
                    throw new Exception("Printer is open. Please close it first.");
                } else if (printerStatus.isPaperOut) {
                    throw new Exception("Please complete the labels first.");
                } else {
                    throw new Exception("Could not get the printer status. Please try again. " +
                            "If this problem persists, restart the printer.");
                }
            }
        } catch (ConnectionException e) {
            if (retryAttempt < MAX_PRINT_RETRIES) {
                Thread.sleep(5000);
                return getPrinterStatus(++retryAttempt);
            } else {
                throw new Exception("Could not get the printer status. Please try again. " +
                        "If this problem persists, restart the printer.");
            }
        }

    }

    private void setLabelLength(ZebraImageAndroid zebraimage) throws Exception {
        ZebraPrinterLinkOs zebraPrinterLinkOs = ZebraPrinterFactory.createLinkOsPrinter(printer);

        if (zebraPrinterLinkOs != null) {
            String currentLabelLength = zebraPrinterLinkOs.getSettingValue("zpl.label_length");
            Log.d(LOG_TAG, "mitja " + currentLabelLength);
            if (!currentLabelLength.equals(String.valueOf(zebraimage.getHeight()))) {
                // printer_diff
                Log.d(LOG_TAG, "mitja me " + zebraimage.getHeight());
                zebraPrinterLinkOs.setSetting("zpl.label_length", zebraimage.getHeight() + "");
            }
        }
    }

    private void discoverPrinters() {
        printerFound = false;

        new Thread(new Runnable() {
            public void run() {
                Looper.prepare();
                try {

                    BluetoothAdapter bluetoothAdapter = BluetoothAdapter.getDefaultAdapter();
                    if (bluetoothAdapter.isEnabled()) {
                        Log.d(LOG_TAG, "Searching for printers...");
                        BluetoothDiscoverer.findPrinters(cordova.getActivity().getApplicationContext(), ZebraPrintPdf.this);
                    } else {
                        Log.d(LOG_TAG, "Bluetooth is disabled...");
                        callbackContext.error("Bluetooth is not turned on.");
                    }

                } catch (ConnectionException e) {
                    Log.e(LOG_TAG, "Connection exception: " + e.getMessage());
                    callbackContext.error(e.getMessage());
                } finally {
                    Looper.myLooper().quit();
                }
            }
        }).start();
    }*/

    // Not implemented - End

}

