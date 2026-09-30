import Foundation

enum ErreurAPI: Error, LocalizedError {
    case probleme(Probleme)
    case reseau(String)

    var errorDescription: String? {
        switch self {
        case .probleme(let p): return p.detail ?? p.title ?? "Une erreur est survenue."
        case .reseau(let message): return message
        }
    }

    /// Le code stable du BFF : l'app décide sur lui, jamais sur le texte.
    var code: String? {
        if case .probleme(let p) = self { return p.code }
        return nil
    }
}

/// Toutes les communications de l'app passent par ici.
/// Pas de retry automatique côté app : le BFF s'en charge déjà (un seul niveau de retry).
final class APIClient {

    static let shared = APIClient()

    private let session: URLSession
    private let cache = URLCache(memoryCapacity: 10_000_000, diskCapacity: 0)
    private let decodeur = JSONDecoder()
    private let encodeur = JSONEncoder()

    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = cache
        configuration.requestCachePolicy = .useProtocolCachePolicy   // applique Cache-Control et ETag du BFF
        configuration.timeoutIntervalForRequest = 15
        session = URLSession(configuration: configuration)
    }

    var token: String? { Trousseau.lire(cle: "token") }

    // MARK: Authentification

    /// Formation : /dev/token simule le serveur d'autorisation.
    /// En production : ASWebAuthenticationSession + Authorization Code + PKCE.
    func connecter(utilisateur: String, scopes: String) async throws {
        var composants = URLComponents(url: Config.authURL.appendingPathComponent("dev/token"),
                                       resolvingAgainstBaseURL: false)!
        composants.queryItems = [URLQueryItem(name: "sub", value: utilisateur),
                                 URLQueryItem(name: "scope", value: scopes)]
        var requete = URLRequest(url: composants.url!)
        requete.httpMethod = "POST"
        let reponse: TokenResponse = try await envoyer(requete)
        Trousseau.enregistrer(reponse.access_token, cle: "token")
    }

    func deconnecter() {
        Trousseau.supprimer(cle: "token")
        cache.removeAllCachedResponses()
    }

    // MARK: Appels au BFF

    /// forcer = true après une écriture ou un « tirer pour rafraîchir » : on ignore le cache local.
    func accueil(forcer: Bool = false) async throws -> AccueilMobile {
        var requete = requeteBFF("mobile/accueil")
        if forcer { requete.cachePolicy = .reloadIgnoringLocalCacheData }
        return try await envoyer(requete)
    }

    /// La clé d'idempotence est fournie par l'écran : générée une fois par intention, réutilisée à chaque nouvel essai.
    func virement(_ corps: VirementMobileRequest, cle: String) async throws -> VirementMobileResponse {
        var requete = requeteBFF("mobile/virements", methode: "POST")
        requete.setValue(cle, forHTTPHeaderField: "Idempotency-Key")
        requete.setValue("application/json", forHTTPHeaderField: "Content-Type")
        requete.httpBody = try encodeur.encode(corps)
        return try await envoyer(requete)
    }

    // MARK: Plomberie

    private func requeteBFF(_ chemin: String, methode: String = "GET") -> URLRequest {
        var requete = URLRequest(url: Config.bffURL.appendingPathComponent(chemin))
        requete.httpMethod = methode
        if let token = token {
            requete.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return requete
    }

    private func envoyer<T: Decodable>(_ requete: URLRequest) async throws -> T {
        let resultat: (Data, URLResponse)
        do {
            resultat = try await session.data(for: requete)
        } catch {
            throw ErreurAPI.reseau("Connexion impossible. Vérifiez le réseau et les URL de Config.swift.")
        }
        let (data, reponse) = resultat
        guard let http = reponse as? HTTPURLResponse else {
            throw ErreurAPI.reseau("Réponse invalide.")
        }
        if http.statusCode == 401 {
            throw ErreurAPI.probleme(Probleme(title: "Session expirée", status: 401,
                                              detail: "Reconnectez-vous pour continuer.", code: "SESSION_EXPIREE"))
        }
        guard (200..<300).contains(http.statusCode) else {
            if let probleme = try? decodeur.decode(Probleme.self, from: data) {
                throw ErreurAPI.probleme(probleme)
            }
            throw ErreurAPI.probleme(Probleme(title: "Erreur", status: http.statusCode,
                                              detail: "Erreur \(http.statusCode).", code: nil))
        }
        return try decodeur.decode(T.self, from: data)
    }
}
