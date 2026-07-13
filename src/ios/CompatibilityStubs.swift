import Foundation

#if !canImport(Cordova)
#error("Cordova is required. Please add Cordova to the project (e.g., via Swift Package, CocoaPods, or adding the framework).")
#endif

#if canImport(Cordova)
import Cordova
#endif

#if canImport(ExternalAccessory)
import ExternalAccessory
#endif

// Attempt to import Zebra SDK. The module name can vary by distribution.
#if canImport(ZSDKDeveloperKit)
import ZSDKDeveloperKit
#elseif canImport(ZebraSDK)
import ZebraSDK
#else
#warning("Zebra SDK not found. Add the Zebra Link-OS iOS SDK to the project. Common module names: ZSDKDeveloperKit or ZebraSDK.")
#endif
