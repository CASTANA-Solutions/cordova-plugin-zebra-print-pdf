interface DiscoverOptions {
    bluetooth?: boolean;
    network?: boolean;
    usb?: boolean;
    timeout?: number;
}

interface DiscoveredPrinter {
    address: string;
    name: string;
    type: 'bluetooth' | 'network' | 'usb';
    serialNumber?: string;
    model?: string;
    isConnected: boolean;
}

interface ConnectOptions {
    address: string;
    type?: 'bluetooth' | 'tcp' | 'usb';
    port?: number;
}

interface PrintPdfOptions {
    filePath: string;
    address?: string;
    type?: 'bluetooth' | 'tcp' | 'usb';
    port?: number;
}

interface PrintZplOptions {
    zpl: string;
    address?: string;
    type?: 'bluetooth' | 'tcp' | 'usb';
    port?: number;
}

interface PrintCpclOptions {
    cpcl: string;
    address?: string;
    type?: 'bluetooth' | 'tcp' | 'usb';
    port?: number;
}

interface PrintRawOptions {
    data: string;
    address?: string;
    type?: 'bluetooth' | 'tcp' | 'usb';
    port?: number;
}

interface PrinterStatus {
    isReadyToPrint: boolean;
    isPaused: boolean;
    isHeadOpen: boolean;
    isPaperOut: boolean;
    isRibbonOut: boolean;
    labelsRemainingInBatch: number;
}

interface StatusOptions {
    address?: string;
    type?: 'bluetooth' | 'tcp' | 'usb';
}

interface ZebraPrint {
    discover(options: DiscoverOptions,
             success: (printers: DiscoveredPrinter[]) => void,
             error: (message: string) => void): void;

    connect(options: ConnectOptions,
            success: () => void,
            error: (message: string) => void): void;

    disconnect(success: () => void,
               error: (message: string) => void): void;

    isConnected(success: (result: { connected: boolean }) => void,
                error: (message: string) => void): void;

    printPdf(options: PrintPdfOptions,
             success: () => void,
             error: (message: string) => void): void;

    printZpl(options: PrintZplOptions,
             success: () => void,
             error: (message: string) => void): void;

    printCpcl(options: PrintCpclOptions,
              success: () => void,
              error: (message: string) => void): void;

    printRaw(options: PrintRawOptions,
             success: () => void,
             error: (message: string) => void): void;

    getStatus(options: StatusOptions,
              success: (status: PrinterStatus) => void,
              error: (message: string) => void): void;

    getSetting(variable: string,
               success: (value: string) => void,
               error: (message: string) => void): void;

    setSetting(variable: string, value: string,
               success: () => void,
               error: (message: string) => void): void;
}

declare var ZebraPrint: ZebraPrint;
