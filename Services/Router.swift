import SwiftUI
import SwiftData
import os

@Observable
@MainActor
final class Router {
    private(set) var path: [Route]
    private(set) var root: Route
    private var session: Session? = nil
    private var modelContext: ModelContext? = nil

    init(root: Route) {
        self.root = root
        self.path = [root]
    }
    
    func setSession(to session: Session, in modelContext: ModelContext){
        self.session = session
        self.modelContext = modelContext
        Log.router.debug("Router: Session and model context is set.")
    }
    
    func syncPathFromSession(defaultTo route: Route){
        if let session = session{
            if session.currentPath.isEmpty{
                self.navigate(to: route)
            } else{
                path = session.currentPath
            }
        }
    }

    func navigate(to route: Route) {
        Log.router.debug("Router: Navigating to \(route.rawValue).")
        self.path.append(route)
        updateSession()
    }

    func navigateBack(steps: Int = 1) {
        guard steps > 0, !self.path.isEmpty else {
            Log.router.debug("Router: Navigated back \(steps) steps, reached to root or target.")
            updateSession()
            return
        }
        self.path.removeLast()
        Log.router.debug("Router: Navigating back to \(self.path.last?.rawValue ?? "root").")
        navigateBack(steps: steps - 1)
    }
    
    func reset() {
        self.path = []
        Log.router.debug("Router: Reset navigation path to [].")
        updateSession()
    }

    func currentRoute() -> Route? {
        guard let route = self.path.last else {
            Log.router.debug("Router: Attempted to fetch current route but path is missing.")
            return nil
        }
        Log.router.debug("Router: Fetched current \(route.rawValue) route.")
        updateSession()
        return route
    }
    
    func prevRoute() -> Route? {
        guard path.count >= 2 else {
            Log.router.debug("Router: Attempted to fetch previous route but path is missing.")
            return nil
        }
        let route = path[path.count-2]
        Log.router.debug("Router: Fetched previous \(route.rawValue) route.")
        updateSession()
        return route
    }
    
    func updateSession(){
        if let session = self.session, let modelContext = self.modelContext{
            session.update(path: self.path, in: modelContext)
            return
        }
        if path.count != 1{
            Log.router.debug("Router: Failed to update path: Session and/or model context is missing.")
        }
        else{
            Log.router.debug("Router: Session and/or model context is not set yet.")
        }
    }
}
