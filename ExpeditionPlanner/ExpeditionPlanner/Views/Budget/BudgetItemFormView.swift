import SwiftUI
import SwiftData
import PhotosUI

enum BudgetFormMode {
    case create
    case edit(BudgetItem)
}

struct BudgetItemFormView: View {
    @Environment(\.dismiss)
    private var dismiss

    let mode: BudgetFormMode
    let expedition: Expedition
    var viewModel: BudgetViewModel

    // Basic info
    @State private var name = ""
    @State private var budgetDescription = ""
    @State private var category: BudgetCategory = .other
    @State private var vendor = ""

    // Amounts
    @State private var estimatedAmountString = ""
    @State private var actualAmountString = ""
    @State private var currency = "USD"

    // Payment
    @State private var isPaid = false
    @State private var paidDate: Date = Date()
    @State private var hasPaidDate = false
    @State private var paymentMethod = ""

    // Dates
    @State private var hasDateIncurred = false
    @State private var dateIncurred: Date = Date()
    @State private var hasDueDate = false
    @State private var dueDate: Date = Date()

    // Receipt
    @State private var hasReceipt = false
    @State private var receiptFileName = ""

    // Notes
    @State private var notes = ""

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    private var editingItem: BudgetItem? {
        if case .edit(let item) = mode { return item }
        return nil
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !estimatedAmountString.isEmpty
    }

    var body: some View {
        Form {
            // Basic Info
            Section {
                TextField("Item Name", text: $name)
                TextField("Description", text: $budgetDescription, axis: .vertical)
                    .lineLimit(2...4)

                Picker("Category", selection: $category) {
                    ForEach(BudgetCategory.allCases, id: \.self) { cat in
                        Label(cat.rawValue, systemImage: cat.icon)
                            .tag(cat)
                    }
                }

                TextField("Vendor", text: $vendor)
            } header: {
                Text("Basic Information")
            }

            // Amounts
            Section {
                HStack {
                    TextField("Estimated Amount", text: $estimatedAmountString)
                        .keyboardType(.decimalPad)
                    Picker("", selection: $currency) {
                        Text("USD").tag("USD")
                        Text("EUR").tag("EUR")
                        Text("GBP").tag("GBP")
                        Text("CAD").tag("CAD")
                        Text("PEN").tag("PEN")
                        Text("MXN").tag("MXN")
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                }

                HStack {
                    TextField("Actual Amount", text: $actualAmountString)
                        .keyboardType(.decimalPad)
                    Text(currency)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Amount")
            }

            // Payment
            Section {
                Toggle("Paid", isOn: $isPaid)

                if isPaid {
                    Toggle("Record Payment Date", isOn: $hasPaidDate)
                    if hasPaidDate {
                        DatePicker("Payment Date", selection: $paidDate, displayedComponents: .date)
                    }
                    TextField("Payment Method", text: $paymentMethod)
                }
            } header: {
                Text("Payment")
            }

            // Dates
            Section {
                Toggle("Date Incurred", isOn: $hasDateIncurred)
                if hasDateIncurred {
                    DatePicker("Date", selection: $dateIncurred, displayedComponents: .date)
                }

                Toggle("Due Date", isOn: $hasDueDate)
                if hasDueDate {
                    DatePicker("Due", selection: $dueDate, displayedComponents: .date)
                }
            } header: {
                Text("Dates")
            }

            // Receipt
            Section {
                Toggle("Has Receipt", isOn: $hasReceipt)

                if hasReceipt && !receiptFileName.isEmpty {
                    LabeledContent("File", value: receiptFileName)
                }
            } header: {
                Text("Receipt")
            }

            // Notes
            Section {
                TextField("Notes", text: $notes, axis: .vertical)
                    .lineLimit(3...6)
            } header: {
                Text("Notes")
            }

            // Category info
            Section {
                HStack(spacing: 12) {
                    Image(systemName: category.icon)
                        .font(.title2)
                        .foregroundStyle(.secondary)
                        .frame(width: 32)

                    Text(category.rawValue)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Category Info")
            }
        }
        .navigationTitle(isEditing ? "Edit Budget Item" : "Add Budget Item")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button(isEditing ? "Save" : "Add") {
                    saveBudgetItem()
                }
                .disabled(!canSave)
            }
        }
        .onAppear {
            if let item = editingItem {
                loadBudgetItem(item)
            }
        }
    }

    // MARK: - Load/Save

    private func loadBudgetItem(_ item: BudgetItem) {
        name = item.name
        budgetDescription = item.budgetDescription
        category = item.category
        vendor = item.vendor ?? ""
        estimatedAmountString = "\(item.estimatedAmount)"
        if let actual = item.actualAmount {
            actualAmountString = "\(actual)"
        }
        currency = item.currency
        isPaid = item.isPaid
        if let date = item.paidDate {
            paidDate = date
            hasPaidDate = true
        }
        paymentMethod = item.paymentMethod ?? ""
        if let date = item.dateIncurred {
            dateIncurred = date
            hasDateIncurred = true
        }
        if let date = item.dueDate {
            dueDate = date
            hasDueDate = true
        }
        hasReceipt = item.hasReceipt
        receiptFileName = item.receiptFileName ?? ""
        notes = item.notes
    }

    private func saveBudgetItem() {
        let item: BudgetItem
        if let existing = editingItem {
            item = existing
        } else {
            item = BudgetItem()
        }

        item.name = name
        item.budgetDescription = budgetDescription
        item.category = category
        item.vendor = vendor.isEmpty ? nil : vendor
        item.estimatedAmount = Decimal(string: estimatedAmountString) ?? 0
        item.actualAmount = actualAmountString.isEmpty ? nil : Decimal(string: actualAmountString)
        item.currency = currency
        item.isPaid = isPaid
        item.paidDate = (isPaid && hasPaidDate) ? paidDate : nil
        item.paymentMethod = paymentMethod.isEmpty ? nil : paymentMethod
        item.dateIncurred = hasDateIncurred ? dateIncurred : nil
        item.dueDate = hasDueDate ? dueDate : nil
        item.hasReceipt = hasReceipt
        item.receiptFileName = receiptFileName.isEmpty ? nil : receiptFileName
        item.notes = notes

        if isEditing {
            viewModel.updateBudgetItem(item, in: expedition)
        } else {
            viewModel.addBudgetItem(item, to: expedition)
        }

        dismiss()
    }
}

#Preview {
    NavigationStack {
        BudgetItemFormView(
            mode: .create,
            expedition: Expedition(name: "Test"),
            // swiftlint:disable:next force_try
            viewModel: BudgetViewModel(modelContext: try! ModelContainer(
                for: Expedition.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            ).mainContext)
        )
    }
}
