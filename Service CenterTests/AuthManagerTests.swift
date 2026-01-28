//
//  AuthManagerTests.swift
//  Service CenterTests
//
//  Created by Robert Agnvall on 2/19/25.
//

import XCTest
@testable import Service_Center

final class AuthManagerTests: XCTestCase {

    var authManager: AuthManager!

    override func setUpWithError() throws {
        // Reset the AuthManager before each test
        authManager = AuthManager.shared
    }

    override func tearDownWithError() throws {
        // Clean up after each test
        authManager = nil
    }

    func testSetMockUser() {
        // Create a mock user
        let mockUser = User(
            profile_pic: "mock_pic_url",
            id: "mock_id",
            fullname: "Test User",
            email: "test@example.com",
            description: "A test user",
            username: "testuser"
        )

        // Set mock user
        authManager.setMockUser(mockUser)

        // Assertions
        XCTAssertNotNil(authManager.currentUser, "Current user should not be nil after setting mock user")
        XCTAssertEqual(authManager.currentUser?.id, "mock_id", "User ID should match mock ID")
        XCTAssertEqual(authManager.currentUser?.email, "test@example.com", "Email should match mock email")
    }
}

