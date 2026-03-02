import SwiftUI

struct MealPlanRowView: View {
    let plan: MealPlan

    var body: some View {
        HStack(spacing: 12) {
            // Meal plan indicator
            VStack {
                Image(systemName: "fork.knife")
                    .font(.title2)
                    .foregroundStyle(.orange)
            }
            .frame(width: 40, height: 40)
            .background(Color.orange.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(plan.dayLabel)
                    .font(.headline)
                    .lineLimit(1)

                Text("\(plan.mealCount) meals")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Total calories
            if plan.totalCalories > 0 {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(plan.totalCalories)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("cal")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
