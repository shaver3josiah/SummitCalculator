import SwiftUI
import SummitCore

struct BudgetView: View {
    @Environment(ThemeStore.self) private var theme
    @Environment(BudgetStore.self) private var store
    @State private var showImport = false

    private let modes = ["This month", "Year view"]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                monthBar
                HStack(spacing: 8) {
                    KTabBar(items: modes, selection: viewModeBinding)
                    Menu {
                        ShareLink(item: store.exportText()) {
                            Label("Share as text", systemImage: "doc.plaintext")
                        }
                        if let xlsx = store.exportXLSXURL() {
                            ShareLink(item: xlsx) {
                                Label("Share as spreadsheet", systemImage: "tablecells")
                            }
                            .accessibilityLabel("Share as spreadsheet")
                        }
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(theme.color("primaryStrong"))
                            .frame(width: 44, height: 44)
                            .background(theme.color("surfaceSoft"))
                            .clipShape(Circle())
                    }
                    .accessibilityLabel("Share this month")
                    Button {
                        showImport = true
                    } label: {
                        Image(systemName: "square.and.arrow.down")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(theme.color("primaryStrong"))
                            .frame(width: 44, height: 44)
                            .background(theme.color("surfaceSoft"))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Import a shared budget")
                }
                if store.view == "month" {
                    MonthWrap()
                } else {
                    YearWrap()
                }
                PrincipalVsRothSection()
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .background(theme.color("bg"))
        .sheet(isPresented: $showImport) {
            ImportBudgetSheet()
        }
    }

    private var viewModeBinding: Binding<String> {
        Binding(
            get: { store.view == "month" ? "This month" : "Year view" },
            set: { store.view = $0 == "This month" ? "month" : "year" }
        )
    }

    private var monthBar: some View {
        HStack {
            EncirclePressButton(cornerRadius: 22, lineWidth: 1.5) {
                store.shiftMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(theme.color("primaryStrong"))
                    .frame(width: 44, height: 44)
                    .background(theme.color("surfaceSoft"))
                    .clipShape(Circle())
            }
            .opacity(store.view == "month" ? 1 : 0)
            .disabled(store.view != "month")
            .accessibilityLabel("Previous month")

            Spacer()

            Text(store.view == "month" ? store.monthLabel : "\(store.yearSel)")
                .font(summitNumber(19, weight: .semibold))
                .foregroundStyle(theme.color("deep"))

            Spacer()

            EncirclePressButton(cornerRadius: 22, lineWidth: 1.5) {
                store.shiftMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(theme.color("primaryStrong"))
                    .frame(width: 44, height: 44)
                    .background(theme.color("surfaceSoft"))
                    .clipShape(Circle())
            }
            .opacity(store.view == "month" ? 1 : 0)
            .disabled(store.view != "month")
            .accessibilityLabel("Next month")
        }
    }
}
