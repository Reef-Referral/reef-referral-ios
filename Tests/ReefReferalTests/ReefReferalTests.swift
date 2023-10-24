import XCTest
@testable import ReefReferral

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
        let handleDeeplinkExpectation = expectation(description: "Handle deeplink Expectation")
        let notifyReferralSuccessExpectation = expectation(description: "Notify Referral success Expectation")
        let checkReferralStatusExpectation = expectation(description: "Check Referral status Expectation")
        let deleteExpectation = expectation(description: "Delete link Expectation")

        Task {
            do {
                let generateResult = try await generateLink()
                generateExpectation.fulfill()
                
                let handleDeepLinkResult = try await handleDeepLink(linkId: generateResult.link.id)
                handleDeeplinkExpectation.fulfill()
                
                try await notifyReferralSuccess(referralId: handleDeepLinkResult.referral.id)
                notifyReferralSuccessExpectation.fulfill()
                
                try await checkReferralStatus(linkId: generateResult.link.id)
                checkReferralStatusExpectation.fulfill()
                
                try await deleteLink(linkId: generateResult.link.id)
                deleteExpectation.fulfill()
                
            } catch let error {
                XCTFail("\(error)")
            }
        }
        
        let result = XCTWaiter().wait(for: [generateExpectation,
                                            handleDeeplinkExpectation,
                                            notifyReferralSuccessExpectation,
                                            checkReferralStatusExpectation,
                                            deleteExpectation],
                                      timeout: 10)
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
    
    func handleDeepLink(linkId: String) async throws -> Referral {
        let response = await ReefAPIClient.shared.send(HandleDeepLinkRequest(link_id: linkId, udid: "simulator_test"))
        switch response {
        case .success(let result):
            XCTAssertNotNil(result)
            return result
        case .failure(let error):
            throw error
        }
    }
    
    func notifyReferralSuccess(referralId: String) async throws {
        let response = await ReefAPIClient.shared.send(NotifyReferralSuccessRequest(referral_id: referralId))
        switch response {
        case .success(let result):
            XCTAssertNotNil(result)
            return
        case .failure(let error):
            throw error
        }
    }
    
    func checkReferralStatus(linkId: String) async throws {
        let response = await ReefAPIClient.shared.send(ReferralStatusesRequest(link_id: linkId))
        switch response {
        case .success(let result):
            XCTAssertNotNil(result)
            return
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
