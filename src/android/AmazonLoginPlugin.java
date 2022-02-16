/**
 */
package org.apache.cordova.lwa;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaInterface;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CordovaWebView;
import org.apache.cordova.PluginResult;
import org.apache.cordova.PluginResult.Status;
import org.json.JSONObject;
import org.json.JSONArray;
import org.json.JSONException;

import android.os.Build;

import android.content.Context;
import android.content.Intent;
import android.os.Handler;
import android.util.Log;
import java.util.List;
import java.util.ArrayList;

import com.amazon.identity.auth.device.AuthError;
import com.amazon.identity.auth.device.api.Listener;
import com.amazon.identity.auth.device.api.authorization.AuthCancellation;
import com.amazon.identity.auth.device.api.authorization.AuthorizationManager;
import com.amazon.identity.auth.device.api.authorization.AuthorizeListener;
import com.amazon.identity.auth.device.api.authorization.AuthorizeRequest;
import com.amazon.identity.auth.device.api.authorization.AuthorizeResult;
import com.amazon.identity.auth.device.api.authorization.ProfileScope;
import com.amazon.identity.auth.device.api.authorization.Scope;
import com.amazon.identity.auth.device.api.authorization.ScopeFactory;
import com.amazon.identity.auth.device.api.authorization.User;
import com.amazon.identity.auth.device.api.workflow.RequestContext;

public class AmazonLoginPlugin extends CordovaPlugin {
    // Apps to check if exists
    private static final int APPS_NONE                  = 0x00000;
    private static final int APPS_SHOPPING              = 0x00001;
    private static final int APPS_ALEXA                 = 0x00010;

    // Alexa scopes doc is here:
    // https://developer.amazon.com/docs/smapi/ask-cli-intro.html
    private static final int PROFILE_NONE               = 0x00000;
    private static final int PROFILE_ALEXA_PRE_AUTH     = 0x00001;
    private static final int PROFILE_USERID             = 0x00010;
    private static final int PROFILE_PROFILE            = 0x00020;
    private static final int PROFILE_POSTAL             = 0x00040;
    private static final int PROFILE_ALEXA_SKILLS_R     = 0x00100;
    private static final int PROFILE_ALEXA_SKILLS_RW    = 0x00200;
    private static final int PROFILE_ALEXA_SKILLS_TEST  = 0x00800;
    private static final int PROFILE_ALEXA_MODELS_R     = 0x01000;
    private static final int PROFILE_ALEXA_MODELS_RW    = 0x02000;
//////////////////////////////////////////////////////////////////////// ASP ///////////////////////////////////////////////////////////////////////////////////////////////
    private static final int PROFILE_ALEXA_PRE_AUTH_ASP = 0x03000;
//////////////////////////////////////////////////////////////////////// ASP ///////////////////////////////////////////////////////////////////////////////////////////////
    // Untested scope for Amazon Dash
    private static final int PROFILE_DASH_REPLENISH     = 0x10000;
    
    private static final String TAG = "AmazonLoginPlugin";
    
    private static final String AMAZON_APP_SHOPPING_NAME = "com.amazon.mShop.android.shopping";
    private static final String AMAZON_APP_ALEXA_NAME = "com.amazon.dee.app";

    private static final String ACTION_AUTHORIZE = "authorize";
    private static final String ACTION_FETCH_USER_PROFILE = "fetchUserProfile";
    private static final String ACTION_GET_TOKEN = "getToken";
    private static final String ACTION_SIGNOUT = "signOut";
    private static final String ACTION_APP_EXISTS = "appExists";
        
    // New stuff to support AVS Companion App
    private static final String ACTION_AUTHORIZE_DEVICE = "authorizeDevice";
    
//////////////////////////////////////////////////////////////////////// ASP ///////////////////////////////////////////////////////////////////////////////////////////////
    private static final String ACTION_AUTHORIZE_DEVICE_ASP = "authorizeDevice_ASP";
//////////////////////////////////////////////////////////////////////// ASP ///////////////////////////////////////////////////////////////////////////////////////////////


