import CoreData

/// NSFetchedResultsControllerDelegate를 클로저 기반으로 브릿지합니다.
/// Repository에서 NSFetchedResultsController를 AsyncStream으로 감쌀 때 사용합니다.
@MainActor
final class FRCStreamDelegate: NSObject, NSFetchedResultsControllerDelegate {
    private let onChange: @MainActor () -> Void

    init(onChange: @escaping @MainActor () -> Void) {
        self.onChange = onChange
    }

    nonisolated func controllerDidChangeContent(_ controller: NSFetchedResultsController<any NSFetchRequestResult>) {
        MainActor.assumeIsolated {
            onChange()
        }
    }
}
