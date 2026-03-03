import Foundation

/// Pure-logic scheduler that computes notification reminders from model data and settings.
/// Deterministic identifiers per model UUID. Testable without UNUserNotificationCenter.
struct NotificationScheduler {

    // MARK: - Types

    struct ScheduledReminder: Equatable {
        let identifier: String
        let title: String
        let body: String
        let triggerDate: Date
        let category: ReminderCategory
    }

    enum ReminderCategory: String {
        case permitDeadline
        case departureReminder
        case gearChecklist
        case budgetAlert
    }

    struct Settings {
        let permitDeadlineNotifications: Bool
        let departureReminderNotifications: Bool
        let gearChecklistReminders: Bool
        let budgetAlertNotifications: Bool
        let reminderDaysBefore: Int
    }

    struct ReminderInput {
        let identifier: String
        let title: String
        let body: String
        let targetDate: Date
        let category: ReminderCategory
    }

    // MARK: - Compute Reminders

    /// Compute all reminders for an expedition based on current settings.
    /// Only returns reminders with trigger dates in the future.
    static func computeReminders(
        for expedition: Expedition,
        settings: Settings,
        now: Date = Date()
    ) -> [ScheduledReminder] {
        var reminders: [ScheduledReminder] = []
        let days = settings.reminderDaysBefore

        if settings.permitDeadlineNotifications {
            reminders += permitReminders(for: expedition, daysBefore: days, now: now)
            reminders += documentExpiryReminders(for: expedition, daysBefore: days, now: now)
            reminders += insuranceExpiryReminders(for: expedition, daysBefore: days, now: now)
            reminders += deviceSubscriptionReminders(for: expedition, daysBefore: days, now: now)
        }

        if settings.departureReminderNotifications {
            reminders += expeditionDepartureReminders(for: expedition, daysBefore: days, now: now)
            reminders += transportDepartureReminders(for: expedition, daysBefore: days, now: now)
            reminders += accommodationCheckInReminders(for: expedition, daysBefore: days, now: now)
        }

        if settings.gearChecklistReminders {
            reminders += checklistReminders(for: expedition, daysBefore: days, now: now)
        }

        return reminders
    }

    /// Compute reminders for multiple expeditions, sorted by urgency (earliest first)
    static func computeAllReminders(
        for expeditions: [Expedition],
        settings: Settings,
        now: Date = Date()
    ) -> [ScheduledReminder] {
        expeditions
            .flatMap { computeReminders(for: $0, settings: settings, now: now) }
            .sorted { $0.triggerDate < $1.triggerDate }
    }

    // MARK: - Permit Reminders

    private static func permitReminders(
        for expedition: Expedition,
        daysBefore: Int,
        now: Date
    ) -> [ScheduledReminder] {
        guard let permits = expedition.permits else { return [] }
        var reminders: [ScheduledReminder] = []

        for permit in permits {
            if let deadline = permit.applicationDeadline {
                let input = ReminderInput(
                    identifier: "\(NotificationIdentifiers.permitDeadline).\(permit.id)",
                    title: "Permit Deadline",
                    body: "\(permit.name) deadline in \(daysBefore) days",
                    targetDate: deadline,
                    category: .permitDeadline
                )
                if let reminder = makeReminder(input: input, daysBefore: daysBefore, now: now) {
                    reminders.append(reminder)
                }
            }

            if let expiry = permit.expirationDate {
                let input = ReminderInput(
                    identifier: "\(NotificationIdentifiers.permitExpiry).\(permit.id)",
                    title: "Permit Expiring",
                    body: "\(permit.name) expires in \(daysBefore) days",
                    targetDate: expiry,
                    category: .permitDeadline
                )
                if let reminder = makeReminder(input: input, daysBefore: daysBefore, now: now) {
                    reminders.append(reminder)
                }
            }
        }

        return reminders
    }

    // MARK: - Document Expiry Reminders

    private static func documentExpiryReminders(
        for expedition: Expedition,
        daysBefore: Int,
        now: Date
    ) -> [ScheduledReminder] {
        guard let documents = expedition.travelDocuments else { return [] }
        var reminders: [ScheduledReminder] = []

        for document in documents {
            if let expiry = document.expiryDate {
                let input = ReminderInput(
                    identifier: "\(NotificationIdentifiers.documentExpiry).\(document.id)",
                    title: "Document Expiring",
                    body: "\(document.displayTitle) expires in \(daysBefore) days",
                    targetDate: expiry,
                    category: .permitDeadline
                )
                if let reminder = makeReminder(input: input, daysBefore: daysBefore, now: now) {
                    reminders.append(reminder)
                }
            }
        }

        return reminders
    }

    // MARK: - Insurance Expiry Reminders

    private static func insuranceExpiryReminders(
        for expedition: Expedition,
        daysBefore: Int,
        now: Date
    ) -> [ScheduledReminder] {
        guard let policies = expedition.insurancePolicies else { return [] }
        var reminders: [ScheduledReminder] = []

        for policy in policies {
            if let expiry = policy.coverageEndDate {
                let input = ReminderInput(
                    identifier: "\(NotificationIdentifiers.insuranceExpiry).\(policy.id)",
                    title: "Insurance Expiring",
                    body: "\(policy.provider) coverage expires in \(daysBefore) days",
                    targetDate: expiry,
                    category: .permitDeadline
                )
                if let reminder = makeReminder(input: input, daysBefore: daysBefore, now: now) {
                    reminders.append(reminder)
                }
            }
        }

        return reminders
    }

