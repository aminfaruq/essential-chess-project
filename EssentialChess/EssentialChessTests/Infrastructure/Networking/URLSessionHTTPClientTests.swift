//
//  URLSessionHTTPClientTests.swift
//  EssentialChess
//
//  Created by Amin faruq on 07/07/26.
//

import XCTest
import EssentialChess

final class URLSessionHTTPClientTests: XCTestCase {

    override func setUp() {
        super.setUp()
        URLProtocolStub.startInterceptingRequests()
    }

    override func tearDown() {
        super.tearDown()
        URLProtocolStub.stopInterceptingRequests()
    }

    // MARK: - Request

    func test_get_performsGETRequestWithURL() {
        let url = anyURL()
        let exp = expectation(description: "Wait for request")

        URLProtocolStub.observeRequests { request in
            XCTAssertEqual(request.url, url)
            XCTAssertEqual(request.httpMethod, "GET")
            exp.fulfill()
        }

        makeSUT().get(from: url) { _ in }

        wait(for: [exp], timeout: 1.0)
    }

    // MARK: - Headers

    func test_get_withHeaders_addsAllHeadersToRequest() {
        let exp = expectation(description: "Wait for request")

        URLProtocolStub.observeRequests { request in
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer token123")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Accept"), "application/json")
            exp.fulfill()
        }

        makeSUT().get(from: anyURL(), headers: ["Authorization": "Bearer token123", "Accept": "application/json"]) { _ in }

        wait(for: [exp], timeout: 1.0)
    }

    func test_get_withNilHeaders_doesNotAddCustomHeaders() {
        let exp = expectation(description: "Wait for request")

        URLProtocolStub.observeRequests { request in
            XCTAssertNil(request.value(forHTTPHeaderField: "Authorization"))
            exp.fulfill()
        }

        makeSUT().get(from: anyURL(), headers: nil) { _ in }

        wait(for: [exp], timeout: 1.0)
    }

    func test_get_withEmptyHeaders_doesNotAddCustomHeaders() {
        let exp = expectation(description: "Wait for request")

        URLProtocolStub.observeRequests { request in
            XCTAssertNil(request.value(forHTTPHeaderField: "Authorization"))
            exp.fulfill()
        }

        makeSUT().get(from: anyURL(), headers: [:]) { _ in }

        wait(for: [exp], timeout: 1.0)
    }

    // MARK: - Success

    func test_get_succeedsOnHTTPURLResponseWithData() {
        let data = anyData()
        let response = anyHTTPURLResponse()

        let receivedValues = resultValuesFor(data: data, response: response, error: nil)

        XCTAssertEqual(receivedValues?.data, data)
        XCTAssertEqual(receivedValues?.response.url, response.url)
        XCTAssertEqual(receivedValues?.response.statusCode, response.statusCode)
    }

    func test_get_succeedsWithEmptyDataOnHTTPURLResponseWithNilData() {
        let response = anyHTTPURLResponse()

        let receivedValues = resultValuesFor(data: nil, response: response, error: nil)

        XCTAssertEqual(receivedValues?.data, Data())
        XCTAssertEqual(receivedValues?.response.url, response.url)
        XCTAssertEqual(receivedValues?.response.statusCode, response.statusCode)
    }

    // MARK: - Failure

    func test_get_failsOnRequestError() {
        let requestError = anyNSError()

        let receivedError = resultErrorFor(data: nil, response: nil, error: requestError)

        XCTAssertEqual(receivedError?.domain, requestError.domain)
        XCTAssertEqual(receivedError?.code, requestError.code)
    }

    func test_get_failsOnAllInvalidRepresentationCases() {
        XCTAssertNotNil(resultErrorFor(data: nil, response: nil, error: nil))
        XCTAssertNotNil(resultErrorFor(data: nil, response: nonHTTPURLResponse(), error: nil))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: nil, error: nil))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: nil, error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: nil, response: nonHTTPURLResponse(), error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: nil, response: anyHTTPURLResponse(), error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: nonHTTPURLResponse(), error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: anyHTTPURLResponse(), error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: nonHTTPURLResponse(), error: nil))
    }

    // MARK: - Helpers

    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> HTTPClient {
        let sut = URLSessionHTTPClient()
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }

    private func resultFor(data: Data?, response: URLResponse?, error: Error?, file: StaticString = #filePath, line: UInt = #line) -> HTTPClient.Result {
        URLProtocolStub.stub(data: data, response: response, error: error)
        let sut = makeSUT(file: file, line: line)
        let exp = expectation(description: "Wait for completion")

        var receivedResult: HTTPClient.Result!
        sut.get(from: anyURL()) { result in
            receivedResult = result
            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.0)
        return receivedResult
    }

    private func resultValuesFor(data: Data?, response: URLResponse?, error: Error?, file: StaticString = #filePath, line: UInt = #line) -> (data: Data, response: HTTPURLResponse)? {
        let result = resultFor(data: data, response: response, error: error, file: file, line: line)

        switch result {
        case let .success((data, response)):
            return (data, response)
        default:
            XCTFail("Expected success, got \(result) instead", file: file, line: line)
            return nil
        }
    }

    private func resultErrorFor(data: Data?, response: URLResponse?, error: Error?, file: StaticString = #filePath, line: UInt = #line) -> NSError? {
        let result = resultFor(data: data, response: response, error: error, file: file, line: line)

        switch result {
        case let .failure(error):
            return error as NSError
        default:
            XCTFail("Expected failure, got \(result) instead", file: file, line: line)
            return nil
        }
    }

    private func anyURL() -> URL { URL(string: "http://any-url.com")! }
    private func anyData() -> Data { Data("any data".utf8) }
    private func anyNSError() -> NSError { NSError(domain: "any error", code: 1) }
    private func anyHTTPURLResponse() -> HTTPURLResponse { HTTPURLResponse(url: anyURL(), statusCode: 200, httpVersion: nil, headerFields: nil)! }
    private func nonHTTPURLResponse() -> URLResponse { URLResponse(url: anyURL(), mimeType: nil, expectedContentLength: 0, textEncodingName: nil) }
}

// MARK: - URLProtocolStub

private class URLProtocolStub: URLProtocol {
    private static var stub: Stub?
    private static var requestObserver: ((URLRequest) -> Void)?

    private struct Stub {
        let data: Data?
        let response: URLResponse?
        let error: Error?
    }

    static func stub(data: Data?, response: URLResponse?, error: Error?) {
        stub = Stub(data: data, response: response, error: error)
    }

    static func observeRequests(observer: @escaping (URLRequest) -> Void) {
        requestObserver = observer
    }

    static func startInterceptingRequests() {
        URLProtocol.registerClass(URLProtocolStub.self)
    }

    static func stopInterceptingRequests() {
        URLProtocol.unregisterClass(URLProtocolStub.self)
        stub = nil
        requestObserver = nil
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        if let requestObserver = URLProtocolStub.requestObserver {
            client?.urlProtocolDidFinishLoading(self)
            return requestObserver(request)
        }

        if let data = URLProtocolStub.stub?.data {
            client?.urlProtocol(self, didLoad: data)
        }
        if let response = URLProtocolStub.stub?.response {
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        }
        if let error = URLProtocolStub.stub?.error {
            client?.urlProtocol(self, didFailWithError: error)
        }
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