    private static final String FIELD_ACCESS_TOKEN = "accessToken";
    private static final String FIELD_AUTHORIZATION_CODE = "authorizationCode";
    private static final String FIELD_USER = "user";
    private static final String FIELD_CLIENT_ID = "clientId";
    private static final String FIELD_REDIRECT_URI = "redirectURI";
    private static final String FIELD_APP_NAME = "appName";
        
    // New stuff to support AVS Companion App
    // Code challenge method can be "plain" or " S256" (SHA256)
    private static final String CODE_CHALLENGE_METHOD = "S256";
    
    // Flag to catch Authorize Device flow where hosted splash has Skip and Back which are not bound
    private boolean mIsAuthDevice;
    private boolean mCompletedRequest;
    private String mProductID;
    private String mProductDSN;
    private String mCodeChallenge;
    private int mScopeFlag;
    private int mAppsFlag;
    private boolean mAppLaunch;

    private RequestContext mRequestContext;
    private CallbackContext mSavedCallbackContext;
    private AuthorizeListener mAuthListener;

    private Scope alexaScope(String productID, String productDSN) {
        if (productID != null && productDSN != null) {
            try {
                final JSONObject scopeData = new JSONObject();
                final JSONObject productInstanceAttributes = new JSONObject();
                productInstanceAttributes.put("deviceSerialNumber", productDSN);
                scopeData.put("productInstanceAttributes", productInstanceAttributes);
                scopeData.put("productID", productID);
            
                return ScopeFactory.scopeNamed("alexa:all", scopeData);
            } catch (JSONException e) {
                // handle exception here
                Log.i(TAG, "Alexa scope creation exception", e);
            }
        }
        return null;
    }
    
    private Scope[] computeScopes(int mScopeFlag) {
        List<Scope> scopes = new ArrayList<Scope>();
        if ((mScopeFlag & PROFILE_USERID) != 0) {
            scopes.add(ProfileScope.userId());
            Log.i(TAG, "Profile: userId scope added");
        }
        if ((mScopeFlag & PROFILE_PROFILE) != 0) {
            scopes.add(ProfileScope.profile());
            Log.i(TAG, "Profile: profile scope added");
        }
        if ((mScopeFlag & PROFILE_POSTAL) != 0) {
            scopes.add(ProfileScope.postalCode());
            Log.i(TAG, "Profile: postal scope added");
        }
        if ((mScopeFlag & PROFILE_ALEXA_SKILLS_R) != 0) {
            scopes.add(ScopeFactory.scopeNamed("alexa::ask:skills:read"));
            Log.i(TAG, "Profile: alexa skills read scope added");
        }
        if ((mScopeFlag & PROFILE_ALEXA_SKILLS_RW) != 0) {
            scopes.add(ScopeFactory.scopeNamed("alexa::ask:skills:readwrite"));
            Log.i(TAG, "Profile: alexa skills readwrite scope added");
        }
        if ((mScopeFlag & PROFILE_ALEXA_SKILLS_TEST) != 0) {
            scopes.add(ScopeFactory.scopeNamed("alexa::ask:skills:test"));
            Log.i(TAG, "Profile: alexa skills test scope added");
        }
        if ((mScopeFlag & PROFILE_ALEXA_MODELS_R) != 0) {
            scopes.add(ScopeFactory.scopeNamed("alexa::ask:models:read"));
            Log.i(TAG, "Profile: alexa models read scope added");
        }
        if ((mScopeFlag & PROFILE_ALEXA_MODELS_RW) != 0) {
            scopes.add(ScopeFactory.scopeNamed("alexa::ask:models:readwrite"));
            Log.i(TAG, "Profile: alexa models readwrite scope added");
        }
        if ((mScopeFlag & PROFILE_DASH_REPLENISH) != 0) {
            scopes.add(ScopeFactory.scopeNamed("dash:replenish"));
            Log.i(TAG, "Profile: dash replenish scope added");
        }
        if ((mScopeFlag & PROFILE_ALEXA_PRE_AUTH) != 0) {
            scopes.add(ScopeFactory.scopeNamed("alexa:voice_service:pre_auth"));
            Log.i(TAG, "Profile: alexa pre_auth scope added");
        }
//////////////////////////////////////////////////////////////////////// ASP ///////////////////////////////////////////////////////////////////////////////////////////////
        if ((mScopeFlag & PROFILE_ALEXA_PRE_AUTH_ASP) != 0) {
            scopes.add(ScopeFactory.scopeNamed("alexa::enterprise::management"));
            Log.i(TAG, "Profile: alexa models read scope added");
        }
//////////////////////////////////////////////////////////////////////// ASP ///////////////////////////////////////////////////////////////////////////////////////////////
        return scopes.toArray(new Scope[scopes.size()]);
    }

