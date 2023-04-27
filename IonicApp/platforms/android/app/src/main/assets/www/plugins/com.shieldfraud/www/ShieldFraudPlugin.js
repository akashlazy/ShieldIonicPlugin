cordova.define("com.shieldfraud.ShieldFraudPlugin", function(require, exports, module) {
var exec = require('cordova/exec');

var PLUGIN_NAME = "ShieldFraudPlugin";

exports.initShieldFraud = function(arg0, success, error) {
    exec(success, error, PLUGIN_NAME, "initShieldFraud", [arg0]);
};

exports.getSessionID = function(arg0, success, error) {
  exec(success, error, PLUGIN_NAME, "getSessionID", [arg0]);
};

exports.getDeviceResult = function(success, error) {
  exec(success, error, PLUGIN_NAME, "getDeviceResult");
};

exports.sendAttributes = function(arg0, success, error) {
  exec(success, error, PLUGIN_NAME, "sendAttributes", [arg0]);
};

exports.sendDeviceSignature = function(arg0, success, error) {
  exec(success, error, PLUGIN_NAME, "sendDeviceSignature", [arg0]);
};

exports.isShieldInitialized = function(success, error) {
  exec(success, error, PLUGIN_NAME, "isShieldInitialized");
};

});
