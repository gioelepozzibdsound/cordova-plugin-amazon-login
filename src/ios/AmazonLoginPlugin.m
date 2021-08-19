#import "AmazonLoginPlugin.h"
#import "AppDelegate.h"

#import <Cordova/CDVAvailability.h>
#import <LoginWithAmazon/LoginWithAmazon.h>

// Types of apps to look up
typedef enum
{
    PluginAppsNone                = 0x00000,
    PluginAppsShopping            = 0x00001,
    PluginAppsAlexa               = 0x00010
} PluginApps;

// Supported Alexa Scopes
// https://developer.amazon.com/docs/smapi/ask-cli-intro.html
typedef enum
{
    PluginProfileNone             = 0x00000,
    PluginProfileAlexaPreAuth     = 0x00001,
    PluginProfileUserId           = 0x00010,
    PluginProfileProfile          = 0x00020,
    PluginProfilePostal           = 0x00040,
    PluginProfileAlexaSkillsR     = 0x00100,
    PluginProfileAlexaSkillsRW    = 0x00200,
    PluginProfileAlexaSkillsTest  = 0x00800,
    PluginProfileAlexaModelsR     = 0x01000,
    PluginProfileAlexaModelsRW    = 0x02000,
    PluginProfileDashReplenish    = 0x10000
} PluginProfiles;
// Untested scope for Amazon Dash

#define PluginNotificationName        @"AmazonLoginPluginNotification"
#define PluginCodeChallengeMethod     @"S256"

#define PluginFieldAccessToken        @"accessToken"
#define PluginFieldAuthorizationCode  @"authorizationCode"
#define PluginFieldUser               @"user"
#define PluginFieldClientId           @"clientId"
#define PluginFieldRedirectUri        @"redirectURI"

#define PluginAmazonShoppingLink      @"com.amazon.mobile.shopping://www.amazon.com/products/"
#define PluginAmazonAlexaLink         @"alexa://"

@implementation AppDelegate (AmazonLogin)

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {

    NSLog(@"AmazonLoginPlugin handle openURL");
    BOOL handled =[AMZNAuthorizationManager handleOpenURL:url
        sourceApplication:options[UIApplicationOpenURLOptionsSourceApplicationKey] ];

    NSLog(@"AmazonLoginPlugin handled was %s", handled ? "true" : "false" );
    // Handle errors caused when user cancels login or skips or backs out unexpectedly
    if (!handled) {
        [[NSNotificationCenter defaultCenter] postNotificationName:PluginNotificationName object:nil];
    }
    return handled;
}

@end

@implementation AmazonLoginPlugin

// Instance reference to our plugin
static id sharedInstance;

- (void)dealloc {
    // If you don't remove yourself as an observer, the Notification Center
    // will continue to try and send notification objects to the deallocated
    // object.
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

// Our plugin is a singelton
+ (instancetype)sharedInstance {
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] initPrivate];
    });
    return sharedInstance;
}

- (instancetype)init {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
        reason:@"AmazonLoginPlugin could not init!" userInfo:nil];
}

- (instancetype)initPrivate {
    if (self = [super init]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveTestNotification:)
                                                     name:PluginNotificationName
                                                   object:nil];
        //TODO: Do other init...
    }
    return self;
}

