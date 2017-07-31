#import <Cordova/CDVPlugin.h>

@interface AmazonLogin : CDVPlugin {
}

- (void)authorize:(CDVInvokedUrlCommand *)command;
- (void)fetchUserProfile:(CDVInvokedUrlCommand *)command;
- (void)getToken:(CDVInvokedUrlCommand *)command;
- (void)signOut:(CDVInvokedUrlCommand *)command;

@end