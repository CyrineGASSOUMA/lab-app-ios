import Foundation

// Contrat du BFF : l'app reçoit des données prêtes à afficher, elle ne calcule rien.

struct AccueilMobile: Codable {
    let utilisateur: String
    let soldeTotal: String
    let comptes: [CompteMobile]
    let dernieresOperations: [OperationMobile]
}

struct CompteMobile: Codable, Identifiable, Hashable {
    let id: Int
    let libelle: String
    let solde: String
}

struct OperationMobile: Codable {
    let libelle: String
    let montant: String
    let sens: String      // DEBIT, CREDIT ou INTERNE
    let date: String      // "2026-09-29"
}

struct VirementMobileRequest: Codable {
    let depuis: Int
    let vers: Int
    let montant: Decimal
    let libelle: String?
}

struct VirementMobileResponse: Codable {
    let reference: Int
    let message: String
    let montant: String
}

/// Erreur au format Problem Details (RFC 9457), avec le "code" stable ajouté par le BFF.
struct Probleme: Codable {
    let title: String?
    let status: Int?
    let detail: String?
    let code: String?
}

struct TokenResponse: Codable {
    let access_token: String
    let expires_in: Int
}
