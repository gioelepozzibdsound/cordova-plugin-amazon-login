#import "AmazonLoginPlugin.h"
#import "AppDelegate.h"

#import <Cordova/CDVAvailability.h>
#import <LoginWithAmazon/LoginWithAmazon.h>

@implementation AppDelegate (AmazonLogin)

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)
            url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {

    // NSLog(@"AmazonLoginPlugin Plugin handle openURL");
    return [AMZNAuthorizationManager handleOpenURL:url
                                 sourceApplication:options[UIApplicationOpenURLOptionsSourceApplicationKey]];

}

@end

@implementation AmazonLoginPlugin

- (void)authorize:(CDVInvokedUrlCommand *)command {
        // NSLog(@"AmazonLoginPlugin authorize request started");
        // Build an authorize request.
        AMZNAuthorizeRequest *request = [[AMZNAuthorizeRequest alloc] init];
        request.scopes = [NSArray arrayWithObjects:
                          [AMZNProfileScope userID],
                          [AMZNProfileScope profile],
                          [AMZNProfileScope postalCode], nil];

        // Make an Authorize call to the Login with Amazon SDK.
        [[AMZNAuthorizationManager sharedManager] authorize:request
                                                withHandler:^(AMZNAuthorizeResult *result, BOOL
                                                              userDidCancel, NSError *error) {
                                                    if (error) {
                                                        // Handle errors from the SDK or authorization server.
                                                        if(error.code == kAIApplicationNotAuthorized) {
                                                            // Show authorize user button.
                                                            // NSLog(@"AmazonLoginPlugin authorize request NotAuthorized");

                                                            NSString* payload =@"authorize request NotAuthorized";

                                                            CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:payload];

                                                            // The sendPluginResult method is thread-safe.
                                                            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];


                                                        } else {
                                                            // NSLog(@"AmazonLoginPlugin authorize request failed");
                                                            NSString* payload = error.userInfo[@"AMZNLWAErrorNonLocalizedDescription"];

                                                            CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:payload];

                                                            // The sendPluginResult method is thread-safe.
                                                            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                                                        }



                                                    } else if (userDidCancel) {
                                                        // Handle errors caused when user cancels login.
                                                        // NSLog(@"AmazonLoginPlugin authorize request canceled");
                                                       NSString* payload = @"authorize request canceled";


                                                        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:payload];

                                                        // The sendPluginResult method is thread-safe.
                                                        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];


                                                    } else {
                                                        // NSLog(@"AmazonLoginPlugin authorize success");
                                                        // Authentication was successful.

                                                        NSDictionary *dictionary = @{
                                                                                     @"accessToken": result.token,
                                                                                     @"user": result.user.profileData
                                                                                     };


                                                        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:dictionary];

                                                        // The sendPluginResult method is thread-safe.
                                                        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                                                    }
                                                }];
}

- (void)fetchUserProfile:(CDVInvokedUrlCommand *)command {
    //NSLog(@"AmazonLoginPlugin fetchUserProfile");

    [AMZNUser fetch:^(AMZNUser *user, NSError *error) {
        if (error) {
            // Error from the SDK, or no user has authorized to the app.
            NSString* payload = error.userInfo[@"AMZNLWAErrorNonLocalizedDescription"];

            CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:payload];

            // The sendPluginResult method is thread-safe.
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];

        } else if (user) {
            CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:user.profileData];

            // The sendPluginResult method is thread-safe.
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];

        }
    }];
}

- (void)getToken:(CDVInvokedUrlCommand *)command {
   // NSLog(@"AmazonLoginPlugin  getToken");
   // Build an authorize request.
          AMZNAuthorizeRequest *request = [[AMZNAuthorizeRequest alloc] init];
          request.scopes = [NSArray arrayWithObjects:
                            [AMZNProfileScope userID],
                            [AMZNProfileScope profile],
                            [AMZNProfileScope postalCode], nil];

          request.interactiveStrategy = AMZNInteractiveStrategyNever;


          // Make an Authorize call to the Login with Amazon SDK.
          [[AMZNAuthorizationManager sharedManager] authorize:request
                                                  withHandler:^(AMZNAuthorizeResult *result, BOOL
                                                                userDidCancel, NSError *error) {
                                                      if (error) {
                                                          // Handle errors from the SDK or authorization server.
                                                          if(error.code == kAIApplicationNotAuthorized) {
                                                              // Show authorize user button.
                                                              //NSLog(@"AmazonLoginPlugin authorize request NotAuthorized");

                                                              NSString* payload =@"authorize request NotAuthorized";

                                                              CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:payload];

                                                              // The sendPluginResult method is thread-safe.
                                                              [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];


                                                          } else {
                                                              //NSLog(@"AmazonLoginPlugin authorize request failed");
                                                              NSString* payload = error.userInfo[@"AMZNLWAErrorNonLocalizedDescription"];

                                                              CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:payload];

                                                              // The sendPluginResult method is thread-safe.
                                                              [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                                                          }
                                                      } else if (userDidCancel) {
                                                          // Handle errors caused when user cancels login.
                                                          // NSLog(@"AmazonLoginPlugin authorize request canceled");
                                                          NSString* payload = @"authorize request canceled";

                                                          CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:payload];

                                                          // The sendPluginResult method is thread-safe.
                                                          [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                                                      } else {
                                                          // NSLog(@"AmazonLoginPlugin authorize success");
                                                          // Authentication was successful.

                                                          NSDictionary *dictionary = @{
                                                                                       @"accessToken": result.token,
                                                                                       @"user": result.user.profileData
                                                                                       };


                                                          CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:dictionary];

                                                          // The sendPluginResult method is thread-safe.
                                                          [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                                                      }
                                                  }];
}

- (void)signOut:(CDVInvokedUrlCommand *)command {
    //NSLog(@"AmazonLoginPlugin signOut");
    [[AMZNAuthorizationManager sharedManager] signOut:^(NSError * _Nullable error) {
        if (!error) {
            // error from the SDK or Login with Amazon authorization server.
            NSString* payload = error.userInfo[@"AMZNLWAErrorNonLocalizedDescription"];

            CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:payload];

            // The sendPluginResult method is thread-safe.
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        }
    }];
}
@end