import Foundation

public protocol HTTPClient {
    func execute(request: URLRequest) async throws -> (Data, HTTPURLResponse)
}
