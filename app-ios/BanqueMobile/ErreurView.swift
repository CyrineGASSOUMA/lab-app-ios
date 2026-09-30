import SwiftUI

/// L'app réagit au "code" du BFF : chaque erreur a son message et son action.
struct ErreurView: View {
    let erreur: ErreurAPI
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(titre, systemImage: icone)
                .font(.headline)
                .foregroundStyle(couleur)
            Text(erreur.errorDescription ?? "")
                .font(.subheadline)
            if let libelle = libelleAction {
                Button(libelle, action: action).buttonStyle(.bordered)
            }
        }
        .padding(.vertical, 4)
    }

    private var titre: String {
        switch erreur.code ?? "" {
        case "SESSION_EXPIREE": return "Session expirée"
        case "OPERATION_NON_AUTORISEE": return "Opération non autorisée"
        case "OPERATION_REFUSEE": return "Opération refusée"
        case "SERVICE_INDISPONIBLE": return "Service momentanément indisponible"
        case "REQUETE_INVALIDE": return "Informations incorrectes"
        default: return "Une erreur est survenue"
        }
    }

    private var icone: String {
        switch erreur.code ?? "" {
        case "SESSION_EXPIREE": return "person.crop.circle.badge.exclamationmark"
        case "OPERATION_NON_AUTORISEE": return "lock.fill"
        case "SERVICE_INDISPONIBLE": return "wifi.exclamationmark"
        default: return "exclamationmark.triangle.fill"
        }
    }

    private var couleur: Color {
        erreur.code == "SERVICE_INDISPONIBLE" ? Color.orange : Color.red
    }

    /// Réessayer n'a de sens que pour une panne ; pour un refus, l'utilisateur doit changer quelque chose.
    private var libelleAction: String? {
        switch erreur.code ?? "" {
        case "SESSION_EXPIREE": return "Se reconnecter"
        case "SERVICE_INDISPONIBLE", "": return "Réessayer"
        default: return nil
        }
    }
}
