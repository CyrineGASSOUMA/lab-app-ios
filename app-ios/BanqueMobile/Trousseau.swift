import Foundation
import Security

/// Le token est stocké dans le Keychain, jamais dans UserDefaults.
enum Trousseau {
    private static let service = "fr.formation.banquemobile"

    static func enregistrer(_ valeur: String, cle: String) {
        let base: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: cle
        ]
        SecItemDelete(base as CFDictionary)
        var ajout = base
        ajout[kSecValueData as String] = Data(valeur.utf8)
        ajout[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        SecItemAdd(ajout as CFDictionary, nil)
    }

    static func lire(cle: String) -> String? {
        let requete: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: cle,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var resultat: AnyObject?
        guard SecItemCopyMatching(requete as CFDictionary, &resultat) == errSecSuccess,
              let data = resultat as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func supprimer(cle: String) {
        let requete: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: cle
        ]
        SecItemDelete(requete as CFDictionary)
    }
}