- (void)failedHandler:(NSString *)callbackId
{
    // Handle errors caused when user cancels login.
    NSLog(@"AmazonLoginPlugin did not complete");
    if (callbackId) {
        NSString* payload = @"handler did not complete perhaps skipped";
        CDVPluginResult* pluginResult = [CDVPluginResult
            resultWithStatus:CDVCommandStatus_ERROR messageAsString:payload];
        
        // The sendPluginResult method is thread-safe.
        [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
    } else {
        NSLog(@"callbackId was invalid could not send the failure");
    }
}


- (NSArray *)computeScopes:(NSNumber *)flag {
    long lFlag = [flag unsignedLongLongValue];
    NSLog(@"computeScopes got scope: " @"0x%lx", lFlag);
    NSMutableArray *scopes = [[NSMutableArray alloc] init];

    if ((lFlag & PluginProfileUserId) != 0) {
        [scopes addObject:[AMZNProfileScope userID]];
        NSLog(@"Profile: userId scope added");
    }
    if ((lFlag & PluginProfileProfile) != 0) {
        [scopes addObject:[AMZNProfileScope profile]];
        NSLog(@"Profile: profile scope added");
    }
    if ((lFlag & PluginProfilePostal) != 0) {
        [scopes addObject:[AMZNProfileScope postalCode]];
        NSLog(@"Profile: postalCode scope added");
    }
    if ((lFlag & PluginProfileAlexaSkillsR) != 0) {
        [scopes addObject:[AMZNScopeFactory scopeWithName:@"alexa::ask:skills:read"]];
        NSLog(@"Profile: alexa skills read scope added");
    }
    if ((lFlag & PluginProfileAlexaSkillsRW) != 0) {
        [scopes addObject:[AMZNScopeFactory scopeWithName:@"alexa::ask:skills:readwrite"]];
        NSLog(@"Profile: alexa skills readwrite scope added");
    }
    if ((lFlag & PluginProfileAlexaSkillsTest) != 0) {
        [scopes addObject:[AMZNScopeFactory scopeWithName:@"alexa::ask:skills:test"]];
        NSLog(@"Profile: alexa skills test scope added");
    }
    if ((lFlag & PluginProfileAlexaModelsR) != 0) {
        [scopes addObject:[AMZNScopeFactory scopeWithName:@"alexa::ask:models:read"]];
        NSLog(@"Profile: alexa models read scope added");
    }
    if ((lFlag & PluginProfileAlexaModelsRW) != 0) {
        [scopes addObject:[AMZNScopeFactory scopeWithName:@"alexa::ask:models:readwrite"]];
        NSLog(@"Profile: alexa models readwrite scope added");
    }
    if ((lFlag & PluginProfileDashReplenish) != 0) {
        [scopes addObject:[AMZNScopeFactory scopeWithName:@"dash:replenish"]];
        NSLog(@"Profile: dash replenish scope added");
    }
    if ((lFlag & PluginProfileAlexaPreAuth) != 0) {
        [scopes addObject:[AMZNScopeFactory scopeWithName:@"alexa:voice_service:pre_auth"]];
        NSLog(@"Profile: alexa pre_auth scope added");
    }
    return [scopes copy];
}

- (void)authorizeDevice:(CDVInvokedUrlCommand *)command {
    NSLog(@"AmazonLoginPlugin authorizeDevice is work in progress...");

    NSOperationQueue *mainQueue = [NSOperationQueue mainQueue];
    [[NSNotificationCenter defaultCenter]
     addObserverForName:PluginNotificationName
     object:nil
     queue:mainQueue
     usingBlock:^(NSNotification *notification) {
         [self failedHandler:command.callbackId];
     }];

    NSDictionary* options = [command argumentAtIndex:0];
    if ([options isKindOfClass:[NSNull class]]) {
        options = [NSDictionary dictionary];
    }
    NSNumber *scopeFlag = [options objectForKey:@"scopeFlag"];
    NSString *productId = [options objectForKey:@"productID"];
    NSString *productDsn = [options objectForKey:@"productDSN"];
    NSString *codeChallenge = [options objectForKey:@"codeChallenge"];
    NSLog(@"authorizeDevice got code challenge of: " @"%@",codeChallenge);

    NSDictionary *scopeData = @{
                                @"productID": productId,
                                @"productInstanceAttributes": @{@"deviceSerialNumber": productDsn}
                                };

    id alexaAllScope = [AMZNScopeFactory scopeWithName:@"alexa:all" data:scopeData];

    NSMutableArray *scopes = [[NSMutableArray alloc] init];
    for (id obj in [self computeScopes:scopeFlag]) {
        [scopes addObject:obj];
    }
    [scopes addObject:alexaAllScope];

    AMZNAuthorizeRequest *request = [[AMZNAuthorizeRequest alloc] init];
    request.scopes = [scopes copy];
    request.codeChallenge = codeChallenge;
    request.codeChallengeMethod = PluginCodeChallengeMethod; //@"S256";
    request.grantType = AMZNAuthorizationGrantTypeCode;

    AMZNAuthorizationManager *authManager = [AMZNAuthorizationManager sharedManager];
    [authManager authorize:request withHandler:^(AMZNAuthorizeResult *result, BOOL userDidCancel, NSError *error) {
        if (error) {
            // Notify the user that authorization failed
            NSLog(@"AmazonLoginPlugin authorizeDevice User authorization failed due to an error: " @"%@",error.localizedDescription);

            NSString* payload = @"authorizeDevice request NotAuthorized";

            CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:payload];

            // The sendPluginResult method is thread-safe.
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        } else if (userDidCancel) {
            // Notify the user that authorization failed
            NSLog(@"AmazonLoginPlugin authorizeDevice was cancelled prior to completion. To continue, you will need to try logging in again.");

            NSString* payload = @"authorizeDevice request cancelled";

            CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:payload];

            // The sendPluginResult method is thread-safe.
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        } else {
            NSLog(@"AmazonLoginPlugin authorizeDevice success");
            // Fetch the authorization code and return to controller
            NSDictionary *dictionary = @{
                                         PluginFieldAuthorizationCode: result.authorizationCode,
                                         PluginFieldClientId: result.clientId,
                                         PluginFieldRedirectUri: result.redirectUri
                                         };

            CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:dictionary];

            // The sendPluginResult method is thread-safe.
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        }
    }];
}

