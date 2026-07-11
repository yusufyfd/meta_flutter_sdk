package dev.yusufdemir.meta_flutter_sdk

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.os.Bundle
import com.facebook.AccessToken
import com.facebook.CallbackManager
import com.facebook.FacebookCallback
import com.facebook.FacebookException
import com.facebook.FacebookSdk
import com.facebook.GraphRequest
import com.facebook.GraphResponse
import com.facebook.HttpMethod
import com.facebook.appevents.AppEventsLogger
import com.facebook.login.LoginManager
import com.facebook.login.LoginResult
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry

class MetaFlutterSdkPlugin :
    FlutterPlugin,
    MethodChannel.MethodCallHandler,
    ActivityAware,
    PluginRegistry.ActivityResultListener {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private var activity: Activity? = null
    private val callbackManager = CallbackManager.Factory.create()
    private var pendingLogin: MethodChannel.Result? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "dev.yusufdemir/meta_flutter_sdk")
        channel.setMethodCallHandler(this)
        registerLoginCallback()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "initialize" -> initialize(call, result)
                "setAutoLogAppEventsEnabled" -> complete(result) {
                    FacebookSdk.setAutoLogAppEventsEnabled(call.required("enabled"))
                }
                "setAdvertiserIdCollectionEnabled" -> complete(result) {
                    FacebookSdk.setAdvertiserIDCollectionEnabled(call.required("enabled"))
                }
                "setAdvertiserTrackingEnabled" -> result.error(
                    "unsupported",
                    "Advertiser tracking is an iOS-only setting. Use advertiser ID collection on Android.",
                    null,
                )
                "setDataProcessingOptions" -> complete(result) {
                    FacebookSdk.setDataProcessingOptions(
                        call.required<List<String>>("options").toTypedArray(),
                        call.required("country"),
                        call.required("state"),
                    )
                }
                "setFlushBehavior" -> setFlushBehavior(call, result)
                "logEvent" -> logEvent(call, result)
                "flushEvents" -> complete(result) { AppEventsLogger.newLogger(context).flush() }
                "login" -> login(call, result)
                "logout" -> complete(result) { LoginManager.getInstance().logOut() }
                "currentAccessToken" -> result.success(accessTokenMap(AccessToken.getCurrentAccessToken()))
                "getAnonymousId" -> result.success(AppEventsLogger.getAnonymousAppDeviceGUID(context))
                "setUserId" -> complete(result) { AppEventsLogger.setUserID(call.argument<String>("userId")) }
                "graphRequest" -> graphRequest(call, result)
                else -> result.notImplemented()
            }
        } catch (error: Throwable) {
            result.nativeError(error)
        }
    }

    private fun initialize(call: MethodCall, result: MethodChannel.Result) {
        val autoInitialize = call.argument<Boolean>("autoInitialize") ?: true
        FacebookSdk.setAutoInitEnabled(autoInitialize)
        call.argument<Boolean>("autoLogAppEventsEnabled")?.let {
            FacebookSdk.setAutoLogAppEventsEnabled(it)
        }
        call.argument<Boolean>("advertiserIdCollectionEnabled")?.let {
            FacebookSdk.setAdvertiserIDCollectionEnabled(it)
        }
        call.argument<String>("flushBehavior")?.let { applyFlushBehavior(it) }

        if (autoInitialize && !FacebookSdk.isFullyInitialized()) {
            FacebookSdk.fullyInitialize()
        }

        result.success(
            mapOf(
                "platform" to "android",
                "sdkVersion" to FacebookSdk.getSdkVersion(),
                "initialized" to FacebookSdk.isFullyInitialized(),
            ),
        )
    }

    private fun setFlushBehavior(call: MethodCall, result: MethodChannel.Result) = complete(result) {
        applyFlushBehavior(call.required("behavior"))
    }

    private fun applyFlushBehavior(behavior: String) {
        AppEventsLogger.setFlushBehavior(
            when (behavior) {
                "automatic" -> AppEventsLogger.FlushBehavior.AUTO
                "explicitOnly" -> AppEventsLogger.FlushBehavior.EXPLICIT_ONLY
                else -> throw IllegalArgumentException("Unknown flush behavior: $behavior")
            },
        )
    }

    private fun logEvent(call: MethodCall, result: MethodChannel.Result) = complete(result) {
        requireInitialized()
        val logger = AppEventsLogger.newLogger(context)
        val name = call.required<String>("name")
        val parameters = bundle(call.argument<Map<String, Any?>>("parameters").orEmpty())
        val valueToSum = call.argument<Double>("valueToSum")
        if (valueToSum == null) {
            logger.logEvent(name, parameters)
        } else {
            logger.logEvent(name, valueToSum, parameters)
        }
    }

    private fun login(call: MethodCall, result: MethodChannel.Result) {
        requireInitialized()
        val currentActivity = activity ?: run {
            result.error("no_activity", "Facebook Login requires a foreground Activity.", null)
            return
        }
        if (pendingLogin != null) {
            result.error("login_in_progress", "Another Facebook Login request is active.", null)
            return
        }
        if ((call.argument<String>("tracking") ?: "enabled") == "limited") {
            result.error("unsupported", "Limited Login is only supported on iOS.", null)
            return
        }
        pendingLogin = result
        LoginManager.getInstance().logInWithReadPermissions(
            currentActivity,
            call.argument<List<String>>("permissions").orEmpty(),
        )
    }

    private fun graphRequest(call: MethodCall, result: MethodChannel.Result) {
        requireInitialized()
        val parameters = bundle(call.argument<Map<String, Any?>>("parameters").orEmpty())
        call.argument<String>("accessToken")?.let { parameters.putString("access_token", it) }
        val method = when (call.required<String>("method")) {
            "GET" -> HttpMethod.GET
            "POST" -> HttpMethod.POST
            "DELETE" -> HttpMethod.DELETE
            else -> throw IllegalArgumentException("Unsupported Graph method.")
        }
        val request = GraphRequest(
            AccessToken.getCurrentAccessToken(),
            call.required("path"),
            parameters,
            method,
        )
        request.callback = GraphRequest.Callback { response -> handleGraphResponse(response, result) }
        request.executeAsync()
    }

    private fun handleGraphResponse(response: GraphResponse, result: MethodChannel.Result) {
        val error = response.error
        if (error != null) {
            result.error(
                "graph_error",
                error.errorMessage ?: "Graph API request failed.",
                mapOf(
                    "type" to error.errorType,
                    "code" to error.errorCode,
                    "subcode" to error.subErrorCode,
                    "body" to response.rawResponse,
                ),
            )
            return
        }
        result.success(
            mapOf(
                "statusCode" to (response.connection?.responseCode ?: 200),
                "body" to (response.rawResponse ?: response.jsonObject?.toString() ?: "null"),
            ),
        )
    }

    private fun registerLoginCallback() {
        LoginManager.getInstance().registerCallback(
            callbackManager,
            object : FacebookCallback<LoginResult> {
                override fun onSuccess(result: LoginResult) {
                    pendingLogin?.success(
                        mapOf(
                            "cancelled" to false,
                            "accessToken" to accessTokenMap(result.accessToken),
                            "authenticationToken" to null,
                            "grantedPermissions" to result.recentlyGrantedPermissions.toList(),
                            "declinedPermissions" to result.recentlyDeniedPermissions.toList(),
                            "error" to null,
                        ),
                    )
                    pendingLogin = null
                }

                override fun onCancel() {
                    pendingLogin?.success(
                        mapOf(
                            "cancelled" to true,
                            "accessToken" to null,
                            "authenticationToken" to null,
                            "grantedPermissions" to emptyList<String>(),
                            "declinedPermissions" to emptyList<String>(),
                            "error" to mapOf(
                                "code" to "login_cancelled",
                                "message" to "The user cancelled Facebook Login.",
                                "details" to null,
                            ),
                        ),
                    )
                    pendingLogin = null
                }

                override fun onError(error: FacebookException) {
                    pendingLogin?.success(
                        mapOf(
                            "cancelled" to false,
                            "accessToken" to null,
                            "authenticationToken" to null,
                            "grantedPermissions" to emptyList<String>(),
                            "declinedPermissions" to emptyList<String>(),
                            "error" to mapOf(
                                "code" to "login_failed",
                                "message" to (error.message ?: "Facebook Login failed."),
                                "details" to mapOf(
                                    "type" to error.javaClass.name,
                                    "cause" to error.cause?.javaClass?.name,
                                ),
                            ),
                        ),
                    )
                    pendingLogin = null
                }
            },
        )
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean =
        callbackManager.onActivityResult(requestCode, resultCode, data)

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        LoginManager.getInstance().unregisterCallback(callbackManager)
    }

    private fun requireInitialized() {
        check(FacebookSdk.isFullyInitialized()) { "Meta SDK is not initialized. Call initialize() first." }
    }

    private fun bundle(values: Map<String, Any?>): Bundle = Bundle().apply {
        values.forEach { (key, value) ->
            when (value) {
                null -> Unit
                is String -> putString(key, value)
                is Boolean -> putBoolean(key, value)
                is Int -> putInt(key, value)
                is Long -> putLong(key, value)
                is Float -> putFloat(key, value)
                is Double -> putDouble(key, value)
                else -> throw IllegalArgumentException("Unsupported parameter type for '$key'.")
            }
        }
    }

    private fun accessTokenMap(token: AccessToken?): Map<String, Any?>? = token?.let {
        mapOf(
            "token" to it.token,
            "userId" to it.userId,
            "applicationId" to it.applicationId,
            "permissions" to it.permissions.toList(),
            "declinedPermissions" to it.declinedPermissions.toList(),
            "expiredPermissions" to it.expiredPermissions.toList(),
            "expiresAt" to it.expires.time,
            "dataAccessExpiresAt" to it.dataAccessExpirationTime.time,
        )
    }

    private fun complete(result: MethodChannel.Result, action: () -> Unit) {
        action()
        result.success(null)
    }

    private inline fun <reified T> MethodCall.required(name: String): T =
        argument<T>(name) ?: throw IllegalArgumentException("Missing argument: $name")

    private fun MethodChannel.Result.nativeError(error: Throwable, code: String = "native_error") {
        error(code, error.message ?: error.javaClass.simpleName, mapOf("type" to error.javaClass.name))
    }
}
