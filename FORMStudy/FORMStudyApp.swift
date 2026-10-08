import SwiftUI

@main
struct FORMStudyApp: App {
    var body: some Scene {
        WindowGroup {
            StudyWebView()
                .background(Color.white)
                .ignoresSafeArea()
        }
    }
}
