import SwiftUI

@main
struct BanqueMobileApp: App {
    @StateObject private var session = Session()

    var body: some Scene {
        WindowGroup {
            if session.connecte {
                AccueilView().environmentObject(session)
            } else {
                ConnexionView().environmentObject(session)
            }
        }
    }
}
