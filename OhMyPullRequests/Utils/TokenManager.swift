//
//  TokenManager.swift
//  OhMyPullRequests
//
//  Created by Zihua Li on 2021/8/7.
//

import Foundation
import KeychainSwift

fileprivate let TOKEN_KEY = "GitHub Personal Token"

class TokenManager {
    static let shared: TokenManager = TokenManager()
    
    let keychain = KeychainSwift()

    private init() {}
    private var token: String?
    
    func get() -> String? {
        keychain.get(TOKEN_KEY)
    }
    
    func set(_ token: String) {
        keychain.set(token, forKey: TOKEN_KEY)
    }
}
