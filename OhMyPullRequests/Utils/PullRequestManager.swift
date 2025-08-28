//
//  PullRequestManager.swift
//  OhMyPullRequests
//
//  Created by Zihua Li on 2021/8/7.
//

import Foundation
import RequestKit
import AsyncHTTPClient
import NIO
import SwiftyJSON

enum GitHubItemReason {
  case toRequestReviewers
  case toAddressFeddbacks
  case toReview
}

struct GitHubItem {
  var title: String
  var repo: String
  var url: String
  var reason: GitHubItemReason
}

let MY_PRS = """
  query {
    search(first: 100, type: ISSUE, query: "is:pr is:open author:@me draft:false") {
      edges {
        node {
          __typename
          ... on PullRequest {
            title
            url
            repository {
              nameWithOwner
            }
            latestReviews(first: 10) {
              edges {
                node {
                  id
                  state
                  author {
                    login
                  }
                }
              }
            }
            reviewRequests(first: 1) {
              __typename
              nodes {
                id
                requestedReviewer {
                  __typename
                }
              }
            }
          }
        }
      }
    }
  }
  """

let OTHER_PRS = """
  query {
    search(first: 100, type: ISSUE, query: "is:pr is:open review-requested:@me draft:false") {
      edges {
        node {
          __typename
          ... on PullRequest {
            title
            url
            repository {
              nameWithOwner
            }
            latestReviews(first: 10) {
              edges {
                node {
                  id
                  state
                  author {
                    login
                  }
                }
              }
            }
            reviewRequests(first: 1) {
              __typename
              nodes {
                id
                requestedReviewer {
                  __typename
                }
              }
            }
          }
        }
      }
    }
  }
  """


protocol PullRequestManagerDelegate: NSObject {
  func pullRequestsFetched(_ prs: [GitHubItem]) -> Void
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
  
  let settings: Settings
  var timer: Timer?
  let token: String
  var myLogin: String?
  weak var delegate: PullRequestManagerDelegate?
  
  init(token: String, settings: Settings) {
    self.token = token
    self.settings = settings
    self.timer?.fire()
  }
  
  deinit {
    timer?.invalidate()
  }
  
  
  @MainActor
  private func searchPullRequests(query: String) async -> [JSON]? {
    var request = HTTPClientRequest(url: "https://api.github.com/graphql")
    request.method = .POST
    request.headers.add(name: "User-Agent", value: "OhMyPullRequest Client 1.0")
    request.headers.add(name: "Authorization", value: "bearer \(token)")
    let bodyJSON = JSON(["query": query] as [String: Any?])
    request.body = .bytes(ByteBuffer(string: bodyJSON.rawString()!))
    
    if let requestBody = bodyJSON.rawString() {
      request.body = .bytes(ByteBuffer(string: requestBody))
      
      if let response = try? await HTTPClient.shared.execute(request, timeout: .seconds(30)),
         var byteBuffer = try? await response.body.collect(upTo: 10 * 1024 * 1024),
         let data = byteBuffer.readData(length: byteBuffer.readableBytes),
         let json = try? JSON(data: data),
         let edges = json["data"]["search"]["edges"].array {
        return edges.map { $0["node"] }
      }
    }
      
    return nil
  }
  
  private func toGitHubItem(json: JSON, reason: GitHubItemReason) -> GitHubItem {
    GitHubItem(title: json["title"].stringValue, repo: json["repository"]["nameWithOwner"].stringValue, url: json["url"].stringValue, reason: reason)
  }
  
  @MainActor
  private func reloadData() async {
    var prs: [GitHubItem] = []
    
    async let myPRItems = searchPullRequests(query: MY_PRS)
    async let otherPRItems = searchPullRequests(query: OTHER_PRS)
    
    let itemGroups = await [myPRItems, otherPRItems]
    
    if let items = itemGroups.first {
      items?.forEach {
        let hasNoReviewerRequested = $0["reviewRequests"].array?.count == 0
        let hasReceivedReviews = $0["latestReviews"]["edges"].arrayValue.contains(where: {
          let state = $0["node"]["state"].stringValue
          return state == "COMMENTED" || state == "APPROVED" || state == "CHANGES_REQUESTED"
        })
        
        if hasNoReviewerRequested {
          prs.append(toGitHubItem(json: $0, reason: .toRequestReviewers))
        } else if hasReceivedReviews {
          prs.append(toGitHubItem(json: $0, reason: .toAddressFeddbacks))
        }
      }
    }
    
    if let items = itemGroups.last {
      items?.forEach {
        if $0["title"].string != nil {
          prs.append(toGitHubItem(json: $0, reason: .toReview))
        }
      }
    }
    
    if !settings.repos.isEmpty {
      prs = prs.filter {
        let repo = $0.repo
        return settings.repos.contains(where: { repo.hasPrefix($0) })
      }
    }
    
    self.delegate?.pullRequestsFetched(prs)
  }
  
  func start() {
    timer = Timer.scheduledTimer(withTimeInterval: 6, repeats: true) { [weak self] _ in
      Task {
        _ = await self?.reloadData()
      }
    }
  }
  
  func fire() {
    timer?.fire()
  }
}
