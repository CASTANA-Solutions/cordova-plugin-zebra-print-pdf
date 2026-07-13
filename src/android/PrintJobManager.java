package at.castana.cordova.plugins.zebraprint;

import android.util.Base64;
import org.apache.cordova.CallbackContext;
import org.json.JSONException;
import org.json.JSONObject;

import com.zebra.sdk.comm.Connection;
import com.zebra.sdk.printer.PrinterStatus;
import com.zebra.sdk.printer.ZebraPrinter;
import com.zebra.sdk.printer.ZebraPrinterFactory;
import com.zebra.sdk.printer.SGD;

import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class PrintJobManager {

    // Native Print Queue to prevent overlapping prints
    private final ExecutorService printQueue = Executors.newSingleThreadExecutor();

    private void checkPrinterStatus(ZebraPrinter printer) throws Exception {
        PrinterStatus status = printer.getCurrentStatus();
        if (!status.isReadyToPrint) {
            if (status.isPaperOut) {
                throw new Exception("ERROR_PAPER_OUT");
            } else if (status.isHeadOpen) {
                throw new Exception("ERROR_HEAD_OPEN");
            } else if (status.isPaused) {
                throw new Exception("ERROR_PAUSED");
            } else if (status.isReceiveBufferFull) {
                throw new Exception("ERROR_BUFFER_FULL");
            } else if (status.isRibbonOut) {
                throw new Exception("ERROR_RIBBON_OUT");
            } else {
                throw new Exception("ERROR_PRINTER_NOT_READY");
            }
        }
    }

    public void printPdf(final JSONObject options, final PrinterConnectionManager connectionManager, final CallbackContext callbackContext, final android.content.Context context) {
        printQueue.execute(new Runnable() {
            @Override
            public void run() {
                Connection connection = null;
                java.io.File tempFile = null;
                try {
                    if (options == null) {
                        callbackContext.error("options is required");
                        return;
                    }
                    String filePath = null;
                    if (options.has("base64")) {
                        String base64 = options.getString("base64");
                        byte[] pdfBytes = android.util.Base64.decode(base64, android.util.Base64.DEFAULT);
                        tempFile = java.io.File.createTempFile("print_", ".pdf", context.getCacheDir());
                        java.io.FileOutputStream fos = new java.io.FileOutputStream(tempFile);
                        fos.write(pdfBytes);
                        fos.close();
                        filePath = tempFile.getAbsolutePath();
                    } else if (options.has("filePath")) {
                        filePath = options.getString("filePath");
                        if (filePath.startsWith("file://")) {
                            filePath = filePath.substring(7);
                        }
                    } else {
                        callbackContext.error("filePath or base64 is required");
                        return;
                    }

                    connection = connectionManager.getOrOpenConnection(options, context);
                    ZebraPrinter printer = ZebraPrinterFactory.getInstance(connection);
                    
                    if (printer == null) {
                        callbackContext.error("Failed to create printer instance");
                        return;
                    }

                    checkPrinterStatus(printer);

                    printer.sendFileContents(filePath);
                    callbackContext.success("PDF printed successfully");
                    
                } catch (Exception e) {
                    String msg = e.getMessage();
                    callbackContext.error("Error printing PDF: " + (msg != null ? msg : e.getClass().getSimpleName()));
                } finally {
                    if (tempFile != null && tempFile.exists()) {
                        tempFile.delete();
                    }
                    connectionManager.closeImplicitConnection(connection);
                }
            }
        });
    }

    public void printZpl(final JSONObject options, final PrinterConnectionManager connectionManager, final CallbackContext callbackContext, final android.content.Context context) {
        printQueue.execute(new Runnable() {
            @Override
            public void run() {
                Connection connection = null;
                try {
                    if (options == null || !options.has("zpl")) {
                        callbackContext.error("zpl is required");
                        return;
                    }
                    String zpl = options.getString("zpl");
                    
                    connection = connectionManager.getOrOpenConnection(options, context);
                    ZebraPrinter printer = ZebraPrinterFactory.getInstance(connection);
                    if (printer != null) checkPrinterStatus(printer);

                    connection.write(zpl.getBytes());
                    
                    callbackContext.success("ZPL printed successfully");
                } catch (Exception e) {
                    String msg = e.getMessage();
                    callbackContext.error("Error printing ZPL: " + (msg != null ? msg : e.getClass().getSimpleName()));
                } finally {
                    connectionManager.closeImplicitConnection(connection);
                }
            }
        });
    }

    public void printCpcl(final JSONObject options, final PrinterConnectionManager connectionManager, final CallbackContext callbackContext, final android.content.Context context) {
        printQueue.execute(new Runnable() {
            @Override
            public void run() {
                Connection connection = null;
                try {
                    if (options == null || !options.has("cpcl")) {
                        callbackContext.error("cpcl is required");
                        return;
                    }
                    String cpcl = options.getString("cpcl");
                    
                    connection = connectionManager.getOrOpenConnection(options, context);
                    ZebraPrinter printer = ZebraPrinterFactory.getInstance(connection);
                    if (printer != null) checkPrinterStatus(printer);

                    connection.write(cpcl.getBytes());
                    
                    callbackContext.success("CPCL printed successfully");
                } catch (Exception e) {
                    String msg = e.getMessage();
                    callbackContext.error("Error printing CPCL: " + (msg != null ? msg : e.getClass().getSimpleName()));
                } finally {
                    connectionManager.closeImplicitConnection(connection);
                }
            }
        });
    }

    public void printRaw(final JSONObject options, final PrinterConnectionManager connectionManager, final CallbackContext callbackContext, final android.content.Context context) {
        printQueue.execute(new Runnable() {
            @Override
            public void run() {
                Connection connection = null;
                try {
                    if (options == null || !options.has("data")) {
                        callbackContext.error("data (base64) is required");
                        return;
                    }
                    String base64Data = options.getString("data");
                    byte[] rawData = Base64.decode(base64Data, Base64.DEFAULT);
                    
                    connection = connectionManager.getOrOpenConnection(options, context);
                    ZebraPrinter printer = ZebraPrinterFactory.getInstance(connection);
                    if (printer != null) checkPrinterStatus(printer);

                    connection.write(rawData);
                    
                    callbackContext.success("Raw data printed successfully");
                } catch (Exception e) {
                    String msg = e.getMessage();
                    callbackContext.error("Error printing raw data: " + (msg != null ? msg : e.getClass().getSimpleName()));
                } finally {
                    connectionManager.closeImplicitConnection(connection);
                }
            }
        });
    }

    public void getStatus(final JSONObject options, final PrinterConnectionManager connectionManager, final CallbackContext callbackContext, final android.content.Context context) {
        printQueue.execute(new Runnable() {
            @Override
            public void run() {
                Connection connection = null;
                try {
                    connection = connectionManager.getOrOpenConnection(options, context);
                    ZebraPrinter printer = ZebraPrinterFactory.getInstance(connection);
                    
                    if (printer == null) {
                        callbackContext.error("Failed to create printer instance");
                        return;
                    }
                    
                    PrinterStatus printerStatus = printer.getCurrentStatus();
                    
                    JSONObject status = new JSONObject();
                    status.put("isReadyToPrint", printerStatus.isReadyToPrint);
                    status.put("isPaused", printerStatus.isPaused);
                    status.put("isHeadOpen", printerStatus.isHeadOpen);
                    status.put("isPaperOut", printerStatus.isPaperOut);
                    status.put("isRibbonOut", printerStatus.isRibbonOut);
                    status.put("labelsRemainingInBatch", printerStatus.labelsRemainingInBatch);
                    
                    callbackContext.success(status);
                } catch (Exception e) {
                    String msg = e.getMessage();
                    callbackContext.error("Error getting status: " + (msg != null ? msg : e.getClass().getSimpleName()));
                } finally {
                    connectionManager.closeImplicitConnection(connection);
                }
            }
        });
    }

    public void getSetting(final String variable, final PrinterConnectionManager connectionManager, final CallbackContext callbackContext, final android.content.Context context) {
        printQueue.execute(new Runnable() {
            @Override
            public void run() {
                Connection connection = null;
                try {
                    connection = connectionManager.getOrOpenConnection(null, context);
                    String value = SGD.GET(variable, connection);
                    callbackContext.success(value);
                } catch (Exception e) {
                    String msg = e.getMessage();
                    callbackContext.error("Error getting setting: " + (msg != null ? msg : e.getClass().getSimpleName()));
                } finally {
                    connectionManager.closeImplicitConnection(connection);
                }
            }
        });
    }

    public void setSetting(final String variable, final String value, final PrinterConnectionManager connectionManager, final CallbackContext callbackContext, final android.content.Context context) {
        printQueue.execute(new Runnable() {
            @Override
            public void run() {
                Connection connection = null;
                try {
                    connection = connectionManager.getOrOpenConnection(null, context);
                    SGD.SET(variable, value, connection);
                    callbackContext.success("Setting updated");
                } catch (Exception e) {
                    String msg = e.getMessage();
                    callbackContext.error("Error setting setting: " + (msg != null ? msg : e.getClass().getSimpleName()));
                } finally {
                    connectionManager.closeImplicitConnection(connection);
                }
            }
        });
    }
}
