import Foundation

/// À ADAPTER : les deux URL publiques de votre Codespace (onglet Ports), sans « / » final.
enum Config {
    /// BFF mobile : port 8081
    static let bffURL = URL(string: "https://VOTRE-CODESPACE-8081.app.github.dev")!
    /// Serveur d'autorisation (ici l'API banque, /dev/token) : port 8080
    static let authURL = URL(string: "https://VOTRE-CODESPACE-8080.app.github.dev")!
}
