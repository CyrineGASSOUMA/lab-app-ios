import SwiftUI

@MainActor
final class AccueilModele: ObservableObject {
    @Published var accueil: AccueilMobile?
    @Published var erreur: ErreurAPI?
    @Published var chargement = false

    func charger(forcer: Bool = false) async {
        chargement = true
        defer { chargement = false }
        do {
            accueil = try await APIClient.shared.accueil(forcer: forcer)
            erreur = nil
        } catch let e as ErreurAPI {
            erreur = e
        } catch {
            erreur = .reseau(error.localizedDescription)
        }
    }
}

struct AccueilView: View {
    @EnvironmentObject private var session: Session
    @StateObject private var modele = AccueilModele()
    @State private var afficherVirement = false

    var body: some View {
        NavigationStack {
            List {
                if let accueil = modele.accueil {
                    Section {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Solde total").font(.subheadline).foregroundStyle(Color.secondary)
                            Text(accueil.soldeTotal).font(.largeTitle.bold()).monospacedDigit()
                        }
                        .padding(.vertical, 8)
                    }
                    Section("Mes comptes") {
                        ForEach(accueil.comptes) { compte in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(compte.libelle)
                                    Text("N° \(compte.id)").font(.caption).foregroundStyle(Color.secondary)
                                }
                                Spacer()
                                Text(compte.solde).bold().monospacedDigit()
                            }
                        }
                    }
                    Section("Dernières opérations") {
                        if accueil.dernieresOperations.isEmpty {
                            Text("Aucune opération").foregroundStyle(Color.secondary)
                        }
                        ForEach(Array(accueil.dernieresOperations.enumerated()), id: \.offset) { _, operation in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(operation.libelle)
                                    Text(operation.date).font(.caption).foregroundStyle(Color.secondary)
                                }
                                Spacer()
                                Text(operation.montant)
                                    .monospacedDigit()
                                    .foregroundStyle(operation.sens == "CREDIT" ? Color.green : Color.primary)
                            }
                        }
                    }
                }
                if let erreur = modele.erreur {
                    Section {
                        ErreurView(erreur: erreur) {
                            if erreur.code == "SESSION_EXPIREE" {
                                session.deconnecter()
                            } else {
                                Task { await modele.charger(forcer: true) }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Bonjour \(modele.accueil?.utilisateur ?? session.utilisateur)")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Déconnexion") { session.deconnecter() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        afficherVirement = true
                    } label: {
                        Label("Virement", systemImage: "arrow.left.arrow.right")
                    }
                    .disabled(modele.accueil == nil)
                }
            }
            .refreshable { await modele.charger(forcer: true) }
            .task { await modele.charger() }
            .overlay {
                if modele.chargement && modele.accueil == nil { ProgressView() }
            }
            .sheet(isPresented: $afficherVirement, onDismiss: {
                Task { await modele.charger(forcer: true) }   // après une écriture : données fraîches
            }) {
                VirementView(comptes: modele.accueil?.comptes ?? [])
            }
        }
    }
}
