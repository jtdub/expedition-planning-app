import SwiftUI

struct ResupplyRowView: View {
    let resupplyPoint: ResupplyPoint

    var body: some View {
        HStack(spacing: 12) {
            // Day indicator
            VStack {
                if let day = resupplyPoint.dayNumber {
                    Text("Day")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("\(day)")
                        .font(.title2)
                        .fontWeight(.bold)
                } else {
                    Image(systemName: "shippingbox.fill")
                        .font(.title2)
                        .foregroundStyle(.brown)
                }
            }
            .frame(width: 44)

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(resupplyPoint.name)
                    .font(.headline)

                if !resupplyPoint.servicesString.isEmpty {
                    Text(resupplyPoint.servicesString)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                if let date = resupplyPoint.expectedArrivalDate {
                    Text(date.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Service icons
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    if resupplyPoint.hasPostOffice {
                        Image(systemName: "envelope.fill")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                    if resupplyPoint.hasGroceries {
                        Image(systemName: "cart.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                    if resupplyPoint.hasLodging {
                        Image(systemName: "bed.double.fill")
                            .font(.caption)
                            .foregroundStyle(.purple)
                    }
                }

                if resupplyPoint.coordinate != nil {
                    Image(systemName: "mappin.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    List {
        ResupplyRowView(
            resupplyPoint: {
                let point = ResupplyPoint(name: "Bettles, AK")
                point.dayNumber = 7
                point.hasPostOffice = true
                point.hasGroceries = true
                point.hasLodging = true
                point.expectedArrivalDate = Date().addingTimeInterval(86400 * 7)
                return point
            }()
        )
        ResupplyRowView(
            resupplyPoint: {
                let point = ResupplyPoint(name: "Coldfoot Camp")
                point.dayNumber = 3
                point.hasFuel = true
                point.hasRestaurant = true
                return point
            }()
        )
    }
}
