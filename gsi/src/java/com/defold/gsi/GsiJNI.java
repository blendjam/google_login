package com.defold.gsi;

import android.util.Log;
import android.app.Activity;
import androidx.credentials.CredentialManagerCallback;
import androidx.credentials.CredentialManager;
import androidx.credentials.GetCredentialRequest;
import androidx.credentials.GetCredentialResponse;
import androidx.credentials.ClearCredentialStateRequest;
import androidx.credentials.exceptions.GetCredentialException;
import com.google.android.libraries.identity.googleid.GoogleIdTokenCredential;
import androidx.credentials.exceptions.ClearCredentialException;
import com.google.android.libraries.identity.googleid.GetSignInWithGoogleOption;
import org.json.JSONObject;
import org.json.JSONException;

public class GsiJNI {
    public static final String TAG = "GSI";
    // duplicate of enums from extension.h
    public static final int MSG_SIGN_IN = 1;
    public static final int MSG_SIGN_OUT = 2;

    // duplicate of enums from extension.h
    private static final int STATUS_SUCCESS = 1;
    private static final int STATUS_FAILED = 2;
    
    private Activity activity;
    private String clientId;

    // gsi results
    private String mServerAuthCode; 

    public static native void gsiAddToQueue(int msg, String json);

    public GsiJNI(Activity activity, String clientId)
   {
        this.activity = activity;
        this.clientId = clientId;
   }

    private void sendSimpleMessage(int msg, Object... keyValues) {
        if (keyValues.length % 2 != 0) {
            throw new IllegalArgumentException("Key-values must be in pairs");
        }

        String message;
        try {
            JSONObject obj = new JSONObject();
            for (int i = 0; i < keyValues.length; i += 2) {
                String key = (String) keyValues[i];
                Object value = keyValues[i + 1];
                obj.put(key, value);
            }
            message = obj.toString();
        } catch (JSONException e) {
            message = "{ \"error\": \"Error while converting simple message to JSON: " 
                    + e.getMessage() + "\" }";
        }

        gsiAddToQueue(msg, message); 
    }

    public void login() {
        CredentialManager credentialManager = CredentialManager.create(activity);
        
        GetSignInWithGoogleOption signInWithGoogleOption = new GetSignInWithGoogleOption.Builder(clientId).build();
        
        GetCredentialRequest request = new GetCredentialRequest.Builder()
                .addCredentialOption(signInWithGoogleOption)
                .build();
        
        credentialManager.getCredentialAsync(
            activity,
            request,
            null, 
            activity.getMainExecutor(),
            new CredentialManagerCallback<GetCredentialResponse, GetCredentialException>() {
                @Override
                public void onResult(GetCredentialResponse response) {
                    GoogleIdTokenCredential googleIdTokenCredential = GoogleIdTokenCredential.createFrom(response.getCredential().getData());
                    mServerAuthCode = googleIdTokenCredential.getIdToken();
                    sendSimpleMessage(MSG_SIGN_IN, "status", STATUS_SUCCESS, "auth_token", mServerAuthCode);
                }
                
                @Override
                public void onError(GetCredentialException e) {
                    sendSimpleMessage(MSG_SIGN_IN, "status", STATUS_FAILED, "error", e.getMessage());
                }
            }
        );
    }

    public void logout() {
        try {
            CredentialManager credentialManager = CredentialManager.create(activity);
            ClearCredentialStateRequest request = new ClearCredentialStateRequest(ClearCredentialStateRequest.TYPE_CLEAR_CREDENTIAL_STATE);

            credentialManager.clearCredentialStateAsync(
                request,
                null,
                activity.getMainExecutor(),
                new CredentialManagerCallback<Void, ClearCredentialException>() {
                    @Override
                    public void onResult(Void result) {
                        mServerAuthCode = null;
                        sendSimpleMessage(MSG_SIGN_OUT, "status", STATUS_SUCCESS);
                    }

                    @Override
                    public void onError(ClearCredentialException e) {
                        // Even if clearing remote state fails, clear local token and report error
                        mServerAuthCode = null;
                        sendSimpleMessage(MSG_SIGN_OUT, "status", STATUS_FAILED, "error", e.getMessage());
                    }
                }
            );
        } catch (Exception e) {
            // Fallback: clear local token and report failure
            mServerAuthCode = null;
            sendSimpleMessage(MSG_SIGN_OUT, "status", STATUS_FAILED, "error", e.getMessage());
        }
    }

    public String getServerAuthCode()
    {
        return mServerAuthCode;    
    }
}