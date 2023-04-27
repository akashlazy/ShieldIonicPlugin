package com.shieldfraud;

import androidx.annotation.Nullable;

import com.shield.android.BlockedDialog;
import com.shield.android.Shield;
import com.shield.android.ShieldCallback;
import com.shield.android.ShieldException;

import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CallbackContext;

import org.apache.cordova.PluginResult;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.HashMap;
import java.util.Iterator;

/**
 * This class echoes a string called from JavaScript.
 */
public class ShieldFraudPlugin extends CordovaPlugin {

    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
        System.out.println("Akash==="+action);
        System.out.println("Akash Para==="+args);
        if (action.equals("initShieldFraud")) {
            JSONObject dictionary = args.getJSONObject(0);
            initShieldFraud(callbackContext, dictionary);
        } else if (action.equals("getSessionID")) {
            getSessionId(callbackContext);
        } else if (action.equals("getDeviceResult")) {
            getDeviceResult(callbackContext);
        } else if (action.equals("sendAttributes")) {
            JSONObject dictionary = args.getJSONObject(0);
            sendAttributes(callbackContext,dictionary);
        } else if (action.equals("sendDeviceSignature")) {
            String screenName = args.getString(0);
            sendDeviceSignature(callbackContext,screenName);
        } else if (action.equals("isShieldInitialized")) {
            isShieldInitialized(callbackContext);
        }
        return true;
    }

    private void isShieldInitialized(CallbackContext callbackContext) {
        try {
            callbackContext.success(String.valueOf(Shield.getInstance() != null));
        } catch (IllegalStateException exception) {
            //Shield is not initialized yet.
            callbackContext.error(String.valueOf(false));
        }
    }

    private void initShieldFraud(CallbackContext callbackContext, JSONObject dictionary) throws JSONException {
        if (dictionary == null) {
            return;
        }
        String siteID = (dictionary.getString("siteID") != null) ? dictionary.getString("siteID") : "";
        String key = (dictionary.getString("key") != null) ? dictionary.getString("key") : "";

        cordova.getThreadPool().execute(new Runnable() {
            @Override
            public void run() {
                Shield shield = new Shield.Builder(cordova.getActivity(),siteID,key).registerDeviceShieldCallback(new ShieldCallback<JSONObject>() {
                    @Override
                    public void onSuccess(@Nullable JSONObject jsonObject) {

                        callbackContext.success(jsonObject.toString());
                    }

                    @Override
                    public void onFailure(@Nullable ShieldException e) {
                        callbackContext.error(e.message);
                    }
                }).build();

                Shield.setSingletonInstance(shield);
            }
        });
    }

    private void getSessionId(CallbackContext callbackContext) {
        cordova.getThreadPool().execute(new Runnable() {
            @Override
            public void run() {
                try {
                    String sessionId = Shield.getInstance().getSessionId();
                    callbackContext.success(sessionId);
                } catch (IllegalStateException e) {
                    callbackContext.error(e.toString());
                }
            }
        });
    }

    private void getDeviceResult(CallbackContext callbackContext) {
        cordova.getThreadPool().execute(new Runnable() {
            @Override
            public void run() {
                try {
                    JSONObject result = Shield.getInstance().getLatestDeviceResult();
                    callbackContext.success(result.toString());
                } catch (IllegalStateException e) {
                    callbackContext.error(e.toString());
                }
            }
        });
    }

    private void sendAttributes(CallbackContext callbackContext, JSONObject object) {
        try {
            String screenName = object.getString("screenName");
            HashMap<String,String> data = jsonObjectToHashMap(object);
            Shield.getInstance().sendAttributes(screenName, data, new ShieldCallback<Boolean>() {
                @Override
                public void onSuccess(@Nullable Boolean aBoolean) {
                    callbackContext.success(String.valueOf(aBoolean));
                }

                @Override
                public void onFailure(@Nullable ShieldException e) {
                    callbackContext.error(e.message);
                }
            });
        } catch (JSONException e) {
            e.printStackTrace();
            callbackContext.error(e.toString());
        }
    }

    private void sendDeviceSignature(CallbackContext callbackContext, String screenName) {
        Shield.getInstance().sendDeviceSignature(screenName, new Shield.DeviceResultStateListener() {
            @Override
            public void isReady() {
                callbackContext.success(String.valueOf(true));
            }
        });
    }

    private static HashMap<String, String> jsonObjectToHashMap(JSONObject jsonObject) throws JSONException {
        HashMap<String, String> hashMap = new HashMap<>();
        Iterator<String> iterator = jsonObject.keys();
        while (iterator.hasNext()) {
            String key = iterator.next();
            String value = jsonObject.getString(key);
            hashMap.put(key, value);
        }
        return hashMap;
    }
}