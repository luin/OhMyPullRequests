//
//  AppDelegate.swift
//  OhMyPullRequests
//
//  Created by Zihua Li on 2021/8/7.
//

import Cocoa
import KeychainSwift
import SwiftyUserDefaults
import OctoKit

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
        statusItem.menu = menu
        
        updatePullRequestManager()
    }
        
    func updatePullRequestManager() {
        if let token = TokenManager.shared.get() {
            pullRequestManager = PullRequestManager(token: token, repo: Defaults.repository)
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
    func pullRequestsFetched(_ prs: [PullRequestManager.InterestedPullRequest]) {
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
