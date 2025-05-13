import SwiftUI

struct ContentView: View {
    @State private var window: UIWindow?

    var body: some View {
        VStack(spacing: 30) {
            Text("Welcome to SampleApp!")
                .font(.title)

            CustomerlyChatButton()
        }
        .injectWindow($window)
    }
}
