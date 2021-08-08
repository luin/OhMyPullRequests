//
//  MenuFactory.swift
//  OhMyPullRequests
//
//  Created by Zihua Li on 2021/8/7.
//

import Cocoa
import OctoKit
import SwiftyUserDefaults

protocol DropdownMenuDelegate: NSObject {
    func loginWindowShouldOpen(_ sender: Any) -> Void
}

class DropdownMenu: NSMenu {
    weak var actionDelegate: DropdownMenuDelegate?
    
    func set(pullRequests: [PullRequestManager.InterestedPullRequest]) {
        removeAllItems()
        
        pullRequests.enumerated().forEach { (index, pr) in
            let title = pr.data.title ?? "Untitled"
            let menuItem = NSMenuItem(title: title, action: #selector(prMenuItemClick(_:)), keyEquivalent: "")
            menuItem.target = self
            menuItem.representedObject = pr.data.htmlURL
            if pr.isMine {
                menuItem.attributedTitle = NSAttributedString(string: title, attributes: [NSAttributedString.Key.foregroundColor: NSColor(named: "myPr")!])
            }
            addItem(menuItem)
        }
        
        addAdditionalLinks()
        addGeneral()
    }
    
    private func addAdditionalLinks() {
        if !items.isEmpty {
            addItem(NSMenuItem.separator())
        }
        
        let links = Defaults.links.split(whereSeparator: \.isNewline).map { $0.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: "|", maxSplits: 2, omittingEmptySubsequences: false) }
        links.forEach {
            if $0.count == 2 {
                let title = $0[0].trimmingCharacters(in: .whitespacesAndNewlines)
                let link = $0[1].trimmingCharacters(in: .whitespacesAndNewlines)
                let menuItem = NSMenuItem(title: title, action: #selector(linkItemClick(_:)), keyEquivalent: "")
                menuItem.representedObject = link
                menuItem.target = self
                addItem(menuItem)
            }
        }
    }
    
    private func addGeneral() {
        if !items.isEmpty {
            addItem(NSMenuItem.separator())
        }
        
        let loginMenuItem = NSMenuItem(title: "Login...", action: #selector(preferencesItemClick(_:)), keyEquivalent: ",")
        loginMenuItem.target = self
        if TokenManager.shared.get() != nil {
            loginMenuItem.title = "Preferences..."
        }
        addItem(loginMenuItem)
        addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
    }
    
    
    @objc func prMenuItemClick(_ sender: Any) {
        if let menuItem = sender as? NSMenuItem, let link = menuItem.representedObject as? URL {
            NSWorkspace.shared.open(link)
        }
    }
    
    @objc func preferencesItemClick(_ sender: Any) {
        actionDelegate?.loginWindowShouldOpen(sender)
    }
    
    @objc func linkItemClick(_ sender: Any) {
        if let menuItem = sender as? NSMenuItem, let link = menuItem.representedObject as? String, let url = URL(string: link) {
            NSWorkspace.shared.open(url)
        }
    }
}