    public void initialize(final CordovaInterface cordova, CordovaWebView webView) {
        super.initialize(cordova, webView);

        Log.d(TAG, "Initializing AmazonLoginPlugin");
        mIsAuthDevice = false;
        mRequestContext = RequestContext.create(cordova.getActivity());
        mAuthListener = new AuthorizeListener() {

            @Override
            public void onSuccess(AuthorizeResult result) {
                mCompletedRequest = true;
                Log.d(TAG, "Authorization was completed successfully");
                /* Your app is now authorized for the requested scopes */
                sendAuthorizeResult(result);
            }

            @Override
            public void onError(AuthError ae) {
                mCompletedRequest = true;
                Log.d(TAG, "There was an error during the attempt to authorize the application");
                Log.d(TAG, ae.getType().toString());
                Log.d(TAG, ae.getCategory().toString());
                Log.d(TAG, ae.toString());
                /* Inform the user of the error */
                mSavedCallbackContext.error("Trouble during the attempt to authorize the application");
            }

            @Override
            public void onCancel(AuthCancellation cancellation) {
                mCompletedRequest = true;
                Log.d(TAG, "Authorization was cancelled before it could be completed");
                /* Reset the UI to a ready-to-login state */
                mSavedCallbackContext.error("Authorization was cancelled before it could be completed");
            }
        };
        
        mRequestContext.registerListener(mAuthListener);
        Log.d(TAG, "Registered AuthorizeListener to plugin");      
    }