- (void)authorize:(CDVInvokedUrlCommand *)command {
    NSLog(@"AmazonLoginPlugin authorize request started");

    NSOperationQueue *mainQueue = [NSOperationQueue mainQueue];
    [[NSNotificationCenter defaultCenter]
     addObserverForName:PluginNotificationName
     object:nil
     queue:mainQueue
     usingBlock:^(NSNotification *notification) {
         [self failedHandler:command.callbackId];
     }];

    NSDictionary* options = [command argumentAtIndex:0];
    if ([options isKindOfClass:[NSNull class]]) {
        options = [NSDictionary dictionary];
    }
    NSNumber *scopeFlag = [options objectForKey:@"scopeFlag"];
    // Build an authorize request.
    AMZNAuthorizeRequest *request = [[AMZNAuthorizeRequest alloc] init];

    NSMutableArray *scopes = [[NSMutableArray alloc] init];
    for (id obj in [self computeScopes:scopeFlag]) {
        [scopes addObject:obj];
    }
    request.scopes = [scopes copy];

    // Make an Authorize call to the Login with Amazon SDK.
    [[AMZNAuthorizationManager sharedManager] authorize:request withHandler:^(AMZNAuthorizeResult *result, BOOL userDidCancel, NSError *error) {
        if (error) {
            // Notify the user that authorization failed
            NSLog(@"AmazonLoginPlugin authorize failed due to an error: " @"%@",error.localizedDescription);

            // Handle errors from the SDK or authorization server.
            if(error.code == kAMZNLWAApplicationNotAuthorized) {
                // Show authorize user button.
                NSLog(@"AmazonLoginPlugin authorize request NotAuthorized");

                NSString* payload = @"authorize request NotAuthorized";

                CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:payload];

                // The sendPluginResult method is thread-safe.
                [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];

            } else {
                NSLog(@"AmazonLoginPlugin authorize request failed");
                NSString* payload = error.userInfo[@"AMZNLWAErrorNonLocalizedDescription"];

                CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:payload];

                // The sendPluginResult method is thread-safe.
                [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
            }
        } else if (userDidCancel) {
            // Handle errors caused when user cancels login.
            NSLog(@"AmazonLoginPlugin authorize request cancelled");
            NSString* payload = @"authorize request cancelled";

            CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:payload];

            // The sendPluginResult method is thread-safe.
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];

        } else {
            NSLog(@"AmazonLoginPlugin authorize success");
            // Authentication was successful.

            NSDictionary *dictionary = @{
                                         PluginFieldAccessToken: result.token,
                                         PluginFieldUser: result.user.profileData
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
    NSLog(@"AmazonLoginPlugin  getToken");
    
    NSDictionary* options = [command argumentAtIndex:0];
    if ([options isKindOfClass:[NSNull class]]) {
        options = [NSDictionary dictionary];
    }
    NSNumber *scopeFlag = [options objectForKey:@"scopeFlag"];
    
    // Build an authorize request.
    AMZNAuthorizeRequest *request = [[AMZNAuthorizeRequest alloc] init];

    NSMutableArray *scopes = [[NSMutableArray alloc] init];
    for (id obj in [self computeScopes:scopeFlag]) {
        [scopes addObject:obj];
    }
    request.scopes = [scopes copy];
    request.interactiveStrategy = AMZNInteractiveStrategyNever;

    // Make an Authorize call to the Login with Amazon SDK.
    [[AMZNAuthorizationManager sharedManager] authorize:request
                                            withHandler:^(AMZNAuthorizeResult *result, BOOL
                                                          userDidCancel, NSError *error) {
        if (error) {
            // Handle errors from the SDK or authorization server.
            if(error.code == kAMZNLWAApplicationNotAuthorized) {
                // Show authorize user button.
                NSLog(@"AmazonLoginPlugin authorize request NotAuthorized");

                NSString* payload = @"authorize request NotAuthorized";

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
                                         PluginFieldAccessToken: result.token,
                                         PluginFieldUser: result.user.profileData
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

- (void)appExists:(CDVInvokedUrlCommand *)command {
    NSLog(@"AmazonLoginPlugin appExists?");

    NSDictionary* options = [command argumentAtIndex:0];
    if ([options isKindOfClass:[NSNull class]]) {
        options = [NSDictionary dictionary];
    }
    NSNumber *appsFlag = [options objectForKey:@"appsFlag"];
    long lFlag = [appsFlag unsignedLongLongValue];
    NSLog(@"appsFlags: " @"0x%lx", lFlag);

    BOOL bLaunch = NO;
    if ([options objectForKey:@"appLaunch"]) {
        bLaunch = [[options objectForKey:@"appLaunch"] boolValue];
    }

    BOOL bExists = NO;
    if ((lFlag & PluginAppsShopping) != 0) {
        // Check whether Shopping app is installed or not
        if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:PluginAmazonShoppingLink]]) {
            bExists = YES;
            NSLog(@"Amazon Shopping app exists");
            if (bLaunch) {
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:PluginAmazonShoppingLink]];
            }
        }
    }
    if ((lFlag & PluginAppsAlexa) != 0) {
        // Check whether Alexa app is installed or not
        if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:PluginAmazonAlexaLink]]) {
            bExists = YES;
            NSLog(@"Amazon Alexa app exists");
            if (bLaunch) {
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:PluginAmazonAlexaLink]];
            }
        }
    }
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:bExists];

    // The sendPluginResult method is thread-safe.
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}
@end