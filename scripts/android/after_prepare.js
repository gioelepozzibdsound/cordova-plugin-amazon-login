#!/usr/bin/env node
'use strict';
var fs = require('fs');

var target = "debug";
if (process.env.TARGET) {
  target = process.env.TARGET;
}

var configobj = JSON.parse(fs.readFileSync('config/project.json', 'utf8'));

var filename = "platforms/android/assets/api_key.txt";
fs.writeFileSync(filename, configobj[target].AMAZON_API_KEY, 'utf8');