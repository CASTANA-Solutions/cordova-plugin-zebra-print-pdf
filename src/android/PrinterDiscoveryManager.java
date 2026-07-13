package at.castana.cordova.plugins.zebraprint;

import android.content.Context;
import org.apache.cordova.CallbackContext;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import com.zebra.sdk.printer.discovery.BluetoothDiscoverer;
import com.zebra.sdk.printer.discovery.DiscoveredPrinter;
import com.zebra.sdk.printer.discovery.DiscoveryHandler;
import com.zebra.sdk.printer.discovery.NetworkDiscoverer;
import com.zebra.sdk.printer.discovery.UsbDiscoverer;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.atomic.AtomicInteger;

public class PrinterDiscoveryManager {

    private Context context;

    public PrinterDiscoveryManager(Context context) {
        this.context = context;
    }

    public void discover(JSONObject options, final CallbackContext callbackContext) {
        boolean useBluetooth = options == null || options.optBoolean("bluetooth", true);
        boolean useNetwork = options == null || options.optBoolean("network", true);
        boolean useUsb = options != null && options.optBoolean("usb", false);
        
        final List<JSONObject> foundPrinters = new ArrayList<>();
        
        int tasksCount = (useBluetooth ? 1 : 0) + (useNetwork ? 1 : 0) + (useUsb ? 1 : 0);
        
        if (tasksCount == 0) {
            callbackContext.success(new JSONArray());
            return;
        }

        final AtomicInteger pendingTasks = new AtomicInteger(tasksCount);
        
        DiscoveryHandler handler = new DiscoveryHandler() {
            @Override
            public void foundPrinter(DiscoveredPrinter printer) {
                try {
                    JSONObject p = new JSONObject();
                    p.put("address", printer.address);
                    
                    String name = printer.getDiscoveryDataMap().get("FRIENDLY_NAME");
                    if (name == null) name = printer.getDiscoveryDataMap().get("PRODUCT_NAME");
                    if (name == null) name = printer.address;
                    p.put("name", name);
                    
                    if (printer instanceof com.zebra.sdk.printer.discovery.DiscoveredPrinterBluetooth) {
                        p.put("type", "bluetooth");
                    } else if (printer instanceof com.zebra.sdk.printer.discovery.DiscoveredPrinterNetwork) {
                        p.put("type", "network");
                    } else if (printer instanceof com.zebra.sdk.printer.discovery.DiscoveredPrinterUsb) {
                        p.put("type", "usb");
                    } else {
                        p.put("type", "unknown");
                    }
                    
                    p.put("serialNumber", printer.getDiscoveryDataMap().get("SYSTEM_NAME"));
                    p.put("model", printer.getDiscoveryDataMap().get("HARDWARE_COMPATIBILITY"));
                    p.put("isConnected", false);
                    
                    synchronized (foundPrinters) {
                        foundPrinters.add(p);
                    }
                } catch (JSONException e) {}
            }

            @Override
            public void discoveryFinished() {
                if (pendingTasks.decrementAndGet() == 0) {
                    callbackContext.success(new JSONArray(foundPrinters));
                }
            }

            @Override
            public void discoveryError(String message) {
                if (pendingTasks.decrementAndGet() == 0) {
                    callbackContext.success(new JSONArray(foundPrinters));
                }
            }
        };

        try {
            if (useBluetooth) {
                // Add paired devices first
                try {
                    android.bluetooth.BluetoothAdapter adapter = android.bluetooth.BluetoothAdapter.getDefaultAdapter();
                    if (adapter != null && adapter.isEnabled()) {
                        java.util.Set<android.bluetooth.BluetoothDevice> pairedDevices = adapter.getBondedDevices();
                        if (pairedDevices != null) {
                            for (android.bluetooth.BluetoothDevice device : pairedDevices) {
                                JSONObject p = new JSONObject();
                                p.put("address", device.getAddress());
                                p.put("name", device.getName() != null ? device.getName() : device.getAddress());
                                p.put("type", "bluetooth");
                                p.put("serialNumber", "");
                                p.put("model", "Paired Device");
                                p.put("isConnected", false);
                                synchronized (foundPrinters) {
                                    foundPrinters.add(p);
                                }
                            }
                        }
                    }
                } catch (Exception e) {
                    // Ignore paired devices errors
                }
                
                BluetoothDiscoverer.findPrinters(context, handler);
            }
            if (useNetwork) {
                NetworkDiscoverer.findPrinters(handler);
            }
            if (useUsb) {
                UsbDiscoverer.findPrinters(context, handler);
            }
        } catch (Exception e) {
            callbackContext.error("Discovery exception: " + e.getMessage());
        }
    }
}
