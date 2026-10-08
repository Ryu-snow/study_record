import SwiftUI

@main
struct FORMStudyApp: App {
    @State private var controlURL: URL?

    var body: some Scene {
        WindowGroup {
            StudyWebView(controlURL: controlURL)
                .background(Color.white)
                .ignoresSafeArea()
                .onOpenURL { url in controlURL = url }
        }
    }
}
