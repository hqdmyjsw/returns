//
//  PortfolioRow.swift
//  Returns (macOS)
//
//  Created by James Chen on 2021/11/03.
//

import SwiftUI

struct PortfolioRow: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject var portfolioSettings = PortfolioSettings()
    @State private var isHovering = false
    @State private var showingDeletePrompt = false
    @State private var showingConfigureSheet = false

    @ObservedObject var portfolio: Portfolio

    var body: some View {
        Section(
            header: Text(verbatim: portfolio.name ?? "")
        ) {
            NavigationLink(
                destination: PortfolioView(portfolio: portfolio, showingConfigureSheet: $showingConfigureSheet)
            ) {
                Label("Overflow", systemImage: "chart.pie")
            }
            .onHover(perform: { isHovering in
                self.isHovering = isHovering
            })
            .alert(isPresented: $showingDeletePrompt) {
                Alert(
                    title: Text(portfolio.name ?? ""),
                    message: Text("Are you sure you want to delete the portfolio?"),
                    primaryButton: .default(Text("Delete")) {
                        delete(portfolio: portfolio)
                    },
                    secondaryButton: .cancel())
            }
            .sheet(isPresented: $showingConfigureSheet) {
                ConfigurePortfolioView(config: portfolio.config) { config in
                    configure(portfolio: portfolio, config: config)
                }
            }
            .contextMenu {
                Button("Configure Portfolio...") {
                    showingConfigureSheet = true
                }
                Divider()
                Button("Add Account") {
                    addAccount(to: portfolio)
                }
                Divider()
                Button("Delete Portfolio...") {
                    showingDeletePrompt = true
                }
            }

            ForEach(portfolio.sortedAccounts) { account in
                AccountRow(portfolio: portfolio, account: account)
                    .environmentObject(portfolioSettings)
            }
        }
        .onAppear {
            portfolioSettings.portfolio = portfolio
        }
    }
}

private extension PortfolioRow {
    // TODO: update sidebar selection
    func delete(portfolio: Portfolio) {
        withAnimation {
            viewContext.delete(portfolio)

            do {
                try viewContext.save()
            } catch {
                viewContext.rollback()
                print("Failed to save, error \(error)")
            }
        }
    }

    // TODO: update sidebar selection
    func addAccount(to portfolio: Portfolio) {
        withAnimation {
            let account = Account(context: viewContext)
            account.createdAt = Date()
            account.portfolio = portfolio
            account.name = "Account #\(portfolio.accounts?.count ?? 0 + 1)"
            account.rebuildRecords()

            do {
                try viewContext.save()
            } catch {
                viewContext.rollback()
                print("Failed to save, error \(error)")
            }
        }
    }

    func configure(portfolio: Portfolio, config: PortfolioConfig) {
        portfolio.update(config: config)

        do {
            try viewContext.save()
            portfolioSettings.update()
        } catch {
            viewContext.rollback()
            print("Failed to save, error \(error)")
        }
    }
}

struct PortfolioRow_Previews: PreviewProvider {
    static var previews: some View {
        PortfolioRow(portfolio: testPortfolio)
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }

    static var testPortfolio: Portfolio {
        let context = PersistenceController.preview.container.viewContext
        let portfolio = Portfolio(context: context)
        portfolio.name = "My Portfolio"
        var account = Account(context: context)
        account.name = "My Account #1"
        account.portfolio = portfolio
        account = Account(context: context)
        account.name = "My Account #2"
        account.portfolio = portfolio
        return portfolio
    }
}
