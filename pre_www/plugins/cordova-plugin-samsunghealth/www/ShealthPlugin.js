cordova.define("cordova-plugin-samsunghealth.ShealthPlugin", function(require, exports, module) {
var exec = require('cordova/exec');

var ShealthPlugin = {
  getData:function(startTime, endTime, successCallback, failureCallback) {
	  console.log('getData');
	  console.log(startTime, endTime, successCallback, failureCallback);
    exec(successCallback,
      failureCallback,
      "ShealthPlugin",
      "getData",
      [{
        "startTime" : startTime,
        "endTime" : endTime
      }]);
    },
    connect:function(successCallback, failureCallback) {
      exec(successCallback,
        failureCallback,
        "ShealthPlugin",
        "connect",
        []);
    }
};

module.exports = ShealthPlugin;

window.onload = function() {
  window.samsunghealth = window.plugins.samsunghealth;
};

});
