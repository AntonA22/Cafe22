import UIKit
import FirebaseMessaging
import YandexMapsMobile
import FirebaseCore
import UserNotifications

struct NotificationToggleResult {
    let isEnabled: Bool
    let needsSettings: Bool
}

final class NotificationSettingsService {
    static let shared = NotificationSettingsService()

    private let key = "notifications_enabled"

    private init() {}

    var isEnabled: Bool {
        UserDefaults.standard.object(forKey: key) as? Bool ?? true
    }

    func configureOnLaunch(application: UIApplication) {
        guard isEnabled else {
            DispatchQueue.main.async {
                application.unregisterForRemoteNotifications()
                application.applicationIconBadgeNumber = 0
            }
            Messaging.messaging().isAutoInitEnabled = false
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            UNUserNotificationCenter.current().removeAllDeliveredNotifications()
            return
        }

        Messaging.messaging().isAutoInitEnabled = true

        UNUserNotificationCenter.current().getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                DispatchQueue.main.async {
                    application.registerForRemoteNotifications()
                }
            case .notDetermined:
                UNUserNotificationCenter.current().requestAuthorization(
                    options: [.alert, .badge, .sound]
                ) { granted, _ in
                    guard granted else { return }
                    DispatchQueue.main.async {
                        application.registerForRemoteNotifications()
                    }
                }
            case .denied:
                break
            @unknown default:
                break
            }
        }
    }

    func refreshEnabledState() async -> Bool {
        guard isEnabled else { return false }

        let settings = await notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined, .denied:
            return false
        @unknown default:
            return false
        }
    }

    @MainActor
    func setEnabled(_ enabled: Bool, application: UIApplication = .shared) async -> NotificationToggleResult {
        if !enabled {
            UserDefaults.standard.set(false, forKey: key)
            Messaging.messaging().isAutoInitEnabled = false
            application.unregisterForRemoteNotifications()
            application.applicationIconBadgeNumber = 0
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            UNUserNotificationCenter.current().removeAllDeliveredNotifications()
            return NotificationToggleResult(isEnabled: false, needsSettings: false)
        }

        let settings = await notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            UserDefaults.standard.set(true, forKey: key)
            Messaging.messaging().isAutoInitEnabled = true
            application.registerForRemoteNotifications()
            return NotificationToggleResult(isEnabled: true, needsSettings: false)
        case .notDetermined:
            let granted = await requestAuthorization()
            UserDefaults.standard.set(granted, forKey: key)
            Messaging.messaging().isAutoInitEnabled = granted
            if granted {
                application.registerForRemoteNotifications()
            }
            return NotificationToggleResult(isEnabled: granted, needsSettings: !granted)
        case .denied:
            UserDefaults.standard.set(false, forKey: key)
            return NotificationToggleResult(isEnabled: false, needsSettings: true)
        @unknown default:
            UserDefaults.standard.set(false, forKey: key)
            return NotificationToggleResult(isEnabled: false, needsSettings: true)
        }
    }

    private func notificationSettings() async -> UNNotificationSettings {
        await withCheckedContinuation { continuation in
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                continuation.resume(returning: settings)
            }
        }
    }

    private func requestAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound]
            ) { granted, _ in
                continuation.resume(returning: granted)
            }
        }
    }
}

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        print("Токен при запуске: \(AuthService.shared.currentToken() != nil ? "есть \(String(describing: AuthService.shared.currentToken()))" : "нет")")

        YMKMapKit.setApiKey("b8b5ec7d-168e-47e7-9a35-ae1bc643aa5c")
        YMKMapKit.sharedInstance()

        FirebaseApp.configure()
        Messaging.messaging().delegate = self          // ← делегат до регистрации

        UNUserNotificationCenter.current().delegate = self
        NotificationSettingsService.shared.configureOnLaunch(application: application)

        return true
    }

    // APNS вернул токен → передаём в FCM
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Messaging.messaging().apnsToken = deviceToken
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("APNS registration failed: \(error)")
    }

    // MARK: UISceneSession Lifecycle

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(
        _ application: UIApplication,
        didDiscardSceneSessions sceneSessions: Set<UISceneSession>
    ) {}
}

// MARK: - MessagingDelegate
extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken else { return }
        print("FCM Token: \(fcmToken)")
        guard AuthService.shared.currentToken() != nil else { return }
        Task {
            try? await AuthService.shared.sendFcmToken(fcmToken)
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension AppDelegate: UNUserNotificationCenterDelegate {
    // Показывать уведомление когда приложение на переднем плане
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        guard NotificationSettingsService.shared.isEnabled else {
            completionHandler([])
            return
        }
        completionHandler([.banner, .sound, .badge])
    }
}
