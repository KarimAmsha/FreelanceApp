import SwiftUI

@MainActor
protocol StateManaging: ObservableObject {
    var state: LoadingState { get set }
    var appRouter: AppRouter? { get set }

    func handleSuccess(message: String?)
    func handleError(_ message: String)
    func resetState()
    func prepareForLoading()
    func shouldStartLoading() -> Bool
    func startLoading()
    func finishLoading(_ message: String?)
    func failLoading(error: String)
}

extension StateManaging {
    
    func handleSuccess(message: String? = nil) {
        resetState()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.state = .success(message: message)
            self.appRouter?.observeState(self.state)
        }
    }

    func handleError(_ message: String) {
        resetState()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.state = .failure(error: message)
            self.appRouter?.observeState(self.state)
        }
    }

    func resetState() {
        state = .idle
    }

    func prepareForLoading() {
        if !state.isLoading {
            resetState()
        }
    }

    func shouldStartLoading() -> Bool {
        guard !state.isLoading else { return false }
        resetState()
        return true
    }

    func startLoading() {
        prepareForLoading()
        state = .loading
    }

    func finishLoading(_ message: String? = nil) {
        handleSuccess(message: message)
    }

    func failLoading(error: String) {
        handleError(error)
    }
}
