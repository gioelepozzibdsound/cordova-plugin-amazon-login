#import <Cordova/CDVPlugin.h>

@interface AmazonLoginPlugin : CDVPlugin 

+ (id)sharedInstance;
- (NSArray *)computeScopes:(NSNumber *)flag;
- (void)failedHandler:(NSString *)callbackId;
- (void)authorizeDevice:(CDVInvokedUrlCommand *)command;
- (void)authorize:(CDVInvokedUrlCommand *)command;
- (void)fetchUserProfile:(CDVInvokedUrlCommand *)command;
- (void)getToken:(CDVInvokedUrlCommand *)command;
- (void)signOut:(CDVInvokedUrlCommand *)command;
- (void)appExists:(CDVInvokedUrlCommand *)command;

@end