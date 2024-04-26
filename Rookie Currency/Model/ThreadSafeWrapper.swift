import Foundation

class ThreadSafeWrapper<Wrapped> {
    init(wrappedValue: Wrapped) {
        self.wrappedValue = wrappedValue
        concurrentDispatchQueue = DispatchQueue(label: "thread.safe.wrapper",
                                                attributes: .concurrent)
    }
    
    private var wrappedValue: Wrapped
    private let concurrentDispatchQueue: DispatchQueue
    
    func readSynchronously<T>(reader: (Wrapped) -> T) -> T {
        concurrentDispatchQueue.sync { reader(wrappedValue) }
    }
    
    func writeAsynchronously(writer: @escaping (Wrapped) -> Wrapped) {
        concurrentDispatchQueue.async(flags: .barrier) { [unowned self] in wrappedValue = writer(wrappedValue) }
    }
}
