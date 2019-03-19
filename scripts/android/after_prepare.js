#!/usr/bin/env node
'use strict';
var fs = require('fs');
var dotenv = require('dotenv');
var apikeyPath = 'build.json';
var filename = "platforms/android/assets/api_key.txt";

// If no target enviroment then load it from dotenv
if (process.env.NODE_ENV == 'undefined' || !process.env.NODE_ENV) {
  var result = dotenv.config();
  if (result.error) {
    throw result.error
  }
  console.log('Dotenv has configured your session environment: ' + JSON.stringify(result.parsed));
}
var target = process.env.NODE_ENV === 'prod' ? 'release' : 'debug'; 
var platform = 'android';

// Combined the AMAZON_API_KEY into the build.json instead of another file
// Also strip off the BOM at the start of VisualStudio's build.json if it is there
var configJson = JSON.parse(fs.readFileSync(apikeyPath, 'utf8').replace(/^\uFEFF/,''));

fs.writeFileSync(filename, configJson[platform][target].AMAZON_API_KEY, 'utf8');
console.log('Writing out ' + target + ' version of ' + platform + ' AMAZON_API_KEY to ' + filename);