    public boolean execute(String action, JSONArray args, final CallbackContext callbackContext) throws JSONException {
        // Doing a new request
        this.mCompletedRequest = false;
        
        this.mSavedCallbackContext = callbackContext;
        // Setup the options if provided...
        final JSONObject params = (args != null && args.length() > 0) ? args.getJSONObject(0) : null;
        mScopeFlag = PROFILE_NONE;
        mAppsFlag = APPS_NONE;
        mAppLaunch = false;
        if (params != null) {
            Log.d(TAG, "Received JSON options");
            if (params.has("scopeFlag")) {
                mScopeFlag = params.getInt("scopeFlag");
            }
            if (params.has("productID")) {
                mProductID = params.getString("productID");
            }
            if (params.has("productDSN")) {
                mProductDSN = params.getString("productDSN");
            }
            if (params.has("codeChallenge")) {
                mCodeChallenge = params.getString("codeChallenge");
            }
            if (params.has("appsFlag")) {
                mAppsFlag = params.getInt("appsFlag");
            }
            if (params.has("appLaunch")) {
                mAppLaunch = params.getBoolean("appLaunch");
            }
        }

        if (ACTION_AUTHORIZE_DEVICE.equals(action)) {
            Log.i(TAG, "Both Authorization started");
            Log.i(TAG, "Args: " + mProductID + ", " + mProductDSN + ", " + mCodeChallenge);
            if (mProductID != null && mProductDSN != null && mCodeChallenge != null) {
                mIsAuthDevice = true;
                // Need to get the MAC address (DSN) of the new device from the App
                // Optionally also provide the product ID?
                // Also a code challenge from the online service using the challenge method: S256

                cordova.getThreadPool().execute(new Runnable() {
                    public void run() {
                        AuthorizationManager.authorize(new AuthorizeRequest
                            .Builder(mRequestContext)
                            .addScope(alexaScope(mProductID, mProductDSN))
                            .addScopes(computeScopes(mScopeFlag))
                            .forGrantType(AuthorizeRequest.GrantType.AUTHORIZATION_CODE)
                            .withProofKeyParameters(mCodeChallenge, CODE_CHALLENGE_METHOD)
                            .build());
                    }
                });
            } else {
                Log.i(TAG, "Not authorizing without valid product ID, product DSN or code challenge");
            }
        }
//////////////////////////////////////////////////////////////////////// ASP ///////////////////////////////////////////////////////////////////////////////////////////////
        else if (ACTION_AUTHORIZE_DEVICE_ASP.equals(action)) {
           Log.i(TAG, "Both Authorization ASP started");
            Log.i(TAG, "Args: " + mProductID + ", " + mProductDSN + ", " + mCodeChallenge);
            if (mProductID != null && mProductDSN != null && mCodeChallenge != null) {
                mIsAuthDevice = true;
                // Need to get the MAC address (DSN) of the new device from the App
                // Optionally also provide the product ID?
                // Also a code challenge from the online service using the challenge method: S256

                cordova.getThreadPool().execute(new Runnable() {
                    public void run() {
                        AuthorizationManager.authorize(new AuthorizeRequest
                            .Builder(mRequestContext)
                            .addScope(alexaScope(mProductID, mProductDSN))
                            .addScopes(computeScopes(mScopeFlag))
                            .forGrantType(AuthorizeRequest.GrantType.AUTHORIZATION_CODE)
                            .withProofKeyParameters(mCodeChallenge, CODE_CHALLENGE_METHOD)
                            .build());
                    }
                });
            } else {
                Log.i(TAG, "Not authorizing without valid product ID, product DSN or code challenge");
            }
        }
//////////////////////////////////////////////////////////////////////// ASP ///////////////////////////////////////////////////////////////////////////////////////////////

        else if (ACTION_AUTHORIZE.equals(action)) {
            Log.i(TAG, "Authorization started");
            Log.i(TAG, "Args: " + mScopeFlag );
            
            if (mScopeFlag != PROFILE_NONE) {
                cordova.getThreadPool().execute(new Runnable() {
                    public void run() {
                        AuthorizationManager.authorize(new AuthorizeRequest
                                .Builder(mRequestContext)
                                .addScopes(computeScopes(mScopeFlag))
                                .build());
                    }
                });
            } else {
                Log.i(TAG, "Not authorizing without valid profile scope");
            }
        } else if (ACTION_FETCH_USER_PROFILE.equals(action)) {
            Log.i(TAG, "User Profile fetching started");
            cordova.getThreadPool().execute(new Runnable() {
                public void run() {
                    User.fetch(cordova.getActivity(), new Listener<User, AuthError>() {

                        /* fetch completed successfully. */
                        @Override
                        public void onSuccess(User user) {
                            sendUserResult(user);
                        }

                        /* There was an error during the attempt to get the profile. */
                        @Override
                        public void onError(AuthError ae) {
                            mSavedCallbackContext.error("Trouble obtaining the profile");
                        }
                    });
                }
            });

        } else if (ACTION_GET_TOKEN.equals(action)) {
            Log.i(TAG, "Get token started");
            Log.i(TAG, "Args: " + mScopeFlag );
            
            if (mScopeFlag != PROFILE_NONE) {

                cordova.getThreadPool().execute(new Runnable() {
                    public void run() {
                        AuthorizationManager.getToken(cordova.getActivity().getApplicationContext(),
                            computeScopes(mScopeFlag),
                            new Listener<AuthorizeResult, AuthError>() {

                            @Override
                            public void onSuccess(AuthorizeResult result) {
                                if (result.getAccessToken() != null) {
                                    /* The user is signed in */
                                    sendAuthorizeResult(result);
                                } else {
                                    mSavedCallbackContext.error("The user is not signed in");
                                }
                            }

                            @Override
                            public void onError(AuthError ae) {
                                /* The user is not signed in */
                                mSavedCallbackContext.error("The user is not signed in");

                            }
                        });
                    }
                });
            } else {
                Log.i(TAG, "Not getting token without valid profile scope");
            }
        } else if (ACTION_SIGNOUT.equals(action)) {
            Log.i(TAG, "Signout started");
            cordova.getThreadPool().execute(new Runnable() {
                public void run() {
                    AuthorizationManager.signOut(cordova.getActivity().getApplicationContext(), new Listener<Void, AuthError>() {
                        @Override
                        public void onSuccess(Void response) {
                            // Set logged out state in UI
                            Log.i(TAG, "The user is signed out");
                            JSONObject logoutResult = new JSONObject();
                            try {
                                logoutResult.put(FIELD_ACCESS_TOKEN, "");
                                mSavedCallbackContext.success(logoutResult);
                            } catch (Exception e) {
                                mSavedCallbackContext.error("Trouble creating success logout JSON: " + e.getMessage());
                            }
                        }

                        @Override
                        public void onError(AuthError authError) {                            
                            // Log the error
                            Log.i(TAG, "The user is not signed out");
                            mSavedCallbackContext.error("The user is not signed out");
                        }
                    });
                }
            });
        } else if (ACTION_APP_EXISTS.equals(action)) {
            Log.i(TAG, "Check if Amazon's app exists");
            Context context = this.cordova.getActivity().getApplicationContext();
            Intent launchIntent = null;
            if ((mAppsFlag & APPS_SHOPPING) != 0) {
                launchIntent = context.getPackageManager().getLaunchIntentForPackage(AMAZON_APP_SHOPPING_NAME);
            } else if ((mAppsFlag & APPS_ALEXA) != 0) {
                launchIntent = context.getPackageManager().getLaunchIntentForPackage(AMAZON_APP_ALEXA_NAME);
            }
            JSONObject logoutResult = new JSONObject();
            try {
                if (launchIntent != null) {
                    String className = launchIntent.getComponent().getClassName();
                    logoutResult.put(FIELD_APP_NAME, className);
                } else
                    logoutResult.put(FIELD_APP_NAME, "");                
                mSavedCallbackContext.success(logoutResult);
                if (mAppLaunch == true && launchIntent != null)
                    this.cordova.getActivity().startActivity(launchIntent);
            } catch (Exception e) {
                mSavedCallbackContext.error("Trouble creating amazon app exists JSON: " + e.getMessage());
            }
        } else {
            Log.i(TAG, "Action " + action + "doesn't exist");
            return false;
        }
        return true;
    }
        
