import SwiftUI

struct ConnexionView: View {
    @EnvironmentObject private var session: Session
    @State private var erreur: String?
    @State private var enCours = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "building.columns.fill")
                .font(.system(size: 56))
                .foregroundStyle(Color.orange)
            Text("Ma Banque").font(.largeTitle.bold())
            Text("Formation BFF — choisissez un profil")
                .foregroundStyle(Color.secondary)
            VStack(spacing: 12) {
                bouton("Alice — tous les droits", nom: "alice",
                       scopes: "comptes:lire comptes:ecrire virements:creer")
                bouton("Bob — lecture seule", nom: "bob", scopes: "comptes:lire")
            }
            .padding(.horizontal)
            if enCours { ProgressView() }
            if let erreur = erreur {
                Text(erreur)
                    .font(.footnote)
                    .foregroundStyle(Color.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            Spacer()
        }
    }

    private func bouton(_ titre: String, nom: String, scopes: String) -> some View {
        Button {
            Task { await connecter(nom, scopes: scopes) }
        } label: {
            Text(titre).frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(Color.orange)
        .controlSize(.large)
        .disabled(enCours)
    }

    private func connecter(_ nom: String, scopes: String) async {
        enCours = true
        defer { enCours = false }
        do {
            try await session.connecter(nom, scopes: scopes)
            erreur = nil
        } catch {
            erreur = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
}
