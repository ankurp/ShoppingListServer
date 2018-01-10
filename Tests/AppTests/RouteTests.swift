import XCTest
import Foundation
import Testing
import HTTP
@testable import Vapor
@testable import App

/// This file shows an example of testing 
/// routes through the Droplet.

class RouteTests: TestCase {
  let drop = try! Droplet.testable()
  
  override func tearDown() {
    super.tearDown()
    try! ShoppingList.makeQuery().delete()
  }
  
  func testHealthcheck() throws {
    try drop
      .testResponse(to: .get, at: "healthcheck.html")
      .assertStatus(is: .ok)
      .assertJSON("status", equals: "up")
  }
  
  func testRootRoute() throws {
    try drop
      .testResponse(to: .get, at: "/")
      .assertStatus(is: .seeOther)
      .assertHeader("Location", contains: "/shopping_lists")
  }
  
  func testShoppingListIndexRoute() throws {
    try drop
      .testResponse(to: .get, at: "/shopping_lists")
      .assertStatus(is: .ok)
      .assertBody(equals: "[]")
  }

  func testShoppingListCreateRoute() throws {
    let shoppingListName = "Shopping List Test Name"
    var reqBody = JSON()
    try reqBody.set("name", shoppingListName)

    let list = try drop
      .testResponse(to: .post,
                    at: "/shopping_lists",
                    headers: ["content-type": "application/json"],
                    body: reqBody)
    try list
      .assertStatus(is: .ok)
      .assertJSON("name", equals: shoppingListName)
      .assertJSON("items", equals: JSON([]))
    
    guard let listJSON = list.json else {
      XCTFail("Response should contain JSON")
      return
    }
    
    guard let listId = listJSON["id"]?.string else {
      XCTFail("JSON should contain id")
      return
    }
    
    try drop
      .testResponse(to: .get, at: "/shopping_lists/\(listId)")
      .assertStatus(is: .ok)
      .assertJSON("id", equals: listId)
      .assertJSON("name", equals: shoppingListName)
      .assertJSON("items", equals: JSON([]))

    let lists = try drop
      .testResponse(to: .get, at: "/shopping_lists")

    guard let listsJSON = lists.json?.array else {
      XCTFail("Response should contain array of shopping lists as JSON")
      return
    }

    XCTAssertEqual(listsJSON.count, 1, "Shopping List should have 1 item in array")
    XCTAssertEqual(listsJSON[0]["id"]?.string, listId, "Shopping List id is the same as the one created")
    XCTAssertEqual(listsJSON[0]["name"]?.string, shoppingListName, "Shopping List name is the same as the one created")
  }
  
  func testShoppingListDeleteRoute() throws {
    let shoppingListName = "Shopping List Test Name"
    var reqBody = JSON()
    try reqBody.set("name", shoppingListName)
    
    let list = try drop
      .testResponse(to: .post,
                    at: "/shopping_lists",
                    headers: ["content-type": "application/json"],
                    body: reqBody)
    try list
      .assertStatus(is: .ok)
      .assertJSON("name", equals: shoppingListName)
    
    guard let listJSON = list.json else {
      XCTFail("Response should contain JSON")
      return
    }
    
    guard let listId = listJSON["id"]?.string else {
      XCTFail("JSON should contain id")
      return
    }
    
    try drop
      .testResponse(to: .delete, at: "/shopping_lists/\(listId)")
      .assertStatus(is: .ok)
    
    let lists = try drop
      .testResponse(to: .get, at: "/shopping_lists")
    
    guard let listsJSON = lists.json?.array else {
      XCTFail("Response should contain array of shopping lists as JSON")
      return
    }
    
    XCTAssertEqual(listsJSON.count, 0, "Shopping List should have 1 item in array")
  }
  
  func testShoppingListUpdateRoute() throws {
    var shoppingListName = "Shopping List Test Name"
    var reqBody = JSON()
    try reqBody.set("name", shoppingListName)
    
    let list = try drop
      .testResponse(to: .post,
                    at: "/shopping_lists",
                    headers: ["content-type": "application/json"],
                    body: reqBody)
    try list
      .assertStatus(is: .ok)
      .assertJSON("name", equals: shoppingListName)
    
    guard let listJSON = list.json else {
      XCTFail("Response should contain JSON")
      return
    }
    
    guard let listId = listJSON["id"]?.string else {
      XCTFail("JSON should contain id")
      return
    }
    
    shoppingListName = "Another Name"
    try reqBody.set("name", shoppingListName)
    try drop
      .testResponse(to: .patch,
                    at: "/shopping_lists/\(listId)",
                    headers: ["content-type": "application/json"],
                    body: reqBody)
      .assertStatus(is: .ok)
    
    let lists = try drop
      .testResponse(to: .get, at: "/shopping_lists")
    
    guard let listsJSON = lists.json?.array else {
      XCTFail("Response should contain array of shopping lists as JSON")
      return
    }

    XCTAssertEqual(listsJSON.count, 1, "Shopping List should have 1 item in array")
    XCTAssertEqual(listsJSON[0]["id"]?.string, listId, "Shopping List id is the same as the one created")
    XCTAssertEqual(listsJSON[0]["name"]?.string, shoppingListName, "Shopping List name is the same as the one created")
  }

  static let allTests = [
    ("testHealthcheck", testHealthcheck),
    ("testRootRoute", testRootRoute),
    ("testShoppingListIndexRoute", testShoppingListIndexRoute),
    ("testShoppingListCreateRoute", testShoppingListCreateRoute),
    ("testShoppingListDeleteRoute", testShoppingListDeleteRoute),
    ("testShoppingListUpdateRoute", testShoppingListUpdateRoute)
    ]
}
