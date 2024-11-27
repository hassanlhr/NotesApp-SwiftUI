//
//  NetworkMonitor.swift
//  NotesApp
//
//  Created by Hassan Mumtaz on 05/11/2024.
//

import Foundation
import Network
import Combine
import BackgroundTasks
import UIKit

class NetworkMonitor: ObservableObject {
    
    private let monitor = NWPathMonitor()
    private var cancellable: AnyCancellable?
    
    @Published var isConnected: Bool = true
    
    init() {
        startMonitoring()
    }
    
    func startMonitoring() {
        let queue = DispatchQueue(label: "NetworkMonitorQueue")
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
            }
        }
        monitor.start(queue: queue)
    }
    
    func isConnectedToInternet() -> Bool {
        return isConnected
    }
}
