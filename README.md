# Cordova Plugin for Amazon Login

This plugin allows you to authenticate and identify users with Amazon Login on Android. 

##Installation

### Android

- Download the [Amazon Mobile App SDK](https://developer.amazon.com/public/resources/development-tools/sdk)  and extract the files to a directory on your hard drive.
- You should see a `login-with-amazon.jar` file in the LoginWithAmazon parent directory.
- Copy `login-with-amazon.jar` file to `platforms/android/libs/login-with-amazon.jar` of your Cordova project.
- Create configuration file for Amazon API keys `config\project.json`
- If you do not have your API Key yet, see [Android App Signatures and API Keys](https://developer.amazon.com/public/apis/engage/login-with-amazon/docs/register_android.html#Android%20App%20Signatures%20and%20API%20Keys) and follow the instructions under "Retrieving an Android API Key".
- Set your Amazon API keys in `config\project.json`

For example, your `config\project.json` might look like this:

```
{
  "debug":
  {
    "AMAZON_API_KEY" : "hdgGHHDG......8yRM=="
  },
  "release":
  {
    "AMAZON_API_KEY" : "dh8HGuDQ......rt5H=="
  }
}
```

By default, the value of API key from `debug` section will be used.
In order to use API key from `release` section 

```
TARGET=release cordova prepare
```


