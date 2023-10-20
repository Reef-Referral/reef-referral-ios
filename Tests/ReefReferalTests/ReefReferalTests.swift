import XCTest
@testable import ReefReferal

class ReefReferalTests: XCTestCase {

    // Test the "test_connection" endpoint
    func testTestConnection() {
        let expectation = expectation(description: "API Connection Expectation")
        let testConnectionRequest = ReferralTestConnectionRequest(app_id: "f342a916-d682-4798-979e-873a74cc0b33")

        Task {
            let result = await ReefAPIClient.shared.send(testConnectionRequest)
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
    
    func testGenerateLink() {
        let generateExpectation = expectation(description: "AGenerate link Expectation")
        let deleteExpectation = expectation(description: "Delete link Expectation")
        
        Task {
            do {
                let generateResult = try await generateLink()
                try await deleteLink(linkId: generateResult.link.id)
            } catch let error {
                XCTFail("\(error)")
            }
            
            generateExpectation.fulfill()
            deleteExpectation.fulfill()
        }
        
        let result = XCTWaiter().wait(for: [generateExpectation, deleteExpectation], timeout: 5)
        XCTAssertEqual(result, .completed)
    }

    func generateLink() async throws -> ReferralLink {
        let response = await ReefAPIClient.shared.send(ReferralLinkRequest(app_id: "f342a916-d682-4798-979e-873a74cc0b33"))
        switch response {
        case .success(let result):
            XCTAssertNotNil(result)
            return result
        case .failure(let error):
            throw error
        }
    }

    func deleteLink(linkId: String) async throws {
        let response = await ReefAPIClient.shared.send(ReferralLinkDeleteRequest(link_id: linkId))
        switch response {
        case .success(let result):
            XCTAssertNotNil(result)
            return
        case .failure(let error):
            throw error
        }
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
