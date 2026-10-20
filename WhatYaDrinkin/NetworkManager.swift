//
//  NetworkManager.swift
//  WhatYaDrinkin
//
//  Created by Dani on 2026. 09. 06..
//

import Foundation

enum NetworkError: Error {
    case invalidURL
    case invalidResponse
    case invalidData
}

final class NetworkManager {
    static let shared = NetworkManager()
    private init() {}
    
    func get<T: Codable>(url: String, object: T.Type) async throws -> T {
        guard let url = URL(string: url) else {
            throw NetworkError.invalidURL
        }
        
        let headers = [
            "apikey": Secret.apiKeys.database.rawValue,
            "Authorization": "Bearer " + Secret.apiKeys.database.rawValue,
            "Content-Type": "application/json"
        ]
        
        var urlRequest = URLRequest(url: url)
        for (f, v) in headers {
            urlRequest.addValue(v, forHTTPHeaderField: f)
        }
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NetworkError.invalidResponse
        }
        
        do {
            if T.self == Data.self {
                return data as! T
            } else {
                return try JSONDecoder().decode(T.self, from: data)
            }
        } catch {
            throw NetworkError.invalidData
        }
    }
}
