# App iOS « Ma Banque » — client du BFF (bonus)

Une petite app SwiftUI qui consomme **votre BFF** : connexion, écran d'accueil, virement.
Code prêt à l'emploi, à lancer dans le simulateur iPhone.

## Ce que le code montre
| Fichier | Bonne pratique |
|---|---|
| `Trousseau.swift` | token stocké dans le **Keychain** |
| `APIClient.swift` | `async/await`, décodage des **Problem Details**, cache HTTP (`Cache-Control`, `ETag`) géré par `URLCache`, **pas de retry côté app** (le BFF s'en charge) |
| `VirementView.swift` | **Idempotency-Key** générée une fois par intention, réutilisée pour « Réessayer », effacée si l'utilisateur modifie le virement |
| `ErreurView.swift` | réaction au **code** du BFF : se reconnecter, réessayer, ou afficher un refus |

## Prérequis
- Mac avec **Xcode 15 ou plus récent** (iOS 17+).
- API banque et BFF lancés (dans Codespaces ou en local).

## Mise en route (5 min)

### 1. Rendre les ports publics (Codespaces)
Onglet **Ports** → clic droit sur **8080** → *Port Visibility* → **Public**. Idem pour **8081**.
Copiez les deux URL (colonne *Forwarded Address*), par ex. `https://xxx-8081.app.github.dev`.
> Sans cette étape, GitHub renvoie une page de connexion au lieu du JSON.

### 2. Créer le projet Xcode
1. *File › New › Project… › iOS › App* → **Next**.
2. Product Name : `BanqueMobile` · Interface : **SwiftUI** · Language : **Swift** · Storage : None → **Next**, choisir un dossier.
3. Dans le projet créé, **supprimer** `ContentView.swift` et `BanqueMobileApp.swift` (*Move to Trash*).
4. Glisser les 10 fichiers du dossier `BanqueMobile/` dans le groupe `BanqueMobile` d'Xcode, en cochant **Copy items if needed**.

### 3. Renseigner les URL
Dans `Config.swift`, remplacer les deux URL par celles de l'étape 1 (sans `/` final).

### 4. Lancer
Choisir un simulateur iPhone, puis **⌘R**.

## Scénarios de démonstration
| Action | Ce qu'on observe |
|---|---|
| Se connecter en **Alice** | accueil : comptes, solde total, opérations, déjà formatés par le BFF |
| Tirer pour rafraîchir | nouvel appel (le BFF répond depuis son cache pendant 30 s) |
| Virement de 1 vers 3 | confirmation, accueil mis à jour |
| Avant un virement : `POST /dev/pannes?mode=REPONSE_PERDUE&nombre=1` (requetes.http, 7.2) | le virement réussit quand même, **une seule fois** : le BFF a réessayé avec la même clé |
| `POST /dev/pannes?mode=INDISPONIBLE&nombre=10`, puis rafraîchir | carte orange « Service momentanément indisponible » + bouton Réessayer. Arrêter la panne : `DELETE /dev/pannes` |
| Se connecter en **Bob**, tenter un virement | « Opération non autorisée », sans bouton Réessayer |
| Montant de 999 999 € | « Opération refusée » + détail de la banque |

## Variante : BFF lancé sur le Mac (localhost)
Mettre `http://localhost:8081` et `http://localhost:8080` dans `Config.swift`, puis autoriser le HTTP local :
cible *BanqueMobile* → onglet **Info** → ajouter `App Transport Security Settings` → `Allow Local Networking` = **YES**.

## Pour aller plus loin
En production, `/dev/token` est remplacé par une vraie connexion : `ASWebAuthenticationSession` avec le flux **Authorization Code + PKCE**, puis un refresh token.
