package at.castana.cordova.plugins.zebraprint;

import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import java.util.Set;

import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CallbackContext;
import org.apache.cordova.PluginResult;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import android.Manifest;
import android.content.pm.PackageManager;
import android.os.Build;
import java.util.ArrayList;
import java.util.List;

public class ZebraPrintPlugin extends CordovaPlugin {

    private static final int REQUEST_CODE_PERMISSIONS = 100;
    
    private PrinterDiscoveryManager discoveryManager;
    private PrinterConnectionManager connectionManager;
    private PrintJobManager printJobManager;
    
    private CallbackContext pendingCallbackContext;
    private String pendingAction;
    private JSONArray pendingArgs;

    @Override
    protected void pluginInitialize() {
        connectionManager = PrinterConnectionManager.getInstance();
        discoveryManager = new PrinterDiscoveryManager(cordova.getActivity());
        printJobManager = new PrintJobManager();
    }

    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
        // Permissions check for actions requiring Bluetooth
        if (action.equals("discover") || action.equals("connect") || 
            action.equals("printPdf") || action.equals("printZpl") || 
            action.equals("printCpcl") || action.equals("printRaw") ||
            action.equals("getStatus")) {
            if (!hasRequiredPermissions()) {
                pendingAction = action;
                pendingArgs = args;
                pendingCallbackContext = callbackContext;
                requestPermissions();
                return true;
            }
        }

        cordova.getThreadPool().execute(() -> {
            try {
                handleAction(action, args, callbackContext);
            } catch (Exception e) {
                callbackContext.error(e.getMessage() != null ? e.getMessage() : "Unknown error in plugin");
            }
        });

        return true;
    }

    private void handleAction(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
        switch (action) {
            case "discover":
                // discoveryManager.discover(args.optJSONObject(0), callbackContext);
                getListConnectedBluetoothDevices(callbackContext);
                break;
            case "connect":
                connectionManager.connect(args.optJSONObject(0), callbackContext, cordova.getActivity());
                break;
            case "disconnect":
                connectionManager.disconnect(callbackContext);
                break;
            case "isConnected":
                connectionManager.isConnected(callbackContext);
                break;
            case "printPdf":
                printJobManager.printPdf(args.optJSONObject(0), connectionManager, callbackContext, cordova.getActivity().getApplicationContext());
                break;
            case "printZpl":
                printJobManager.printZpl(args.optJSONObject(0), connectionManager, callbackContext, cordova.getActivity().getApplicationContext());
                break;
            case "printCpcl":
                printJobManager.printCpcl(args.optJSONObject(0), connectionManager, callbackContext, cordova.getActivity().getApplicationContext());
                break;
            case "printRaw":
                printJobManager.printRaw(args.optJSONObject(0), connectionManager, callbackContext, cordova.getActivity().getApplicationContext());
                break;
            case "getStatus":
                printJobManager.getStatus(args.optJSONObject(0), connectionManager, callbackContext, cordova.getActivity().getApplicationContext());
                break;
            case "getSetting":
                printJobManager.getSetting(args.getString(0), connectionManager, callbackContext, cordova.getActivity().getApplicationContext());
                break;
            case "setSetting":
                printJobManager.setSetting(args.getString(0), args.getString(1), connectionManager, callbackContext, cordova.getActivity().getApplicationContext());
                break;

            default:
                callbackContext.error("Action not recognized: " + action);
                break;
        }
    }

    private boolean hasRequiredPermissions() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            return cordova.hasPermission(Manifest.permission.BLUETOOTH_SCAN) &&
                   cordova.hasPermission(Manifest.permission.BLUETOOTH_CONNECT) &&
                   cordova.hasPermission(Manifest.permission.ACCESS_FINE_LOCATION);
        } else {
            return cordova.hasPermission(Manifest.permission.BLUETOOTH) &&
                   cordova.hasPermission(Manifest.permission.BLUETOOTH_ADMIN) &&
                   cordova.hasPermission(Manifest.permission.ACCESS_FINE_LOCATION);
        }
    }

    private void requestPermissions() {
        List<String> permissions = new ArrayList<>();
        permissions.add(Manifest.permission.ACCESS_FINE_LOCATION);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            permissions.add(Manifest.permission.BLUETOOTH_SCAN);
            permissions.add(Manifest.permission.BLUETOOTH_CONNECT);
        } else {
            permissions.add(Manifest.permission.BLUETOOTH);
            permissions.add(Manifest.permission.BLUETOOTH_ADMIN);
        }
        cordova.requestPermissions(this, REQUEST_CODE_PERMISSIONS, permissions.toArray(new String[0]));
    }

    @Override
    public void onRequestPermissionResult(int requestCode, String[] permissions, int[] grantResults) throws JSONException {
        if (requestCode == REQUEST_CODE_PERMISSIONS) {
            for (int r : grantResults) {
                if (r == PackageManager.PERMISSION_DENIED) {
                    if (pendingCallbackContext != null) {
                        pendingCallbackContext.error("Required permissions denied");
                        pendingCallbackContext = null;
                    }
                    return;
                }
            }
            
            // If all granted, proceed with pending action
            if (pendingAction != null && pendingCallbackContext != null) {
                final String action = pendingAction;
                final JSONArray args = pendingArgs;
                final CallbackContext callbackContext = pendingCallbackContext;
                
                pendingAction = null;
                pendingArgs = null;
                pendingCallbackContext = null;
                
                cordova.getThreadPool().execute(() -> {
                    try {
                        handleAction(action, args, callbackContext);
                    } catch (Exception e) {
                        callbackContext.error(e.getMessage());
                    }
                });
            }
        }
    }

    @Override
    public void onDestroy() {
        connectionManager.disconnect(null);
        super.onDestroy();
    }


    
    private void getListConnectedBluetoothDevices(CallbackContext callbackContext) throws Exception {
        new Thread(new Runnable() {
            @Override
            public void run() {
                try {
                    String devices = searchConnectedBluetoothDevices();
                    if (devices != null) {
                        // Log.d(LOG_TAG, "Successfully found connected devices " + devices);
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
                // Log.d(LOG_TAG, "Paired device found: " + device.getName());
                JSONObject d = new JSONObject();
                d.put("name", device.getName());
                d.put("macaddress", device.getAddress());
                deviceArray.put(d);
            }
            return deviceArray.toString();
        }

        return null;
    }
}