    // MARK: - Device Subscription Reminders

    private static func deviceSubscriptionReminders(
        for expedition: Expedition,
        daysBefore: Int,
        now: Date
    ) -> [ScheduledReminder] {
        guard let devices = expedition.satelliteDevices else { return [] }
        var reminders: [ScheduledReminder] = []

        for device in devices {
            if let expiry = device.subscriptionExpiry {
                let input = ReminderInput(
                    identifier: "\(NotificationIdentifiers.deviceSubscription).\(device.id)",
                    title: "Device Subscription",
                    body: "\(device.displayName) subscription expires in \(daysBefore) days",
                    targetDate: expiry,
                    category: .permitDeadline
                )
                if let reminder = makeReminder(input: input, daysBefore: daysBefore, now: now) {
                    reminders.append(reminder)
                }
            }

            if device.isRented, let returnDate = device.returnDate {
                let input = ReminderInput(
                    identifier: "\(NotificationIdentifiers.deviceReturn).\(device.id)",
                    title: "Device Return",
                    body: "\(device.displayName) return due in \(daysBefore) days",
                    targetDate: returnDate,
                    category: .departureReminder
                )
                if let reminder = makeReminder(input: input, daysBefore: daysBefore, now: now) {
                    reminders.append(reminder)
                }
            }
        }

        return reminders
    }

    // MARK: - Expedition Departure Reminders

    private static func expeditionDepartureReminders(
        for expedition: Expedition,
        daysBefore: Int,
        now: Date
    ) -> [ScheduledReminder] {
        guard let startDate = expedition.startDate else { return [] }

        let input = ReminderInput(
            identifier: "\(NotificationIdentifiers.expeditionDeparture).\(expedition.id)",
            title: "Expedition Starting",
            body: "\(expedition.name) starts in \(daysBefore) days",
            targetDate: startDate,
            category: .departureReminder
        )
        if let reminder = makeReminder(input: input, daysBefore: daysBefore, now: now) {
            return [reminder]
        }

        return []
    }

    // MARK: - Transport Departure Reminders

    private static func transportDepartureReminders(
        for expedition: Expedition,
        daysBefore: Int,
        now: Date
    ) -> [ScheduledReminder] {
        guard let legs = expedition.transportLegs else { return [] }
        var reminders: [ScheduledReminder] = []

        for leg in legs {
            if let departure = leg.departureTime {
                let input = ReminderInput(
                    identifier: "\(NotificationIdentifiers.transportDeparture).\(leg.id)",
                    title: "Transport Departure",
                    body: "\(leg.displayTitle) departs in \(daysBefore) days",
                    targetDate: departure,
                    category: .departureReminder
                )
                if let reminder = makeReminder(input: input, daysBefore: daysBefore, now: now) {
                    reminders.append(reminder)
                }
            }
        }

        return reminders
    }

    // MARK: - Accommodation Check-In Reminders

    private static func accommodationCheckInReminders(
        for expedition: Expedition,
        daysBefore: Int,
        now: Date
    ) -> [ScheduledReminder] {
        guard let accommodations = expedition.accommodations else { return [] }
        var reminders: [ScheduledReminder] = []

        for accommodation in accommodations {
            if let checkIn = accommodation.checkInDate {
                let input = ReminderInput(
                    identifier: "\(NotificationIdentifiers.accommodationCheckIn).\(accommodation.id)",
                    title: "Accommodation Check-In",
                    body: "\(accommodation.name) check-in in \(daysBefore) days",
                    targetDate: checkIn,
                    category: .departureReminder
                )
                if let reminder = makeReminder(input: input, daysBefore: daysBefore, now: now) {
                    reminders.append(reminder)
                }
            }
        }

        return reminders
    }

    // MARK: - Checklist Reminders

    private static func checklistReminders(
        for expedition: Expedition,
        daysBefore: Int,
        now: Date
    ) -> [ScheduledReminder] {
        guard let items = expedition.checklistItems else { return [] }
        var reminders: [ScheduledReminder] = []

        for item in items where !item.isComplete && !item.isSkipped {
            if let dueDate = item.computedDueDate(expeditionStartDate: expedition.startDate) {
                let input = ReminderInput(
                    identifier: "\(NotificationIdentifiers.checklistDue).\(item.id)",
                    title: "Task Due",
                    body: "\(item.title) is due in \(daysBefore) days",
                    targetDate: dueDate,
                    category: .gearChecklist
                )
                if let reminder = makeReminder(input: input, daysBefore: daysBefore, now: now) {
                    reminders.append(reminder)
                }
            }
        }

        return reminders
    }

    // MARK: - Helper

    private static func makeReminder(
        input: ReminderInput,
        daysBefore: Int,
        now: Date
    ) -> ScheduledReminder? {
        let triggerDate = Calendar.current.date(
            byAdding: .day, value: -daysBefore, to: input.targetDate
        ) ?? input.targetDate

        guard triggerDate > now else { return nil }

        return ScheduledReminder(
            identifier: input.identifier,
            title: input.title,
            body: input.body,
            triggerDate: triggerDate,
            category: input.category
        )
    }
}
