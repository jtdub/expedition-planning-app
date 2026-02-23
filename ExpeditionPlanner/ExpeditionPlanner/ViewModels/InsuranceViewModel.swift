import Foundation
import SwiftData

@Observable
final class InsuranceViewModel {
    private var modelContext: ModelContext

    var policies: [InsurancePolicy] = []
    var errorMessage: String?

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - CRUD Operations

    func loadPolicies(for expedition: Expedition) {
        policies = (expedition.insurancePolicies ?? []).sorted { policy1, policy2 in
            // Sort by: active first, then by type, then by provider
            if policy1.isActive != policy2.isActive {
                return policy1.isActive
            }
            if policy1.insuranceType != policy2.insuranceType {
                return policy1.insuranceType.rawValue < policy2.insuranceType.rawValue
            }
            return policy1.provider < policy2.provider
        }
    }

    func addPolicy(_ policy: InsurancePolicy, to expedition: Expedition) {
        policy.expedition = expedition
        if expedition.insurancePolicies == nil {
            expedition.insurancePolicies = []
        }
        expedition.insurancePolicies?.append(policy)
        modelContext.insert(policy)
        saveContext()
        loadPolicies(for: expedition)
    }

    func deletePolicy(_ policy: InsurancePolicy, from expedition: Expedition) {
        expedition.insurancePolicies?.removeAll { $0.id == policy.id }
        modelContext.delete(policy)
        saveContext()
        loadPolicies(for: expedition)
    }

    func updatePolicy(_ policy: InsurancePolicy, in expedition: Expedition) {
        saveContext()
        loadPolicies(for: expedition)
    }

    // MARK: - Computed Statistics

    var activePoliciesCount: Int {
        policies.filter { $0.isActive }.count
    }

    var expiringSoonCount: Int {
        policies.filter { $0.isExpiringSoon && !$0.isExpired }.count
    }

    var expiredCount: Int {
        policies.filter { $0.isExpired }.count
    }

    var totalCoverageByType: [InsuranceType: Decimal] {
        var result: [InsuranceType: Decimal] = [:]
        for policy in policies where policy.isActive {
            let current = result[policy.insuranceType] ?? 0
            result[policy.insuranceType] = current + (policy.coverageAmount ?? 0)
        }
        return result
    }

    var hasEvacuationCoverage: Bool {
        policies.contains { $0.insuranceType == .evacuation && $0.isActive }
    }

    var hasMedicalCoverage: Bool {
        policies.contains { $0.insuranceType == .travelMedical && $0.isActive }
    }

    var hasSearchRescueCoverage: Bool {
        policies.contains { $0.insuranceType == .searchRescue && $0.isActive }
    }

    // MARK: - Filtering

    func policies(ofType type: InsuranceType) -> [InsurancePolicy] {
        policies.filter { $0.insuranceType == type }
    }

    func activePolicies() -> [InsurancePolicy] {
        policies.filter { $0.isActive }
    }

    func policiesNeedingAttention() -> [InsurancePolicy] {
        policies.filter { $0.isExpiringSoon || $0.isExpired }
    }

    // MARK: - Private

    private func saveContext() {
        do {
            try modelContext.save()
            errorMessage = nil
        } catch {
            errorMessage = "Failed to save: \(error.localizedDescription)"
        }
    }
}
