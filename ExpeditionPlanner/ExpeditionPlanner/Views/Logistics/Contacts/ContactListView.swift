import SwiftUI
import SwiftData

struct ContactListView: View {
    @Environment(\.modelContext)
    private var modelContext

    @Bindable var expedition: Expedition

    @State private var viewModel: ContactViewModel?
    @State private var showingAddSheet = false
    @State private var selectedContact: Contact?

    var body: some View {
        Group {
            if let viewModel = viewModel {
                contactList(viewModel: viewModel)
            } else {
                ProgressView()
            }
        }
        .navigationTitle("Contacts")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }

            if let viewModel = viewModel, !viewModel.contacts.isEmpty {
                ToolbarItem(placement: .topBarLeading) {
                    filterMenu(viewModel: viewModel)
                }
            }
        }
        .searchable(
            text: Binding(
                get: { viewModel?.searchText ?? "" },
                set: { newValue in
                    viewModel?.searchText = newValue
                    viewModel?.loadContacts(for: expedition)
                }
            ),
            prompt: "Search contacts"
        )
        .sheet(isPresented: $showingAddSheet) {
            if let viewModel = viewModel {
                NavigationStack {
                    ContactFormView(
                        mode: .create,
                        expedition: expedition,
                        viewModel: viewModel
                    )
                }
            }
        }
        .sheet(item: $selectedContact) { contact in
            if let viewModel = viewModel {
                NavigationStack {
                    ContactDetailView(
                        contact: contact,
                        expedition: expedition,
                        viewModel: viewModel
                    )
                }
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = ContactViewModel(modelContext: modelContext)
            }
            viewModel?.loadContacts(for: expedition)
        }
    }

    // MARK: - List Content

    @ViewBuilder
    private func contactList(viewModel: ContactViewModel) -> some View {
        if viewModel.contacts.isEmpty && !viewModel.hasActiveFilters {
            ContentUnavailableView {
                Label("No Contacts", systemImage: "person.crop.rectangle.stack")
            } description: {
                Text("Add contacts for local resources, emergency services, and logistics support.")
            } actions: {
                Button("Add Contact") {
                    showingAddSheet = true
                }
                .buttonStyle(.borderedProminent)
            }
        } else if viewModel.contacts.isEmpty {
            ContentUnavailableView.search(text: viewModel.searchText)
        } else {
            List {
                // Emergency contacts section
                if !viewModel.emergencyContacts.isEmpty && !viewModel.showEmergencyOnly {
                    Section {
                        ForEach(viewModel.emergencyContacts) { contact in
                            ContactRowView(contact: contact)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedContact = contact
                                }
                        }
                    } header: {
                        Label("Emergency Contacts", systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                    }
                }

                // Filter indicator
                if viewModel.hasActiveFilters {
                    Section {
                        filterIndicator(viewModel: viewModel)
                    }
                }

                // Grouped content
                ForEach(viewModel.groupedByCategory, id: \.category) { group in
                    // Skip emergency if shown separately
                    if group.category != .emergency || viewModel.showEmergencyOnly {
                        Section {
                            ForEach(group.contacts) { contact in
                                ContactRowView(contact: contact)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        selectedContact = contact
                                    }
                            }
                            .onDelete { indexSet in
                                deleteContacts(at: indexSet, from: group.contacts, viewModel: viewModel)
                            }
                        } header: {
                            HStack {
                                Image(systemName: group.category.icon)
                                Text(group.category.rawValue)
                                Text("(\(group.contacts.count))")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Filter Indicator

    private func filterIndicator(viewModel: ContactViewModel) -> some View {
        HStack {
            Image(systemName: "line.3.horizontal.decrease.circle.fill")
                .foregroundStyle(.blue)
            Text(filterDescription(viewModel: viewModel))
                .font(.subheadline)
            Spacer()
            Button("Clear") {
                viewModel.clearFilters()
                viewModel.loadContacts(for: expedition)
            }
            .font(.caption)
            .foregroundStyle(.blue)
        }
    }

    private func filterDescription(viewModel: ContactViewModel) -> String {
        var parts: [String] = []
        if let category = viewModel.filterCategory {
            parts.append(category.rawValue)
        }
        if viewModel.showEmergencyOnly {
            parts.append("Emergency")
        }
        if !viewModel.searchText.isEmpty {
            parts.append("\"\(viewModel.searchText)\"")
        }
        return parts.isEmpty ? "Filtered" : parts.joined(separator: " · ")
    }

    // MARK: - Filter Menu

    @ViewBuilder
    private func filterMenu(viewModel: ContactViewModel) -> some View {
        Menu {
            Button {
                viewModel.clearFilters()
                viewModel.loadContacts(for: expedition)
            } label: {
                Label(
                    "Clear Filters",
                    systemImage: viewModel.hasActiveFilters ? "" : "checkmark"
                )
            }

            Divider()

            Button {
                viewModel.showEmergencyOnly.toggle()
                viewModel.loadContacts(for: expedition)
            } label: {
                Label(
                    "Emergency Only",
                    systemImage: viewModel.showEmergencyOnly ? "checkmark" : ""
                )
            }

            Divider()

            // Category filter
            Menu("Category") {
                Button {
                    viewModel.filterCategory = nil
                    viewModel.loadContacts(for: expedition)
                } label: {
                    Label("All Categories", systemImage: viewModel.filterCategory == nil ? "checkmark" : "")
                }

                Divider()

                ForEach(ContactCategory.allCases, id: \.self) { category in
                    Button {
                        viewModel.filterCategory = category
                        viewModel.loadContacts(for: expedition)
                    } label: {
                        Label {
                            Text(category.rawValue)
                        } icon: {
                            if viewModel.filterCategory == category {
                                Image(systemName: "checkmark")
                            } else {
                                Image(systemName: category.icon)
                            }
                        }
                    }
                }
            }

            Divider()

            // Sort options
            Menu("Sort By") {
                ForEach(ContactSortOrder.allCases, id: \.self) { order in
                    Button {
                        viewModel.sortOrder = order
                        viewModel.loadContacts(for: expedition)
                    } label: {
                        Label(
                            order.rawValue,
                            systemImage: viewModel.sortOrder == order ? "checkmark" : ""
                        )
                    }
                }
            }
        } label: {
            Image(systemName: viewModel.hasActiveFilters
                ? "line.3.horizontal.decrease.circle.fill"
                : "line.3.horizontal.decrease.circle")
        }
    }

    // MARK: - Delete

    private func deleteContacts(
        at indexSet: IndexSet,
        from contacts: [Contact],
        viewModel: ContactViewModel
    ) {
        for index in indexSet {
            viewModel.deleteContact(contacts[index], from: expedition)
        }
    }
}

#Preview {
    NavigationStack {
        ContactListView(expedition: Expedition(name: "Test Expedition"))
    }
    .modelContainer(for: [Expedition.self, Contact.self], inMemory: true)
}
