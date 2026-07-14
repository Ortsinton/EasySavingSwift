//
//  AppCoordinator.swift
//  EasySaving
//
//  Created by Jorge Sirvent on 14/7/26.
//

import SwiftUI
import Observation

@Observable @MainActor
final class AppCoordinator {
    var path = NavigationPath()

    func push(_ route: Route) {
        path.append(route)
    }
    
    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }
    
    func popToRoot() {
        while !path.isEmpty {
            path.removeLast()
        }
    }
}
