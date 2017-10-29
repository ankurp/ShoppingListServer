import Vapor

extension Droplet {
    func setupRoutes() throws {
        try resource("shopping_lists", ShoppingListController.self)
        try resource("items", ItemController.self)
    }
}
