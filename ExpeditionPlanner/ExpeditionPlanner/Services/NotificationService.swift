import Foundation
import UserNotifications
import SwiftData
import OSLog

private let logger = Logger(subsystem: "com.chaki.app", category: "Notifications")

/// Singleton service wrapping UNUserNotificationCenter.
/// Requests authorization, schedules/cancels notifications, and manages badge count.
@MainActor
final class NotificationService: ObservableObject {

    static let shared = NotificationService()

    // MARK: - Published State

    @Published private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined

    // MARK: - Constants

    /// iOS limits apps to 64 scheduled local notifications
    private static let maxScheduledNotifications = 64

    // MARK: - Init

    private init() {
        Task {
            await checkAuthorizationStatus()
        }
    }

    // MARK: - Authorization

    /// Request notification authorization. Returns true if granted.
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound]
            )
            await checkAuthorizationStatus()
            logger.info("Notification authorization: \(granted ? "granted" : "denied")")
            return granted
        } catch {
            logger.error("Notification authorization error: \(error.localizedDescription)")
            return false
        }
    }

    /// Check current authorization status
    func checkAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    var isAuthorized: Bool {
        authorizationStatus == .authorized || authorizationStatus == .provisional
    }

    // MARK: - Scheduling

    /// Remove all pending notifications and reschedule from scratch.
    /// Caps at 64 notifications (iOS limit), prioritized by urgency (earliest first).
    func scheduleAllNotifications(for expeditions: [Expedition]) async {
        guard isAuthorized else {
            logger.info("Skipping notification scheduling — not authorized")
            return
        }

        let settings = readSettings()
        let reminders = NotificationScheduler.computeAllReminders(
            for: expeditions,
            settings: settings
        )

        // Remove all existing scheduled notifications
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()

        // Schedule up to the iOS limit, already sorted by urgency
        let toSchedule = Array(reminders.prefix(Self.maxScheduledNotifications))
        var scheduled = 0

        for reminder in toSchedule {
            let content = UNMutableNotificationContent()
            content.title = reminder.title
            content.body = reminder.body
            content.sound = .default
            content.categoryIdentifier = reminder.category.rawValue

            let triggerComponents = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: reminder.triggerDate
            )
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)

            let request = UNNotificationRequest(
                identifier: reminder.identifier,
                content: content,
                trigger: trigger
            )

            do {
                try await UNUserNotificationCenter.current().add(request)
                scheduled += 1
            } catch {
                logger.error("Failed to schedule notification \(reminder.identifier): \(error.localizedDescription)")
            }
        }

        logger.info("Scheduled \(scheduled) of \(reminders.count) notifications")
    }

    /// Update the app badge count based on overdue items
    func updateBadgeCount(for expeditions: [Expedition]) async {
        guard isAuthorized else { return }

        var overdueCount = 0

        for expedition in expeditions {
            // Overdue permits
            if let permits = expedition.permits {
                overdueCount += permits.filter { permit in
                    guard let deadline = permit.applicationDeadline else { return false }
                    return deadline < Date() && permit.status != .obtained && permit.status != .approved
                }.count
            }

            // Expired documents
            if let docs = expedition.travelDocuments {
                overdueCount += docs.filter { $0.isExpired }.count
            }

            // Overdue checklist items
            if let items = expedition.checklistItems {
                overdueCount += items.filter { $0.isOverdue(expeditionStartDate: expedition.startDate) }.count
            }

            // Expired insurance
            if let policies = expedition.insurancePolicies {
                overdueCount += policies.filter { $0.isExpired }.count
            }
        }

        do {
            try await UNUserNotificationCenter.current().setBadgeCount(overdueCount)
        } catch {
            logger.error("Failed to set badge count: \(error.localizedDescription)")
        }
    }

    // MARK: - Settings Reader

    private func readSettings() -> NotificationScheduler.Settings {
        NotificationScheduler.Settings(
            permitDeadlineNotifications: UserDefaults.standard.object(
                forKey: "permitDeadlineNotifications"
            ) as? Bool ?? true,
            departureReminderNotifications: UserDefaults.standard.object(
                forKey: "departureReminderNotifications"
            ) as? Bool ?? true,
            gearChecklistReminders: UserDefaults.standard.object(
                forKey: "gearChecklistReminders"
            ) as? Bool ?? true,
            budgetAlertNotifications: UserDefaults.standard.object(
                forKey: "budgetAlertNotifications"
            ) as? Bool ?? false,
            reminderDaysBefore: UserDefaults.standard.object(
                forKey: "reminderDaysBefore"
            ) as? Int ?? 7
        )
    }
}
