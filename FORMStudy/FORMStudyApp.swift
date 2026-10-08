import SwiftUI

private enum StudyTab: Hashable {
    case home
    case focus
    case history
}

@main
struct FORMStudyApp: App {
    @State private var selectedTab: StudyTab = .home
    @State private var controlURL: URL?

    var body: some Scene {
        WindowGroup {
            TabView(selection: $selectedTab) {
                Tab("ホーム", systemImage: "house", value: StudyTab.home) {
                    Group {
                        if selectedTab == .home {
                            StudyWebView(page: "", controlURL: nil)
                                .ignoresSafeArea(.container, edges: .all)
                        } else {
                            Color.white
                        }
                    }
                }

                Tab("集中", systemImage: "timer", value: StudyTab.focus) {
                    Group {
                        if selectedTab == .focus {
                            StudyWebView(page: "focus", controlURL: controlURL)
                                .ignoresSafeArea(.container, edges: .all)
                        } else {
                            Color.white
                        }
                    }
                }

                Tab("履歴", systemImage: "clock.arrow.circlepath", value: StudyTab.history) {
                    Group {
                        if selectedTab == .history {
                            StudyWebView(page: "history", controlURL: nil)
                                .ignoresSafeArea(.container, edges: .all)
                        } else {
                            Color.white
                        }
                    }
                }
            }
            .background {
                Color.white.ignoresSafeArea()
            }
            .tint(Color(red: 0.32, green: 0.27, blue: 0.72))
            .onOpenURL { url in
                guard url.scheme == "studymoney", url.host == "timer" else { return }
                selectedTab = .focus
                controlURL = url
            }
        }
    }
}
