import Foundation
import Network
import Combine

/// Monitors network connectivity and notifies when connection status changes
@MainActor
class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()
    
    @Published var isConnected = true
    @Published var connectionType: NWInterface.InterfaceType?
    @Published var isExpensive = false
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    private init() {
        startMonitoring()
    }
    
    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.isConnected = path.status == .satisfied
                self?.isExpensive = path.isExpensive
                self?.connectionType = path.availableInterfaces.first?.type
                
                #if DEBUG
                print("[NetworkMonitor] Connection status: \(path.status == .satisfied ? "Connected" : "Disconnected")")
                if let type = self?.connectionType {
                    print("[NetworkMonitor] Connection type: \(type)")
                }
                #endif
            }
        }
        monitor.start(queue: queue)
    }
    
    nonisolated func stopMonitoring() {
        monitor.cancel()
    }
    
    deinit {
        stopMonitoring()
    }
}
