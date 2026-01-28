//
//  JobStatusManager.swift
//  Service Center
//
//  Created by Alan Lam on 2/17/25.
//

import SwiftUI
import Combine

class JobStatusManager: ObservableObject {
    @Published var jobStatus: String = ""
    
    func updateJobStatus(newStatus: String) {
        self.jobStatus = newStatus
    }
}
