var exec = require('cordova/exec');

var PLUGIN_NAME = 'AmazonLoginPlugin';

var AmazonLoginPlugin = {
  authorizeDevice: function (options, successCallback, errorCallback) {
    exec(successCallback, errorCallback, PLUGIN_NAME, 'authorizeDevice', [options]);
  },
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
  },
  appExists: function (options, successCallback, errorCallback) {
    exec(successCallback, errorCallback, PLUGIN_NAME, 'appExists', [options]);
  }
};

module.exports = AmazonLoginPlugin;