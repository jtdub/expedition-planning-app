import Foundation
import PDFKit
import UIKit

// swiftlint:disable file_length

/// Service for exporting expedition data to PDF format
final class PDFExportService {

    // MARK: - PDF Generation

    /// Generate a complete expedition guidebook PDF
    static func generateGuidebook(for expedition: Expedition) -> Data? {
        let pdfMetaData = [
            kCGPDFContextCreator: "Expedition Planner",
            kCGPDFContextAuthor: "Expedition Planner App",
            kCGPDFContextTitle: "\(expedition.name) - Expedition Guidebook"
        ]

        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]

        let pageWidth = 8.5 * 72.0 // Letter size in points
        let pageHeight = 11.0 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let margin: CGFloat = 50

        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        let data = renderer.pdfData { context in
            // Title Page
            context.beginPage()
            drawTitlePage(expedition: expedition, in: pageRect, margin: margin)

            // Overview Page
            context.beginPage()
            drawOverviewPage(expedition: expedition, in: pageRect, margin: margin)

            // Itinerary Pages
            if let itinerary = expedition.itinerary, !itinerary.isEmpty {
                context.beginPage()
                var yOffset = drawSectionHeader("Itinerary", in: pageRect, margin: margin)
                yOffset = drawItinerary(
                    expedition.sortedItinerary,
                    startY: yOffset,
                    in: pageRect,
                    margin: margin,
                    context: context
                )
            }

            // Participants Page
            if let participants = expedition.participants, !participants.isEmpty {
                context.beginPage()
                var yOffset = drawSectionHeader("Participants", in: pageRect, margin: margin)
                yOffset = drawParticipants(participants, startY: yOffset, in: pageRect, margin: margin)
            }

            // Contacts Page
            if let contacts = expedition.contacts, !contacts.isEmpty {
                context.beginPage()
                var yOffset = drawSectionHeader("Contacts", in: pageRect, margin: margin)
                yOffset = drawContacts(contacts, startY: yOffset, in: pageRect, margin: margin)
            }

            // Budget Summary Page
            if let budgetItems = expedition.budgetItems, !budgetItems.isEmpty {
                context.beginPage()
                var yOffset = drawSectionHeader("Budget", in: pageRect, margin: margin)
                yOffset = drawBudget(budgetItems, startY: yOffset, in: pageRect, margin: margin)
            }

            // Safety Information Page
            context.beginPage()
            drawSafetyPage(expedition: expedition, in: pageRect, margin: margin)
        }

