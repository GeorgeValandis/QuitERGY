#if DEBUG
import Foundation
import Combine

@MainActor
final class DebugSimulationController: ObservableObject {
    static let shared = DebugSimulationController()

    @Published var simulatedCleanDays: Int?

    private init() { }
}
#endif
