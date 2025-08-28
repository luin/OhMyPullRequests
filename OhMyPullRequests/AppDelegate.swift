//
//  AppDelegate.swift
//  OhMyPullRequests
//
//  Created by Zihua Li on 2021/8/7.
//

import Cocoa
import KeychainSwift
import SwiftyUserDefaults
import SwiftyJSON

struct QuickLink {
  var title: String
  var url: String
}

struct Settings {
  var repos: [String]
  var quickLinks: [QuickLink]
}

@main
class AppDelegate: NSObject, NSApplicationDelegate {
  let menu = DropdownMenu()
  let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
  var pullRequestManager: PullRequestManager?
  lazy var loginWindowController = LoginWindowController(windowNibName: "LoginWindowController")
  
  func applicationDidFinishLaunching(_ aNotification: Notification) {
    if let button = statusItem.button {
      button.title = "..."
      button.image = NSImage(named: "github")
      button.imagePosition = .imageLeading
      button.imageScaling = .scaleProportionallyUpOrDown
    }
    menu.actionDelegate = self
    menu.set(pullRequests: [])
    statusItem.menu = menu
        
    updatePullRequestManager()
  }
  
  func updatePullRequestManager() {
    guard let data = Defaults.settings.data(using: .utf8, allowLossyConversion: false), let json = try? JSON(data: data) else {
      let anAlert = NSAlert()
      anAlert.messageText = "Invalid JSON"
      anAlert.informativeText = "Your JSON content: \(Defaults.settings)"
      anAlert.alertStyle = .critical
      anAlert.runModal()
      return
    }
    let settings = Settings(repos: json["repos"].arrayValue.map { $0.stringValue }, quickLinks: json["quickLinks"].arrayValue.compactMap {
      let title = $0["title"].string ?? "Untitled"
      if let url = $0["url"].string {
        return QuickLink(title: title, url: url)
      }
      return nil
    })
    menu.quickLinks = settings.quickLinks

    if let token = TokenManager.shared.get() {
      pullRequestManager = PullRequestManager(token: token, settings: settings)
      pullRequestManager?.delegate = self
      pullRequestManager?.start()
    } else {
      pullRequestManager = nil
    }
  }
  
  @IBAction func openLoginWindow(_ sender: Any) {
    NSApp.activate(ignoringOtherApps: true)
    
    loginWindowController.delegate = self
    loginWindowController.showWindow(sender)
  }
}

extension AppDelegate: PullRequestManagerDelegate {
  func pullRequestsFetched(_ prs: [GitHubItem]) {
    statusItem.button?.title = prs.count > 0 ? String(prs.count) : ""
    menu.set(pullRequests: prs)
  }
}

extension AppDelegate: DropdownMenuDelegate {
  func loginWindowShouldOpen(_ sender: Any) {
    openLoginWindow(sender)
  }
}

extension AppDelegate: LoginWindowControllerDelegate {
  func settingUpdated(_ sender: Any) {
    updatePullRequestManager()
  }
}
