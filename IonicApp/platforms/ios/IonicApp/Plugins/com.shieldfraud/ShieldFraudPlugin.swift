import ShieldFraud

@objc(ShieldFraudPlugin) class ShieldFraudPlugin : CDVPlugin {
    
    static var isShieldInitialized: Bool = false
    private var callbackId: String = ""
    
    @objc(initShieldFraud:) func initShieldFraud(command: CDVInvokedUrlCommand) {
        self.callbackId = command.callbackId
        print("methodName===\(command.methodName)")
        print("arguments===\(command.arguments)")
        
        let arguments = command.arguments[0]
        if ShieldFraudPlugin.isShieldInitialized {
            return
        }
        guard let args = arguments as? [String: Any],
              let siteID = args["siteID"] as? String,
              let key = args["key"] as? String else {
            return
        }
        let config = Configuration(withSiteId: siteID, secretKey: key)
        if let enableMocking = args["enableMocking"] as? Bool, enableMocking {
            config.enableMocking = true
        }
        if let partnerId = args["partnerId"] as? String{
            config.partnerId = partnerId
        }
        if let environment = args["environment"] as? String {
            config.environment = environment == "dev" ? Environment.dev : Environment.prod
        }
        if let logLevel = args["logLevel"] as? String {
            if logLevel == "debug" || logLevel == "verbose" {
                config.logLevel = LogLevel.debug
            } else if logLevel == "info" {
                config.logLevel = LogLevel.info
            } else {
                config.logLevel = LogLevel.none
            }
        }
        config.deviceShieldCallback = self
        config.defaultBlockedDialog = BlockedDialog(title: "Akash", body: "Hi, How are you?")
        Shield.setUp(with: config)
        ShieldFraudPlugin.isShieldInitialized = true
    }
    
    @objc(getSessionID:) func getSessionID(command: CDVInvokedUrlCommand) {
        self.commandDelegate.run {
            var pluginResult = CDVPluginResult()
            if ShieldFraudPlugin.isShieldInitialized {
                let sessionId =  Shield.shared().sessionId
                pluginResult = CDVPluginResult(status: .ok, messageAs: sessionId)
            } else {
                pluginResult = CDVPluginResult(status: .error, messageAs: "Intialized sdk before calling getSessionId")
            }
            self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
        }
    }
    
    @objc(getDeviceResult:) func getDeviceResult(command: CDVInvokedUrlCommand) {
        self.commandDelegate.run {
            Shield.shared().setDeviceResultStateListener {  // check whether device result assessment is complete
                var pluginResult = CDVPluginResult()
                if let deviceResult = Shield.shared().getLatestDeviceResult() {
                    guard let jsonData = try? JSONSerialization.data(withJSONObject: deviceResult, options: []) else { return }
                    let dataString = String(bytes: jsonData, encoding: String.Encoding.utf8) ?? ""
                    pluginResult = CDVPluginResult(status: .ok, messageAs: dataString)
                }
                if let error = Shield.shared().getErrorResponse() {
                    pluginResult = CDVPluginResult(status: .error, messageAs: error.localizedDescription)
                }
                self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
            }
        }
    }
    
    @objc(sendAttributes:) func sendAttributes(command: CDVInvokedUrlCommand) {
        let argument = command.arguments[0]
        guard let args = argument as? [String: Any],
              let screenName = args["screenName"] as? String,
              let data = args["attributes"] as? Dictionary<String, String>
        else {
            return
        }
        self.commandDelegate.run {
            Shield.shared().sendAttributes(withScreenName: screenName, data: data) { (status, error) in
                var pluginResult = CDVPluginResult()
                if error != nil {
                    pluginResult = CDVPluginResult(status: .ok, messageAs: false)
                } else {
                    pluginResult = CDVPluginResult(status: .error, messageAs: status)
                }
                self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
            }
        }
    }
    
    @objc(sendDeviceSignature:) func sendDeviceSignature(command: CDVInvokedUrlCommand) {
        let argument = command.arguments[0]
        guard let args = argument as? [String: Any],
              let screenName = args["screenName"] as? String
        else {
            return
        }
        self.commandDelegate.run {
            Shield.shared().sendDeviceSignature(withScreenName: screenName) {
                let pluginResult = CDVPluginResult(status: .ok, messageAs: true)
                self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
            }
        }
    }
    
    @objc(isShieldInitialized:) func isShieldInitialized(command: CDVInvokedUrlCommand) {
        Shield.shared().setDeviceResultStateListener {
            let pluginResult = CDVPluginResult(status: .ok, messageAs: true)
            DispatchQueue.main.async {
                self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
            }
        }
    }
}

extension ShieldFraudPlugin: DeviceShieldCallback {
    
    public func didSuccess(result: [String : Any]) {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: result, options: []) else { return }
        let dataString = String(bytes: jsonData, encoding: String.Encoding.utf8) ?? ""
        let pluginResult = CDVPluginResult(status: .ok, messageAs: dataString)
        self.commandDelegate.send(pluginResult, callbackId: self.callbackId)
    }
    
    public func didError(error: NSError) {
        var shieldError = [String : Any]()
        shieldError["message"] = error.localizedDescription
        shieldError["code"] = error.code
        let pluginResult = CDVPluginResult(status: .error, messageAs: error.localizedDescription)
        self.commandDelegate.send(pluginResult, callbackId: self.callbackId)
    }
}