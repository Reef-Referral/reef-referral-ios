import XCTest
@testable import ReefReferal

class ReefReferalTests: XCTestCase {

    // Test the "test_connection" endpoint
    func testTestConnection() {
        let expectation = expectation(description: "API Connection Expectation")
        let testConnectionRequest = ReferralTestConnectionRequest()

        Task {
            let result = await ReefAPIClient.shared.send(testConnectionRequest)

            // Check the result
            switch result {
            case .success(let response):
                XCTAssertNotNil(response)
            case .failure(let error):
                XCTFail("API Connection Error: \(error)")
            }
            expectation.fulfill()
        }

        // Wait for the expectation to be fulfilled
        waitForExpectations(timeout: 5, handler: nil)
    }


    override func setUp() {
        super.setUp()
        // Perform any setup, if needed, for your tests
    }

    override func tearDown() {
        super.tearDown()
        // Perform any cleanup, if needed, for your tests
    }
}
