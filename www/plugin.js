var exec = require('cordova/exec');

var PLUGIN_NAME = 'AmazonLogin';

var AmazonLogin = {
  authorize: function (options, successCallback, errorCallback) {
    exec(successCallback, errorCallback, PLUGIN_NAME, 'authorize', [options]);
  },
  fetchUserProfile: function (successCallback, errorCallback) {
    exec(successCallback, errorCallback, PLUGIN_NAME, 'fetchUserProfile', []);
  },
  getToken: function (options, successCallback, errorCallback) {
    exec(successCallback, errorCallback, PLUGIN_NAME, 'getToken', [options]);
  },
  signOut: function (successCallback, errorCallback) {
    exec(successCallback, errorCallback, PLUGIN_NAME, 'signOut', []);
  }
};


module.exports = AmazonLogin;