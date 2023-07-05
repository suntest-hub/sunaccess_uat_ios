cordova.define("cordova-plugin-documentpicker.DocumentPicker", function(require, exports, module) {
var exec = require('cordova/exec');

exports.getFile = function (arg0, success, error) {
    exec(success, error, 'DocumentPicker', 'getFile', [arg0]);
};

});
