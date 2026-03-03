import XCTest
@testable import Chaki

final class NotificationSchedulerTests: XCTestCase {

    // MARK: - Helpers

    private let now = Date()

    private var allEnabledSettings: NotificationScheduler.Settings {
        NotificationScheduler.Settings(
            permitDeadlineNotifications: true,
            departureReminderNotifications: true,
            gearChecklistReminders: true,
            budgetAlertNotifications: false,
            reminderDaysBefore: 7
        )
    }

    private var allDisabledSettings: NotificationScheduler.Settings {
        NotificationScheduler.Settings(
            permitDeadlineNotifications: false,
            departureReminderNotifications: false,
            gearChecklistReminders: false,
            budgetAlertNotifications: false,
            reminderDaysBefore: 7
        )
    }

    private func futureDate(days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: now)!
    }

    private func pastDate(days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -days, to: now)!
    }

    // MARK: - Permit Deadline Reminders

    func testPermitDeadlineReminder() {
        let expedition = Expedition(name: "Test")
        let permit = Permit(name: "Wilderness Permit")
        permit.applicationDeadline = futureDate(days: 30)
        expedition.permits = [permit]

        let reminders = NotificationScheduler.computeReminders(for: expedition, settings: allEnabledSettings, now: now)

        let permitReminders = reminders.filter { $0.identifier.hasPrefix("permit.deadline.") }
        XCTAssertEqual(permitReminders.count, 1)
        XCTAssertEqual(permitReminders[0].title, "Permit Deadline")
        XCTAssertTrue(permitReminders[0].body.contains("Wilderness Permit"))
    }

    func testPermitExpiryReminder() {
        let expedition = Expedition(name: "Test")
        let permit = Permit(name: "Entry Permit")
        permit.expirationDate = futureDate(days: 30)
        expedition.permits = [permit]

        let reminders = NotificationScheduler.computeReminders(for: expedition, settings: allEnabledSettings, now: now)

        let expiryReminders = reminders.filter { $0.identifier.hasPrefix("permit.expiry.") }
        XCTAssertEqual(expiryReminders.count, 1)
        XCTAssertEqual(expiryReminders[0].title, "Permit Expiring")
    }

    func testPastPermitDeadlineNotScheduled() {
        let expedition = Expedition(name: "Test")
        let permit = Permit(name: "Old Permit")
        permit.applicationDeadline = pastDate(days: 10)
        expedition.permits = [permit]

        let reminders = NotificationScheduler.computeReminders(for: expedition, settings: allEnabledSettings, now: now)
        let permitReminders = reminders.filter { $0.identifier.hasPrefix("permit.deadline.") }
        XCTAssertTrue(permitReminders.isEmpty)
    }

    func testPermitRemindersDisabledWhenToggleOff() {
        let expedition = Expedition(name: "Test")
        let permit = Permit(name: "Permit")
        permit.applicationDeadline = futureDate(days: 30)
        expedition.permits = [permit]

        var settings = allEnabledSettings
        settings = NotificationScheduler.Settings(
            permitDeadlineNotifications: false,
            departureReminderNotifications: true,
            gearChecklistReminders: true,
            budgetAlertNotifications: false,
            reminderDaysBefore: 7
        )

        let reminders = NotificationScheduler.computeReminders(for: expedition, settings: settings, now: now)
        XCTAssertTrue(reminders.filter { $0.category == .permitDeadline }.isEmpty)
    }

    // MARK: - Expedition Departure Reminders

    func testExpeditionDepartureReminder() {
        let expedition = Expedition(name: "Alaska Trip")
        expedition.startDate = futureDate(days: 30)

        let reminders = NotificationScheduler.computeReminders(for: expedition, settings: allEnabledSettings, now: now)

        let departureReminders = reminders.filter { $0.identifier.hasPrefix("expedition.departure.") }
        XCTAssertEqual(departureReminders.count, 1)
        XCTAssertTrue(departureReminders[0].body.contains("Alaska Trip"))
    }

    func testNoExpeditionDepartureReminderWithoutStartDate() {
        let expedition = Expedition(name: "Test")

        let reminders = NotificationScheduler.computeReminders(for: expedition, settings: allEnabledSettings, now: now)
        let departureReminders = reminders.filter { $0.identifier.hasPrefix("expedition.departure.") }
        XCTAssertTrue(departureReminders.isEmpty)
    }

    // MARK: - Transport Departure Reminders

    func testTransportDepartureReminder() {
        let expedition = Expedition(name: "Test")
        let leg = TransportLeg(transportType: .flight, carrier: "Alaska Air")
        leg.departureTime = futureDate(days: 20)
        expedition.transportLegs = [leg]

        let reminders = NotificationScheduler.computeReminders(for: expedition, settings: allEnabledSettings, now: now)

        let transportReminders = reminders.filter { $0.identifier.hasPrefix("transport.departure.") }
        XCTAssertEqual(transportReminders.count, 1)
        XCTAssertEqual(transportReminders[0].title, "Transport Departure")
    }

    func testDepartureRemindersDisabledWhenToggleOff() {
        let expedition = Expedition(name: "Test")
        expedition.startDate = futureDate(days: 30)

        let settings = NotificationScheduler.Settings(
            permitDeadlineNotifications: true,
            departureReminderNotifications: false,
            gearChecklistReminders: true,
            budgetAlertNotifications: false,
            reminderDaysBefore: 7
        )

        let reminders = NotificationScheduler.computeReminders(for: expedition, settings: settings, now: now)
        XCTAssertTrue(reminders.filter { $0.category == .departureReminder }.isEmpty)
    }

    // MARK: - Accommodation Check-In Reminders

    func testAccommodationCheckInReminder() {
        let expedition = Expedition(name: "Test")
        let accommodation = Accommodation(name: "Mountain Lodge")
        accommodation.checkInDate = futureDate(days: 14)
        expedition.accommodations = [accommodation]

        let reminders = NotificationScheduler.computeReminders(for: expedition, settings: allEnabledSettings, now: now)

        let checkInReminders = reminders.filter { $0.identifier.hasPrefix("accommodation.checkin.") }
        XCTAssertEqual(checkInReminders.count, 1)
        XCTAssertTrue(checkInReminders[0].body.contains("Mountain Lodge"))
    }

    // MARK: - Document Expiry Reminders

    func testDocumentExpiryReminder() {
        let expedition = Expedition(name: "Test")
        let document = TravelDocument(documentType: .passport, holderName: "Alice")
        document.expiryDate = futureDate(days: 60)
        expedition.travelDocuments = [document]

        let reminders = NotificationScheduler.computeReminders(for: expedition, settings: allEnabledSettings, now: now)

        let docReminders = reminders.filter { $0.identifier.hasPrefix("document.expiry.") }
        XCTAssertEqual(docReminders.count, 1)
        XCTAssertEqual(docReminders[0].title, "Document Expiring")
    }

    // MARK: - Insurance Expiry Reminders

    func testInsuranceExpiryReminder() {
        let expedition = Expedition(name: "Test")
        let policy = InsurancePolicy(provider: "World Nomads")
        policy.coverageEndDate = futureDate(days: 45)
        expedition.insurancePolicies = [policy]

        let reminders = NotificationScheduler.computeReminders(for: expedition, settings: allEnabledSettings, now: now)

        let insuranceReminders = reminders.filter { $0.identifier.hasPrefix("insurance.expiry.") }
        XCTAssertEqual(insuranceReminders.count, 1)
        XCTAssertTrue(insuranceReminders[0].body.contains("World Nomads"))
    }

    // MARK: - Device Subscription Reminders

    func testDeviceSubscriptionReminder() {
        let expedition = Expedition(name: "Test")
        let device = SatelliteDevice(name: "inReach Mini")
        device.subscriptionExpiry = futureDate(days: 20)
        expedition.satelliteDevices = [device]

        let reminders = NotificationScheduler.computeReminders(for: expedition, settings: allEnabledSettings, now: now)

        let deviceReminders = reminders.filter { $0.identifier.hasPrefix("device.subscription.") }
        XCTAssertEqual(deviceReminders.count, 1)
    }

    func testDeviceReturnReminder() {
        let expedition = Expedition(name: "Test")
        let device = SatelliteDevice(name: "Rental Sat Phone")
        device.isRented = true
        device.returnDate = futureDate(days: 14)
        expedition.satelliteDevices = [device]

        let reminders = NotificationScheduler.computeReminders(for: expedition, settings: allEnabledSettings, now: now)

        let returnReminders = reminders.filter { $0.identifier.hasPrefix("device.return.") }
        XCTAssertEqual(returnReminders.count, 1)
        XCTAssertEqual(returnReminders[0].title, "Device Return")
    }

    // MARK: - Checklist Reminders

    func testChecklistDueReminder() {
        let expedition = Expedition(name: "Test")
        let item = ChecklistItem(title: "Buy bear spray")
        item.dueDate = futureDate(days: 14)
        expedition.checklistItems = [item]

        let reminders = NotificationScheduler.computeReminders(for: expedition, settings: allEnabledSettings, now: now)

        let checklistReminders = reminders.filter { $0.identifier.hasPrefix("checklist.due.") }
        XCTAssertEqual(checklistReminders.count, 1)
        XCTAssertTrue(checklistReminders[0].body.contains("Buy bear spray"))
    }

    func testCompletedChecklistItemNotScheduled() {
        let expedition = Expedition(name: "Test")
        let item = ChecklistItem(title: "Done task", status: .completed)
        item.dueDate = futureDate(days: 14)
        expedition.checklistItems = [item]

        let reminders = NotificationScheduler.computeReminders(for: expedition, settings: allEnabledSettings, now: now)
        let checklistReminders = reminders.filter { $0.identifier.hasPrefix("checklist.due.") }
        XCTAssertTrue(checklistReminders.isEmpty)
    }

    func testChecklistRemindersDisabledWhenToggleOff() {
        let expedition = Expedition(name: "Test")
        let item = ChecklistItem(title: "Task")
        item.dueDate = futureDate(days: 14)
        expedition.checklistItems = [item]

        let settings = NotificationScheduler.Settings(
            permitDeadlineNotifications: true,
            departureReminderNotifications: true,
            gearChecklistReminders: false,
            budgetAlertNotifications: false,
            reminderDaysBefore: 7
        )

        let reminders = NotificationScheduler.computeReminders(for: expedition, settings: settings, now: now)
        XCTAssertTrue(reminders.filter { $0.category == .gearChecklist }.isEmpty)
    }

    // MARK: - Multi-Expedition

    func testComputeAllRemindersMultipleExpeditions() {
        let expedition1 = Expedition(name: "Trip 1")
        expedition1.startDate = futureDate(days: 30)

        let expedition2 = Expedition(name: "Trip 2")
        expedition2.startDate = futureDate(days: 15)

        let reminders = NotificationScheduler.computeAllReminders(
            for: [expedition1, expedition2],
            settings: allEnabledSettings,
            now: now
        )

        XCTAssertEqual(reminders.count, 2)
        // Should be sorted by trigger date (earliest first)
        XCTAssertTrue(reminders[0].triggerDate <= reminders[1].triggerDate)
    }

    // MARK: - Reminder Days Before

    func testReminderDaysBeforeAffectsTriggerDate() {
        let expedition = Expedition(name: "Test")
        expedition.startDate = futureDate(days: 30)

        let settings14 = NotificationScheduler.Settings(
            permitDeadlineNotifications: false,
            departureReminderNotifications: true,
            gearChecklistReminders: false,
            budgetAlertNotifications: false,
            reminderDaysBefore: 14
        )

        let reminders = NotificationScheduler.computeReminders(for: expedition, settings: settings14, now: now)
        let departure = reminders.first { $0.identifier.hasPrefix("expedition.departure.") }
        XCTAssertNotNil(departure)

        // Trigger should be ~16 days from now (30 - 14 = 16)
        let expectedTrigger = futureDate(days: 16)
        let diff = abs(departure!.triggerDate.timeIntervalSince(expectedTrigger))
        XCTAssertLessThan(diff, 60) // Within 1 minute tolerance
    }

    // MARK: - All Disabled

    func testAllDisabledReturnsNoReminders() {
        let expedition = Expedition(name: "Test")
        expedition.startDate = futureDate(days: 30)

        let permit = Permit(name: "Permit")
        permit.applicationDeadline = futureDate(days: 20)
        expedition.permits = [permit]

        let item = ChecklistItem(title: "Task")
        item.dueDate = futureDate(days: 14)
        expedition.checklistItems = [item]

        let reminders = NotificationScheduler.computeReminders(
            for: expedition, settings: allDisabledSettings, now: now
        )
        XCTAssertTrue(reminders.isEmpty)
    }

    // MARK: - Deterministic Identifiers

    func testIdentifiersContainModelUUID() {
        let expedition = Expedition(name: "Test")
        let permit = Permit(name: "Test Permit")
        permit.applicationDeadline = futureDate(days: 30)
        expedition.permits = [permit]

        let reminders = NotificationScheduler.computeReminders(for: expedition, settings: allEnabledSettings, now: now)
        let permitReminder = reminders.first { $0.identifier.hasPrefix("permit.deadline.") }
        XCTAssertNotNil(permitReminder)
        XCTAssertTrue(permitReminder!.identifier.contains(permit.id.uuidString))
    }
}
