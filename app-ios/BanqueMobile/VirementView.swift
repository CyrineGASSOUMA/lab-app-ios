import SwiftUI

struct VirementView: View {
    let comptes: [CompteMobile]

    @Environment(\.dismiss) private var dismiss
    @State private var depuis: Int?
    @State private var vers = "3"
    @State private var montant = ""
    @State private var libelle = ""

    /// Générée quand l'utilisateur valide, conservée pour « Réessayer », effacée si l'intention change.
    @State private var cle: String?
    @State private var enCours = false
    @State private var confirmation: String?
    @State private var erreur: ErreurAPI?

    var body: some View {
        NavigationStack {
            Form {
                if let confirmation = confirmation {
                    Section {
                        Label(confirmation, systemImage: "checkmark.circle.fill")
                            .foregroundStyle(Color.green)
                        Button("Terminer") { dismiss() }
                    }
                } else {
                    Section("Virement") {
                        Picker("Depuis", selection: $depuis) {
                            ForEach(comptes) { compte in
                                Text("\(compte.libelle) · \(compte.solde)").tag(Optional(compte.id))
                            }
                        }
                        TextField("Vers (n° de compte)", text: $vers)
                            .keyboardType(.numberPad)
                        TextField("Montant (€)", text: $montant)
                            .keyboardType(.decimalPad)
                        TextField("Libellé (facultatif)", text: $libelle)
                    }
                    Section {
                        Button {
                            Task { await valider() }
                        } label: {
                            HStack {
                                Text(cle == nil ? "Valider le virement" : "Réessayer (même clé)")
                                if enCours { Spacer(); ProgressView() }
                            }
                        }
                        .disabled(enCours)
                    } footer: {
                        if let cle = cle {
                            Text("Idempotency-Key : \(cle)").font(.caption2.monospaced())
                        }
                    }
                    if let erreur = erreur {
                        Section {
                            ErreurView(erreur: erreur) {
                                Task { await valider() }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Nouveau virement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                }
            }
            .onAppear {
                if depuis == nil { depuis = comptes.first?.id }
            }
            // Nouvelle intention = nouvelle clé
            .onChange(of: montant) { cle = nil }
            .onChange(of: vers) { cle = nil }
            .onChange(of: depuis) { cle = nil }
        }
    }

    private func valider() async {
        guard let source = depuis,
              let destination = Int(vers),
              let valeur = Decimal(string: montant.replacingOccurrences(of: ",", with: ".")) else {
            erreur = .reseau("Renseignez le compte de départ, la destination et le montant.")
            return
        }
        if cle == nil { cle = UUID().uuidString }       // une seule fois par intention
        guard let cleActuelle = cle else { return }

        enCours = true
        defer { enCours = false }
        do {
            let corps = VirementMobileRequest(depuis: source, vers: destination, montant: valeur,
                                              libelle: libelle.isEmpty ? nil : libelle)
            let reponse = try await APIClient.shared.virement(corps, cle: cleActuelle)
            confirmation = reponse.message
            erreur = nil
            cle = nil
        } catch let e as ErreurAPI {
            erreur = e                                  // la clé est conservée pour réessayer
        } catch {
            erreur = .reseau(error.localizedDescription)
        }
    }
}
