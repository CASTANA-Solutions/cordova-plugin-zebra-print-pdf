package at.castana.cordova.plugins.zebraprint;

import org.apache.cordova.CallbackContext;
import org.json.JSONObject;

import android.content.Context;
import android.hardware.usb.UsbManager;

import com.zebra.sdk.comm.BluetoothConnection;
import com.zebra.sdk.comm.Connection;
import com.zebra.sdk.comm.ConnectionException;
import com.zebra.sdk.comm.TcpConnection;
import com.zebra.sdk.printer.discovery.UsbDiscoverer;

public class PrinterConnectionManager {

    private static PrinterConnectionManager instance;
    private Connection currentConnection;

    private PrinterConnectionManager() {}

    public static synchronized PrinterConnectionManager getInstance() {
        if (instance == null) {
            instance = new PrinterConnectionManager();
        }
        return instance;
    }

    public Connection getConnection() {
        return currentConnection;
    }
    
    public synchronized Connection getOrOpenConnection(JSONObject options, Context context) throws Exception {
        if (options != null && options.has("address")) {
            // Implicit connect if options provides an address
            Connection tempConn = createConnection(options, context);
            tempConn.open();
            return tempConn;
        } else if (currentConnection != null && currentConnection.isConnected()) {
            return currentConnection;
        } else if (context != null) {
            // Auto-reconnect to last known printer
            android.content.SharedPreferences prefs = context.getSharedPreferences("ZebraPrintPrefs", Context.MODE_PRIVATE);
            String lastAddress = prefs.getString("lastAddress", null);
            String lastType = prefs.getString("lastType", "bluetooth");
            if (lastAddress != null) {
                JSONObject lastOpts = new JSONObject();
                lastOpts.put("address", lastAddress);
                lastOpts.put("type", lastType);
                Connection tempConn = createConnection(lastOpts, context);
                tempConn.open();
                return tempConn;
            }
        }
        throw new ConnectionException("No active connection and no address provided.");
    }
    
    public synchronized void closeImplicitConnection(Connection connection) {
        if (connection != null && connection != currentConnection) {
            try {
                connection.close();
            } catch (ConnectionException e) {
                // Ignore
            }
        }
    }

    public synchronized void connect(JSONObject options, CallbackContext callbackContext, Context context) {
        try {
            if (options == null || !options.has("address")) {
                callbackContext.error("MAC or IP address is required to connect");
                return;
            }

            // Close existing connection if any
            if (currentConnection != null && currentConnection.isConnected()) {
                currentConnection.close();
            }

            currentConnection = createConnection(options, context);
            currentConnection.open();

            // Save for future auto-reconnect
            if (context != null) {
                android.content.SharedPreferences prefs = context.getSharedPreferences("ZebraPrintPrefs", Context.MODE_PRIVATE);
                prefs.edit()
                     .putString("lastAddress", options.getString("address"))
                     .putString("lastType", options.optString("type", "bluetooth"))
                     .apply();
            }

            callbackContext.success("Connected to " + options.getString("address"));
        } catch (Exception e) {
            currentConnection = null;
            String msg = e.getMessage();
            callbackContext.error("Connection failed: " + (msg != null ? msg : e.getClass().getSimpleName()));
        }
    }

    private Connection createConnection(JSONObject options, Context context) throws Exception {
        String address = options.getString("address");
        String type = options.optString("type", "bluetooth").toLowerCase();

        switch (type) {
            case "tcp":
            case "network":
                int port = options.optInt("port", 9100);
                return new TcpConnection(address, port);
            case "usb":
                // USB connection in Zebra SDK requires finding the printer via UsbManager first
                // For simplicity, we assume address is the USB device name, but proper USB needs more setup
                throw new UnsupportedOperationException("USB connection not fully implemented yet");
            case "bluetooth":
            default:
                return new BluetoothConnection(address);
        }
    }

    public synchronized void disconnect(CallbackContext callbackContext) {
        if (currentConnection != null) {
            try {
                currentConnection.close();
                currentConnection = null;
                if (callbackContext != null) callbackContext.success("Disconnected");
            } catch (ConnectionException e) {
                currentConnection = null; // Still nullify to reset state
                if (callbackContext != null) {
                    String msg = e.getMessage();
                    callbackContext.error("Disconnect error: " + (msg != null ? msg : e.getClass().getSimpleName()));
                }
            }
        } else {
            if (callbackContext != null) callbackContext.success("Already disconnected");
        }
    }

    public synchronized void isConnected(CallbackContext callbackContext) {
        try {
            JSONObject result = new JSONObject();
            boolean connected = currentConnection != null && currentConnection.isConnected();
            result.put("connected", connected);
            callbackContext.success(result);
        } catch (Exception e) {
            callbackContext.error(e.getMessage());
        }
    }
}