    @Override
    public void onDestroy() {
        Log.d(TAG, "Plugin about to invoke super Destroy()");
        super.onDestroy();
    }
    
    @Override
    public void onResume(boolean multitasking) {
        super.onResume(multitasking);
        if (mRequestContext != null)
            mRequestContext.onResume();
        else
            Log.d(TAG, "Plugin could not perform mRequestContext resume");
        // Catch Skip and Back UX that is not bound by current abstract class events
        if (mIsAuthDevice) {
            final Handler handler = new Handler();
            handler.postDelayed(new Runnable() {
                @Override
                public void run() {
                    if (!mCompletedRequest) {
                        Log.d(TAG, "onResumed however requests are still pending on Authorize Device workflow");
                        if (mSavedCallbackContext != null)
                            mSavedCallbackContext.error("Authorize device workflow was either skipped or popped and not completed");
                        }
                    }
            }, 1000); // Delay check for 1 sec 
        }
    }

    private void sendAuthorizeResult(AuthorizeResult result) {

        if (mSavedCallbackContext == null) {
            return;
        }
        JSONObject authResult = new JSONObject();
        try {
            authResult.put(FIELD_ACCESS_TOKEN, result.getAccessToken());
            authResult.put(FIELD_AUTHORIZATION_CODE, result.getAuthorizationCode());
            authResult.put(FIELD_CLIENT_ID, result.getClientId());
            authResult.put(FIELD_REDIRECT_URI, result.getRedirectURI());
            if (result.getUser() != null)
                authResult.put(FIELD_USER, new JSONObject(result.getUser().getUserInfo()));
            // For Companion app we need to...
            // Securely send the authorization code, redirectUri, and clientId to the product
            mSavedCallbackContext.success(authResult);
            mIsAuthDevice = false; // Reset flag
        } catch (Exception e) {
            mSavedCallbackContext.error("Trouble obtaining Authorize Result, error: " + e.getMessage());
        }
    }

    private void sendUserResult(User user) {
        if (mSavedCallbackContext == null) {
            return;
        }
        try {
            mSavedCallbackContext.success(new JSONObject(user.getUserInfo()));
        } catch (Exception e) {
            mSavedCallbackContext.error("Trouble obtaining user, error: " + e.getMessage());
        }
    }
}
