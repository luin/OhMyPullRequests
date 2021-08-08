//
//  PullRequestManager.swift
//  OhMyPullRequests
//
//  Created by Zihua Li on 2021/8/7.
//

import Foundation
import OctoKit
import RequestKit

protocol PullRequestManagerDelegate: NSObject {
    func pullRequestsFetched(_ prs: [PullRequestManager.InterestedPullRequest]) -> Void
}

class PullRequestManager {
    struct Repo {
        var owner: String
        var repository: String
        
        static func from(string: String) -> Self? {
            let parts = string.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: "/")
            if parts.count != 2 {
                return nil
            }
            return Repo(owner: String(parts[0]), repository: String(parts[1]))
        }
    }
    
    struct InterestedPullRequest {
        var data: PullRequest
        var isMine: Bool
    }
    
    let client: Octokit
    let repo: String
    var timer: Timer?
    var myLogin: String?
    weak var delegate: PullRequestManagerDelegate?
    
    init(token: String, repo: String) {
        let config = TokenConfiguration(token)
        client = Octokit(config)
        self.repo = repo
        
        client.me {
            if case let .success(user) = $0 {
                self.myLogin = user.login
                self.timer?.fire()
            }
        }
    }
    
    deinit {
        timer?.invalidate()
    }
    
    private func needMyReview(_ pr: PullRequest) -> Bool {
        (pr.requestedReviewers ?? []).contains { $0.login == myLogin }
    }
    
    private func isIdle(_ pr: PullRequest) -> Bool {
        pr.user?.login == myLogin && (pr.requestedReviewers ?? []).isEmpty
    }
    
    private func reloadData() {
        pullRequests { [weak self] in
            guard let self = self else {
                return
            }
            
            switch $0 {
            case .success(let pullRequests):
                self.delegate?.pullRequestsFetched(pullRequests)
            case .failure(let error):
                debugPrint(error)
            }
        }
    }
    
    private func pullRequests(completion: @escaping (Response<[InterestedPullRequest]>) -> Void) {
        var error: Error?
        let dispatchGroup = DispatchGroup()
        var interested: [InterestedPullRequest] = []
        let repos = repo.split(separator: ",").compactMap { Repo.from(string: String($0)) }
        repos.forEach {
            dispatchGroup.enter()
            
            client.pullRequests(owner: String($0.owner), repository: String($0.repository), state: .open) { response in
                DispatchQueue.main.async {
                    defer {
                        dispatchGroup.leave()
                    }
                    switch response {
                    case .success(let prs):
                        prs.filter(self.needMyReview(_:)).forEach { interested.append(InterestedPullRequest(data: $0, isMine: false)) }
                        prs.filter(self.isIdle(_:)).forEach { interested.append(InterestedPullRequest(data: $0, isMine: true)) }
                    case .failure(let reason):
                        error = reason
                        break
                    }
                }
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            if let error = error {
                completion(Response.failure(error))
            } else {
                completion(Response.success(interested))
            }
        }
    }
    
    func start() {
        timer = Timer.scheduledTimer(withTimeInterval: 6, repeats: true) { [weak self] _ in
            self?.reloadData()
        }
    }
    
    func fire() {
        timer?.fire()
    }
}
