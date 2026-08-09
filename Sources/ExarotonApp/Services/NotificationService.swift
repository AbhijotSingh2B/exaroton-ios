import UserNotifications
import Foundation

// MARK: - Notification Service

@MainActor
final class NotificationService: ObservableObject {

    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined

    private let center = UNUserNotificationCenter.current()

    // MARK: Permission

    func requestPermission() {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, _ in
            Task { @MainActor [weak self] in
                self?.refreshStatus()
            }
        }
    }

    func refreshStatus() {
        center.getNotificationSettings { [weak self] settings in
            Task { @MainActor [weak self] in
                self?.authorizationStatus = settings.authorizationStatus
            }
        }
    }

    // MARK: Fire Notification

    func notifyServerOnline(serverName: String) {
        deliver(
            id: "server-online-\(serverName)",
            title: "✅ \(serverName) is Online",
            body: "Your Minecraft server is now online and ready to connect.",
            sound: .default
        )
    }

    func notifyServerOffline(serverName: String) {
        deliver(
            id: "server-offline-\(serverName)",
            title: "🔴 \(serverName) Stopped",
            body: "Your Minecraft server has stopped.",
            sound: .default
        )
    }

    func notifyServerCrashed(serverName: String) {
        deliver(
            id: "server-crashed-\(serverName)",
            title: "💥 \(serverName) Crashed",
            body: "Your Minecraft server has crashed. Check the console for details.",
            sound: UNNotificationSound(named: UNNotificationSoundName("basso.aiff"))
        )
    }

    // MARK: Status Change Handler (call from WebSocket onStatusChange)

    func handleStatusChange(serverName: String, from old: ServerStatus, to new: ServerStatus) {
        switch new {
        case .online:
            notifyServerOnline(serverName: serverName)
        case .offline:
            // Only notify offline if it was previously transitioning (stopped intentionally)
            // or was online (unexpected offline without crash)
            if old == .stopping || old == .online {
                notifyServerOffline(serverName: serverName)
            }
        case .crashed:
            notifyServerCrashed(serverName: serverName)
        default:
            break
        }
    }

    // MARK: Private

    private func deliver(id: String, title: String, body: String, sound: UNNotificationSound?) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        if let sound = sound { content.sound = sound }

        let request = UNNotificationRequest(
            identifier: id,
            content: content,
            trigger: nil  // deliver immediately
        )
        center.add(request)
    }
}