        return data
    }

    // MARK: - Title Page

    private static func drawTitlePage(expedition: Expedition, in rect: CGRect, margin: CGFloat) {
        let titleFont = UIFont.systemFont(ofSize: 36, weight: .bold)
        let subtitleFont = UIFont.systemFont(ofSize: 18, weight: .medium)
        let bodyFont = UIFont.systemFont(ofSize: 14)

        let centerX = rect.width / 2

        // Title
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: UIColor.black
        ]
        let titleString = expedition.name
        let titleSize = titleString.size(withAttributes: titleAttributes)
        titleString.draw(
            at: CGPoint(x: centerX - titleSize.width / 2, y: 150),
            withAttributes: titleAttributes
        )

        // Subtitle
        let subtitleAttributes: [NSAttributedString.Key: Any] = [
            .font: subtitleFont,
            .foregroundColor: UIColor.darkGray
        ]
        let subtitleString = "Expedition Guidebook"
        let subtitleSize = subtitleString.size(withAttributes: subtitleAttributes)
        subtitleString.draw(
            at: CGPoint(x: centerX - subtitleSize.width / 2, y: 200),
            withAttributes: subtitleAttributes
        )

        // Location
        if !expedition.location.isEmpty {
            let locationAttributes: [NSAttributedString.Key: Any] = [
                .font: bodyFont,
                .foregroundColor: UIColor.gray
            ]
            let locationString = expedition.location
            let locationSize = locationString.size(withAttributes: locationAttributes)
            locationString.draw(
                at: CGPoint(x: centerX - locationSize.width / 2, y: 250),
                withAttributes: locationAttributes
            )
        }

        // Dates
        if let startDate = expedition.startDate, let endDate = expedition.endDate {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .long
            let dateString = "\(dateFormatter.string(from: startDate)) - \(dateFormatter.string(from: endDate))"
            let dateAttributes: [NSAttributedString.Key: Any] = [
                .font: bodyFont,
                .foregroundColor: UIColor.gray
            ]
            let dateSize = dateString.size(withAttributes: dateAttributes)
            dateString.draw(
                at: CGPoint(x: centerX - dateSize.width / 2, y: 280),
                withAttributes: dateAttributes
            )
        }

        // Footer
        let footerFont = UIFont.systemFont(ofSize: 10)
        let footerAttributes: [NSAttributedString.Key: Any] = [
            .font: footerFont,
            .foregroundColor: UIColor.lightGray
        ]
        let footerString = "Generated by Expedition Planner on \(Date().formatted(date: .long, time: .omitted))"
        let footerSize = footerString.size(withAttributes: footerAttributes)
        footerString.draw(
            at: CGPoint(x: centerX - footerSize.width / 2, y: rect.height - 100),
            withAttributes: footerAttributes
        )
    }

    // MARK: - Overview Page

    private static func drawOverviewPage(expedition: Expedition, in rect: CGRect, margin: CGFloat) {
        var yOffset = drawSectionHeader("Overview", in: rect, margin: margin)

        let bodyFont = UIFont.systemFont(ofSize: 12)
        let labelFont = UIFont.systemFont(ofSize: 12, weight: .semibold)

        let textWidth = rect.width - (margin * 2)

        // Status
        yOffset = drawLabelValue(
            "Status:",
            expedition.status.rawValue,
            at: yOffset,
            margin: margin,
            labelFont: labelFont,
            bodyFont: bodyFont
        )

        // Location
        if !expedition.location.isEmpty {
            yOffset = drawLabelValue(
                "Location:",
                expedition.location,
                at: yOffset,
                margin: margin,
                labelFont: labelFont,
                bodyFont: bodyFont
            )
        }

        // Duration
        if expedition.totalDays > 0 {
            yOffset = drawLabelValue(
                "Duration:",
                "\(expedition.totalDays) days",
                at: yOffset,
                margin: margin,
                labelFont: labelFont,
                bodyFont: bodyFont
            )
        }

        // Participants
        yOffset = drawLabelValue(
            "Participants:",
            "\(expedition.participantCount)",
            at: yOffset,
            margin: margin,
            labelFont: labelFont,
            bodyFont: bodyFont
        )

        // Description
        if !expedition.expeditionDescription.isEmpty {
            yOffset += 20
            let descriptionAttributes: [NSAttributedString.Key: Any] = [
                .font: bodyFont,
                .foregroundColor: UIColor.black
            ]
            let descriptionRect = CGRect(x: margin, y: yOffset, width: textWidth, height: 200)
            expedition.expeditionDescription.draw(in: descriptionRect, withAttributes: descriptionAttributes)
        }
    }

    // MARK: - Section Header

    @discardableResult
    private static func drawSectionHeader(_ title: String, in rect: CGRect, margin: CGFloat) -> CGFloat {
        let headerFont = UIFont.systemFont(ofSize: 24, weight: .bold)
        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: headerFont,
            .foregroundColor: UIColor.black
        ]

        let yOffset: CGFloat = margin
        title.draw(at: CGPoint(x: margin, y: yOffset), withAttributes: headerAttributes)

        // Draw line under header
        let lineY = yOffset + 35
        let path = UIBezierPath()
        path.move(to: CGPoint(x: margin, y: lineY))
        path.addLine(to: CGPoint(x: rect.width - margin, y: lineY))
        UIColor.lightGray.setStroke()
        path.stroke()

        return lineY + 20
    }

    // MARK: - Itinerary

    private static func drawItinerary(
        _ days: [ItineraryDay],
        startY: CGFloat,
        in rect: CGRect,
        margin: CGFloat,
        context: UIGraphicsPDFRendererContext
    ) -> CGFloat {
        var yOffset = startY
        let bodyFont = UIFont.systemFont(ofSize: 11)
        let boldFont = UIFont.systemFont(ofSize: 11, weight: .semibold)
        let lineHeight: CGFloat = 16

        for day in days {
            // Check if we need a new page
            if yOffset > rect.height - 100 {
                context.beginPage()
                yOffset = margin
            }

            // Day header
            let dayTitle = "Day \(day.dayNumber): \(day.location)"
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: boldFont,
                .foregroundColor: UIColor.black
            ]
            dayTitle.draw(at: CGPoint(x: margin, y: yOffset), withAttributes: titleAttributes)
            yOffset += lineHeight + 4

            // Location
            let locations = [day.startLocation, day.endLocation].filter { !$0.isEmpty }.joined(separator: " → ")
            if !locations.isEmpty {
                let locationAttributes: [NSAttributedString.Key: Any] = [
                    .font: bodyFont,
                    .foregroundColor: UIColor.darkGray
                ]
                locations.draw(at: CGPoint(x: margin + 10, y: yOffset), withAttributes: locationAttributes)
                yOffset += lineHeight
            }

            // Description
            if !day.clientDescription.isEmpty {
                let descAttributes: [NSAttributedString.Key: Any] = [
                    .font: bodyFont,
                    .foregroundColor: UIColor.gray
                ]
                let descWidth = rect.width - margin * 2 - 10
                let descRect = CGRect(x: margin + 10, y: yOffset, width: descWidth, height: 60)
                day.clientDescription.draw(in: descRect, withAttributes: descAttributes)
                yOffset += 40
            }

            yOffset += 10
        }

        return yOffset
    }

    // MARK: - Participants

    private static func drawParticipants(
        _ participants: [Participant],
        startY: CGFloat,
        in rect: CGRect,
        margin: CGFloat
    ) -> CGFloat {
        var yOffset = startY
        let bodyFont = UIFont.systemFont(ofSize: 11)
        let boldFont = UIFont.systemFont(ofSize: 11, weight: .semibold)
        let lineHeight: CGFloat = 16

        for participant in participants.sorted(by: { $0.name < $1.name }) {
            let nameAttributes: [NSAttributedString.Key: Any] = [
                .font: boldFont,
                .foregroundColor: UIColor.black
            ]
            participant.name.draw(at: CGPoint(x: margin, y: yOffset), withAttributes: nameAttributes)

            let roleAttributes: [NSAttributedString.Key: Any] = [
                .font: bodyFont,
                .foregroundColor: UIColor.gray
            ]
            let roleText = " - \(participant.role.rawValue)"
            roleText.draw(at: CGPoint(x: margin + 150, y: yOffset), withAttributes: roleAttributes)

            yOffset += lineHeight

            if !participant.email.isEmpty {
                let emailAttributes: [NSAttributedString.Key: Any] = [
                    .font: bodyFont,
                    .foregroundColor: UIColor.darkGray
                ]
                participant.email.draw(at: CGPoint(x: margin + 10, y: yOffset), withAttributes: emailAttributes)
                yOffset += lineHeight
            }

            yOffset += 5
        }

        return yOffset
    }

    // MARK: - Contacts

    private static func drawContacts(
        _ contacts: [Contact],
        startY: CGFloat,
        in rect: CGRect,
        margin: CGFloat
    ) -> CGFloat {
        var yOffset = startY
        let bodyFont = UIFont.systemFont(ofSize: 11)
        let boldFont = UIFont.systemFont(ofSize: 11, weight: .semibold)
        let lineHeight: CGFloat = 16

        // Emergency contacts first
        let emergencyContacts = contacts
            .filter { $0.isEmergencyContact }
            .sorted { ($0.emergencyPriority ?? 999) < ($1.emergencyPriority ?? 999) }
        if !emergencyContacts.isEmpty {
            let emergencyHeader: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14, weight: .bold),
                .foregroundColor: UIColor.red
            ]
            "EMERGENCY CONTACTS".draw(at: CGPoint(x: margin, y: yOffset), withAttributes: emergencyHeader)
            yOffset += 20

            for contact in emergencyContacts {
                yOffset = drawContact(
                    contact,
                    at: yOffset,
                    margin: margin,
                    bodyFont: bodyFont,
                    boldFont: boldFont,
                    lineHeight: lineHeight
                )
            }
            yOffset += 10
        }

        // Other contacts
        let otherContacts = contacts.filter { !$0.isEmergencyContact }
        for contact in otherContacts {
            yOffset = drawContact(
                contact,
                at: yOffset,
                margin: margin,
                bodyFont: bodyFont,
                boldFont: boldFont,
                lineHeight: lineHeight
            )
        }

        return yOffset
    }

    private static func drawContact(
        _ contact: Contact,
        at yOffset: CGFloat,
        margin: CGFloat,
        bodyFont: UIFont,
        boldFont: UIFont,
        lineHeight: CGFloat
    ) -> CGFloat {
        var y = yOffset

        let nameAttributes: [NSAttributedString.Key: Any] = [
            .font: boldFont,
            .foregroundColor: UIColor.black
        ]
        contact.name.draw(at: CGPoint(x: margin, y: y), withAttributes: nameAttributes)
        y += lineHeight

        let detailAttributes: [NSAttributedString.Key: Any] = [
            .font: bodyFont,
            .foregroundColor: UIColor.darkGray
        ]

        if let phone = contact.primaryPhone {
            phone.draw(at: CGPoint(x: margin + 10, y: y), withAttributes: detailAttributes)
            y += lineHeight
        }

        if let email = contact.email {
            email.draw(at: CGPoint(x: margin + 10, y: y), withAttributes: detailAttributes)
            y += lineHeight
        }

        y += 5
        return y
    }

    // MARK: - Budget

    private static func drawBudget(
        _ items: [BudgetItem],
        startY: CGFloat,
        in rect: CGRect,
        margin: CGFloat
    ) -> CGFloat {
        var yOffset = startY
        let bodyFont = UIFont.systemFont(ofSize: 11)
        let boldFont = UIFont.systemFont(ofSize: 11, weight: .semibold)
        let lineHeight: CGFloat = 16

        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"

        // Summary
        let totalEstimated = items.reduce(Decimal(0)) { $0 + $1.estimatedAmount }
        let totalActual = items.compactMap { $0.actualAmount }.reduce(Decimal(0), +)

        let summaryAttributes: [NSAttributedString.Key: Any] = [
            .font: boldFont,
            .foregroundColor: UIColor.black
        ]

        let estimatedString = "Total Estimated: \(formatter.string(from: totalEstimated as NSDecimalNumber) ?? "")"
        estimatedString.draw(at: CGPoint(x: margin, y: yOffset), withAttributes: summaryAttributes)
        yOffset += lineHeight

        let actualString = "Total Actual: \(formatter.string(from: totalActual as NSDecimalNumber) ?? "")"
        actualString.draw(at: CGPoint(x: margin, y: yOffset), withAttributes: summaryAttributes)
        yOffset += lineHeight * 2

        // Items by category
        let grouped = Dictionary(grouping: items) { $0.category }
        for category in BudgetCategory.allCases {
            guard let categoryItems = grouped[category], !categoryItems.isEmpty else { continue }

            let categoryHeader: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12, weight: .semibold),
                .foregroundColor: UIColor.darkGray
            ]
            category.rawValue.draw(at: CGPoint(x: margin, y: yOffset), withAttributes: categoryHeader)
            yOffset += lineHeight + 2

            for item in categoryItems {
                let itemAttributes: [NSAttributedString.Key: Any] = [
                    .font: bodyFont,
                    .foregroundColor: UIColor.black
                ]
                let amountString = formatter.string(from: item.estimatedAmount as NSDecimalNumber) ?? ""
                let itemText = "  \(item.name): \(amountString)"
                itemText.draw(at: CGPoint(x: margin, y: yOffset), withAttributes: itemAttributes)
                yOffset += lineHeight
            }

            yOffset += 5
        }

        return yOffset
    }

    // MARK: - Safety Page

    private static func drawSafetyPage(expedition: Expedition, in rect: CGRect, margin: CGFloat) {
        var yOffset = drawSectionHeader("Safety Information", in: rect, margin: margin)

        let bodyFont = UIFont.systemFont(ofSize: 11)
        let boldFont = UIFont.systemFont(ofSize: 11, weight: .semibold)
        let lineHeight: CGFloat = 16

        // Insurance
        if let policies = expedition.insurancePolicies, !policies.isEmpty {
            let insuranceHeader: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14, weight: .bold),
                .foregroundColor: UIColor.black
            ]
            "Insurance Policies".draw(at: CGPoint(x: margin, y: yOffset), withAttributes: insuranceHeader)
            yOffset += 20

            for policy in policies {
                let policyAttributes: [NSAttributedString.Key: Any] = [
                    .font: boldFont,
                    .foregroundColor: UIColor.black
                ]
                let policyName = "\(policy.provider) - \(policy.insuranceType.rawValue)"
                policyName.draw(at: CGPoint(x: margin, y: yOffset), withAttributes: policyAttributes)
                yOffset += lineHeight

                if let phone = policy.emergencyPhone {
                    let phoneAttributes: [NSAttributedString.Key: Any] = [
                        .font: bodyFont,
                        .foregroundColor: UIColor.red
                    ]
                    "Emergency: \(phone)".draw(at: CGPoint(x: margin + 10, y: yOffset), withAttributes: phoneAttributes)
                    yOffset += lineHeight
                }

                yOffset += 5
            }
        }

        // Risk Assessments
        if let risks = expedition.riskAssessments, !risks.isEmpty {
            yOffset += 10
            let riskHeader: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14, weight: .bold),
                .foregroundColor: UIColor.black
            ]
            "Risk Assessments".draw(at: CGPoint(x: margin, y: yOffset), withAttributes: riskHeader)
            yOffset += 20

            for risk in risks {
                let riskAttributes: [NSAttributedString.Key: Any] = [
                    .font: boldFont,
                    .foregroundColor: UIColor.black
                ]
                risk.title.draw(at: CGPoint(x: margin, y: yOffset), withAttributes: riskAttributes)
                yOffset += lineHeight

                if !risk.mitigationStrategy.isEmpty {
                    let mitigationAttributes: [NSAttributedString.Key: Any] = [
                        .font: bodyFont,
                        .foregroundColor: UIColor.darkGray
                    ]
                    let mitigationWidth = rect.width - margin * 2 - 10
                    let mitigationRect = CGRect(
                        x: margin + 10,
                        y: yOffset,
                        width: mitigationWidth,
                        height: 40
                    )
                    risk.mitigationStrategy.draw(in: mitigationRect, withAttributes: mitigationAttributes)
                    yOffset += 30
                }

                yOffset += 5
            }
        }
    }

    // MARK: - Helper Methods

    private static func drawLabelValue(
        _ label: String,
        _ value: String,
        at yOffset: CGFloat,
        margin: CGFloat,
        labelFont: UIFont,
        bodyFont: UIFont
    ) -> CGFloat {
        let labelAttributes: [NSAttributedString.Key: Any] = [
            .font: labelFont,
            .foregroundColor: UIColor.black
        ]
        let valueAttributes: [NSAttributedString.Key: Any] = [
            .font: bodyFont,
            .foregroundColor: UIColor.darkGray
        ]

        label.draw(at: CGPoint(x: margin, y: yOffset), withAttributes: labelAttributes)
        value.draw(at: CGPoint(x: margin + 100, y: yOffset), withAttributes: valueAttributes)

        return yOffset + 20
    }
}
