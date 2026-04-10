import SwiftUI
import SwiftData

enum GearFormMode {
    case create(expedition: Expedition)
    case edit(GearItem)
}

struct GearItemFormView: View {
    @Environment(\.dismiss)
    private var dismiss

    let mode: GearFormMode
    var viewModel: GearViewModel

    @AppStorage("weightUnit")
    private var weightUnit: WeightUnit = .pounds

    // Form state
    @State private var name = ""
    @State private var category: GearCategory = .personalItems
    @State private var priority: GearPriority = .suggested
    @State private var descriptionOrPurpose = ""
    @State private var exampleProduct = ""
    @State private var moreInfoURL = ""
    @State private var selection = ""
    @State private var quantity = 1
    @State private var weightString = ""
    @State private var preHikeComments = ""
    @State private var postHikeComments = ""
    @State private var alternateItem = ""
    @State private var isWeighed = false
    @State private var isInHand = false
    @State private var isPacked = false
    @State private var ownershipType: GearOwnershipType = .personal
    @State private var carriedByID: UUID?

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    private var editingItem: GearItem? {
        if case .edit(let item) = mode { return item }
        return nil
    }

    private var expedition: Expedition {
        switch mode {
        case .create(let expedition):
            return expedition
        case .edit(let item):
            return item.expedition ?? Expedition(name: "Unknown")
        }
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                // Basic Info Section
                basicInfoSection

                // Assignment Section
                assignmentSection

                // Weight Section
                weightSection

                // Product Info Section
                productInfoSection

                // Status Section
                statusSection

                // Comments Section
                commentsSection

                // Category Description
                categoryInfoSection
            }
            .navigationTitle(isEditing ? "Edit Item" : "Add Gear Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Add") {
                        saveItem()
                    }
                    .disabled(!canSave)
                }
            }
            .onAppear {
                if let item = editingItem {
                    loadItem(item)
                }
            }
        }
    }

    // MARK: - Form Sections

    private var basicInfoSection: some View {
        Section {
            TextField("Item Name", text: $name)

            Picker("Category", selection: $category) {
                ForEach(GearCategory.allCases, id: \.self) { cat in
                    Label(cat.rawValue, systemImage: cat.icon)
                        .tag(cat)
                }
            }

            Picker("Priority", selection: $priority) {
                ForEach(GearPriority.allCases, id: \.self) { pri in
                    Label(pri.rawValue, systemImage: pri.icon)
                        .tag(pri)
                }
            }

            Stepper("Quantity: \(quantity)", value: $quantity, in: 1...99)

            TextField("Description/Purpose", text: $descriptionOrPurpose, axis: .vertical)
                .lineLimit(2...4)
        } header: {
            Text("Basic Info")
        }
    }

    private var assignmentSection: some View {
        Section {
            Picker("Ownership", selection: $ownershipType) {
                ForEach(GearOwnershipType.allCases, id: \.self) { type in
                    Label(type.rawValue, systemImage: type.icon).tag(type)
                }
            }

            if ownershipType == .group {
                Picker("Carried By", selection: $carriedByID) {
                    Text("Unassigned").tag(nil as UUID?)
                    ForEach(expedition.participants ?? []) { participant in
                        Text(participant.displayName).tag(participant.id as UUID?)
                    }
                }
            }
        } header: {
            Text("Assignment")
        }
    }

    private var weightUnitLabel: String {
        switch weightUnit {
        case .kilograms:
            return "g"
        case .pounds:
            return "lb"
        case .ounces:
            return "oz"
        }
    }

    private var weightSection: some View {
        Section {
            HStack {
                Text("Weight")
                Spacer()
                TextField(
                    weightUnitLabel,
                    text: $weightString
                )
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
                Text(weightUnitLabel)
                    .foregroundStyle(.secondary)
            }

            if let weight = parseWeight(), quantity > 1 {
                LabeledContent("Total Weight") {
                    Text(formatTotalWeight(weight * Double(quantity)))
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("Weight")
        } footer: {
            Text("Enter weight per item. Total will be calculated for quantity > 1.")
        }
    }

    private var productInfoSection: some View {
        Section {
            TextField("Your Selection", text: $selection)
                .textContentType(.none)

            TextField("Example Product", text: $exampleProduct)

            TextField("More Info URL", text: $moreInfoURL)
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        } header: {
            Text("Product Details")
        } footer: {
            Text("Selection is what you're bringing. Example is a recommended product.")
        }
    }

    private var statusSection: some View {
        Section {
            Toggle(isOn: $isWeighed) {
                Label("Weighed", systemImage: "scalemass")
            }

            Toggle(isOn: $isInHand) {
                Label("In Hand", systemImage: "shippingbox")
            }

            Toggle(isOn: $isPacked) {
                Label("Packed", systemImage: "checkmark.circle")
            }
        } header: {
            Text("Status")
        } footer: {
            statusFooter
        }
    }

    @ViewBuilder private var statusFooter: some View {
        HStack(spacing: 4) {
            Text("Progress:")
            if !isWeighed && !isInHand && !isPacked {
                Text("Not started")
            } else if isWeighed && !isInHand {
                Text("Weighed")
            } else if isInHand && !isPacked {
                Text("Ready to pack")
            } else if isPacked {
                Text("Complete!")
            }
        }
        .font(.caption)
    }

    private var commentsSection: some View {
        Section {
            TextField("Pre-Hike Comments", text: $preHikeComments, axis: .vertical)
                .lineLimit(2...4)

            TextField("Post-Hike Comments", text: $postHikeComments, axis: .vertical)
                .lineLimit(2...4)

            TextField("Alternate Item", text: $alternateItem)
        } header: {
            Text("Notes")
        }
    }

    private var categoryInfoSection: some View {
        Section {
            HStack(spacing: 12) {
                Image(systemName: category.icon)
                    .font(.title2)
                    .foregroundStyle(.secondary)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(category.rawValue)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text(categoryDescription(for: category))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("Category Info")
        }
    }

    // MARK: - Helper Methods

    private func loadItem(_ item: GearItem) {
        name = item.name
        category = item.category
        priority = item.priority
        descriptionOrPurpose = item.descriptionOrPurpose
        exampleProduct = item.exampleProduct
        moreInfoURL = item.moreInfoURL ?? ""
        selection = item.selection
        quantity = item.quantity
        if let grams = item.weightGrams {
            switch weightUnit {
            case .kilograms:
                weightString = "\(Int(grams))"
            case .pounds:
                let lbs = grams / 453.592
                weightString = String(format: "%.1f", lbs)
            case .ounces:
                let oz = grams / 28.3495
                weightString = String(format: "%.1f", oz)
            }
        }
        preHikeComments = item.preHikeComments
        postHikeComments = item.postHikeComments
        alternateItem = item.alternateItem
        isWeighed = item.isWeighed
        isInHand = item.isInHand
        isPacked = item.isPacked
        ownershipType = item.ownershipType
        carriedByID = item.carriedBy?.id
    }

    private func saveItem() {
        let item: GearItem
        if let existing = editingItem {
            item = existing
        } else {
            item = viewModel.addItem(name: name, category: category, priority: priority)
        }

        item.name = name
        item.category = category
        item.priority = priority
        item.descriptionOrPurpose = descriptionOrPurpose
        item.exampleProduct = exampleProduct
        item.moreInfoURL = moreInfoURL.isEmpty ? nil : moreInfoURL
        item.selection = selection
        item.quantity = quantity
        item.weightGrams = parseWeight()
        item.preHikeComments = preHikeComments
        item.postHikeComments = postHikeComments
        item.alternateItem = alternateItem
        item.isWeighed = isWeighed
        item.isInHand = isInHand
        item.isPacked = isPacked
        item.ownershipType = ownershipType
        if ownershipType == .group, let carriedByID {
            item.carriedBy = (expedition.participants ?? []).first { $0.id == carriedByID }
        } else {
            item.carriedBy = nil
        }

        dismiss()
    }

    private func parseWeight() -> Double? {
        guard let value = Double(weightString.replacingOccurrences(of: ",", with: ".")) else {
            return nil
        }
        switch weightUnit {
        case .kilograms:
            return value // Input is in grams
        case .pounds:
            return value * 453.592 // Convert lb to grams
        case .ounces:
            return value * 28.3495 // Convert oz to grams
        }
    }

    private func formatTotalWeight(_ grams: Double) -> String {
        switch weightUnit {
        case .kilograms:
            let kg = grams / 1000
            if kg >= 1 {
                return String(format: "%.2f kg", kg)
            } else {
                return String(format: "%.0f g", grams)
            }
        case .pounds:
            let lbs = grams / 453.592
            return String(format: "%.1f lb", lbs)
        case .ounces:
            let oz = grams / 28.3495
            return String(format: "%.1f oz", oz)
        }
    }

    private func categoryDescription(for category: GearCategory) -> String {
        switch category {
        case .goSuitClothing:
            return "Active wear for hiking and movement"
        case .footwear:
            return "Boots, shoes, and camp footwear"
        case .elementProtection:
            return "Rain gear, sun protection, insect defense"
        case .stopAndSleep:
            return "Camp and sleeping clothing layers"
        case .packing:
            return "Backpacks, stuff sacks, organization"
        case .shelter:
            return "Tent, tarp, bivy, ground protection"
        case .sleep:
            return "Sleeping bag, pad, pillow"
        case .kitchen:
            return "Stove, cookware, utensils"
        case .hydration:
            return "Water bottles, filters, treatment"
        case .navigation:
            return "Maps, compass, GPS, guides"
        case .toolsFirstAidEmergency:
            return "First aid, repair kit, emergency gear"
        case .personalItems:
            return "Toiletries, medications, personal care"
        case .electronics:
            return "Lights, batteries, chargers, devices"
        }
    }
}

#Preview {
    do {
        let container = try ModelContainer(
            for: Expedition.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let expedition = Expedition(name: "Test Expedition")
        container.mainContext.insert(expedition)

        return GearItemFormView(
            mode: .create(expedition: expedition),
            viewModel: GearViewModel(
                expedition: expedition,
                modelContext: container.mainContext
            )
        )
    } catch {
        return Text("Preview failed: \(error.localizedDescription)")
    }
}
