import FBSDKCoreKit
import FBSDKLoginKit
import Flutter
import UIKit

public final class MetaFlutterSdkPlugin: NSObject, FlutterPlugin {
  private let loginManager = LoginManager()
  private weak var viewController: UIViewController?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "dev.yusufdemir/meta_flutter_sdk",
      binaryMessenger: registrar.messenger()
    )
    let instance = MetaFlutterSdkPlugin()
    instance.viewController = registrar.viewController
    registrar.addMethodCallDelegate(instance, channel: channel)
    registrar.addApplicationDelegate(instance)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    do {
      switch call.method {
      case "initialize":
        try initialize(arguments(call), result: result)
      case "setAutoLogAppEventsEnabled":
        Settings.shared.isAutoLogAppEventsEnabled = try required(call, "enabled")
        result(nil)
      case "setAdvertiserIdCollectionEnabled":
        Settings.shared.isAdvertiserIDCollectionEnabled = try required(call, "enabled")
        result(nil)
      case "setAdvertiserTrackingEnabled":
        applyAdvertiserTrackingEnabled(try required(call, "enabled"))
        result(nil)
      case "setDataProcessingOptions":
        Settings.shared.setDataProcessingOptions(
          try required(call, "options"),
          country: Int32(try required(call, "country") as Int),
          state: Int32(try required(call, "state") as Int)
        )
        result(nil)
      case "setFlushBehavior":
        try applyFlushBehavior(try required(call, "behavior"))
        result(nil)
      case "logEvent":
        try logEvent(call)
        result(nil)
      case "flushEvents":
        AppEvents.shared.flush()
        result(nil)
      case "login":
        try login(call, result: result)
      case "logout":
        loginManager.logOut()
        result(nil)
      case "currentAccessToken":
        result(accessTokenMap(AccessToken.current))
      case "getAnonymousId":
        result(AppEvents.shared.anonymousID)
      case "setUserId":
        AppEvents.shared.userID = arguments(call)["userId"] as? String
        result(nil)
      case "graphRequest":
        try graphRequest(call, result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    } catch {
      result(flutterError(error))
    }
  }

  private func initialize(_ values: [String: Any], result: FlutterResult) throws {
    if let enabled = values["autoLogAppEventsEnabled"] as? Bool {
      Settings.shared.isAutoLogAppEventsEnabled = enabled
    }
    if let enabled = values["advertiserIdCollectionEnabled"] as? Bool {
      Settings.shared.isAdvertiserIDCollectionEnabled = enabled
    }
    if let enabled = values["advertiserTrackingEnabled"] as? Bool {
      applyAdvertiserTrackingEnabled(enabled)
    }
    if let behavior = values["flushBehavior"] as? String {
      try applyFlushBehavior(behavior)
    }

    let shouldInitialize = values["autoInitialize"] as? Bool ?? true
    if shouldInitialize {
      ApplicationDelegate.shared.initializeSDK()
    }
    result([
      "platform": "ios",
      "sdkVersion": Settings.shared.sdkVersion,
      "initialized": shouldInitialize,
    ])
  }

  private func applyFlushBehavior(_ behavior: String) throws {
    switch behavior {
    case "automatic": AppEvents.shared.flushBehavior = .auto
    case "explicitOnly": AppEvents.shared.flushBehavior = .explicitOnly
    default: throw MetaNativeError.invalidArgument("Unknown flush behavior: \(behavior)")
    }
  }

  private func applyAdvertiserTrackingEnabled(_ enabled: Bool) {
    Settings.shared.advertisingTrackingStatus = enabled ? .allowed : .disallowed
  }

  private func logEvent(_ call: FlutterMethodCall) throws {
    let name: String = try required(call, "name")
    let rawParameters = (arguments(call)["parameters"] as? [String: Any]) ?? [:]
    var parameters: [AppEvents.ParameterName: Any] = [:]
    rawParameters.forEach { parameters[AppEvents.ParameterName($0.key)] = $0.value }

    if let value = arguments(call)["valueToSum"] as? Double {
      AppEvents.shared.logEvent(
        AppEvents.Name(name),
        valueToSum: value,
        parameters: parameters
      )
    } else {
      AppEvents.shared.logEvent(AppEvents.Name(name), parameters: parameters)
    }
  }

  private func login(_ call: FlutterMethodCall, result: @escaping FlutterResult) throws {
    let permissions: [String] = try required(call, "permissions")
    let trackingValue: String = try required(call, "tracking")
    let tracking: LoginTracking = trackingValue == "limited" ? .limited : .enabled
    let nonce = arguments(call)["nonce"] as? String
    let configuration: LoginConfiguration?
    if let nonce = nonce {
      configuration = LoginConfiguration(
        permissions: permissions,
        tracking: tracking,
        nonce: nonce
      )
    } else {
      configuration = LoginConfiguration(permissions: permissions, tracking: tracking)
    }
    guard let configuration = configuration else {
      throw MetaNativeError.invalidArgument("Invalid permissions or nonce.")
    }

    loginManager.logIn(viewController: viewController, configuration: configuration) { loginResult in
      switch loginResult {
      case .cancelled:
        result([
          "cancelled": true,
          "accessToken": NSNull(),
          "authenticationToken": NSNull(),
          "grantedPermissions": [],
          "declinedPermissions": [],
        ])
      case .failed(let error):
        result(self.flutterError(error, code: "login_failed"))
      case .success(let granted, let declined, let token):
        let payload: [String: Any] = [
          "cancelled": false,
          "accessToken": self.accessTokenMap(token) ?? NSNull(),
          "authenticationToken": AuthenticationToken.current?.tokenString ?? NSNull(),
          "grantedPermissions": granted.map(\.name),
          "declinedPermissions": declined.map(\.name),
        ]
        result(payload)
      }
    }
  }

  private func graphRequest(_ call: FlutterMethodCall, result: @escaping FlutterResult) throws {
    let values = arguments(call)
    let path: String = try required(call, "path")
    let methodValue: String = try required(call, "method")
    let method: HTTPMethod
    switch methodValue {
    case "GET": method = .get
    case "POST": method = .post
    case "DELETE": method = .delete
    default: throw MetaNativeError.invalidArgument("Unsupported Graph method.")
    }
    let request = GraphRequest(
      graphPath: path,
      parameters: values["parameters"] as? [String: Any] ?? [:],
      tokenString: values["accessToken"] as? String ?? AccessToken.current?.tokenString,
      version: nil,
      httpMethod: method
    )
    request.start { _, response, error in
      if let error = error {
        result(self.flutterError(error, code: "graph_error"))
        return
      }
      do {
        let data = try JSONSerialization.data(withJSONObject: response ?? NSNull())
        result([
          "statusCode": 200,
          "body": String(data: data, encoding: .utf8) ?? "null",
        ])
      } catch {
        result(self.flutterError(error, code: "serialization_error"))
      }
    }
  }

  private func accessTokenMap(_ token: AccessToken?) -> [String: Any?]? {
    guard let token = token else { return nil }
    return [
      "token": token.tokenString,
      "userId": token.userID,
      "applicationId": token.appID,
      "permissions": token.permissions.map(\.name),
      "declinedPermissions": token.declinedPermissions.map(\.name),
      "expiredPermissions": token.expiredPermissions.map(\.name),
      "expiresAt": Int(token.expirationDate.timeIntervalSince1970 * 1000),
      "dataAccessExpiresAt": Int(token.dataAccessExpirationDate.timeIntervalSince1970 * 1000),
    ]
  }

  private func arguments(_ call: FlutterMethodCall) -> [String: Any] {
    (call.arguments as? [String: Any]) ?? [:]
  }

  private func required<T>(_ call: FlutterMethodCall, _ key: String) throws -> T {
    guard let value = arguments(call)[key] as? T else {
      throw MetaNativeError.invalidArgument("Missing or invalid argument: \(key)")
    }
    return value
  }

  private func flutterError(_ error: Error, code: String = "native_error") -> FlutterError {
    FlutterError(
      code: code,
      message: error.localizedDescription,
      details: ["type": String(describing: type(of: error))]
    )
  }

  public func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [AnyHashable: Any] = [:]
  ) -> Bool {
    var typedOptions: [UIApplication.LaunchOptionsKey: Any] = [:]
    for (key, value) in launchOptions {
      if let typedKey = key as? UIApplication.LaunchOptionsKey {
        typedOptions[typedKey] = value
      }
    }
    return ApplicationDelegate.shared.application(
      application,
      didFinishLaunchingWithOptions: typedOptions
    )
  }

  public func application(
    _ application: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    ApplicationDelegate.shared.application(application, open: url, options: options)
  }

  @available(iOS 13.0, *)
  public func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    guard let context = URLContexts.first else { return }
    var options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    if let sourceApplication = context.options.sourceApplication {
      options[.sourceApplication] = sourceApplication
    }
    if let annotation = context.options.annotation {
      options[.annotation] = annotation
    }
    ApplicationDelegate.shared.application(
      UIApplication.shared,
      open: context.url,
      options: options
    )
  }
}

private enum MetaNativeError: LocalizedError {
  case invalidArgument(String)

  var errorDescription: String? {
    switch self {
    case .invalidArgument(let message): return message
    }
  }
}
