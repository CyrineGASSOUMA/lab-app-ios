import Foundation

@MainActor
final class Session: ObservableObject {
    @Published var connecte = APIClient.shared.token != nil
    @Published var utilisateur = ""

    func connecter(_ nom: String, scopes: String) async throws {
        try await APIClient.shared.connecter(utilisateur: nom, scopes: scopes)
        utilisateur = nom
        connecte = true
    }

    func deconnecter() {
        APIClient.shared.deconnecter()
        utilisateur = ""
        connecte = false
    }
}
