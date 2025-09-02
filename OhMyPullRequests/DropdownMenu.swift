import Cocoa
import SwiftyUserDefaults

protocol DropdownMenuDelegate: NSObject {
  func loginWindowShouldOpen(_ sender: Any) -> Void
}

class DropdownMenu: NSMenu {
  weak var actionDelegate: DropdownMenuDelegate?
  var quickLinks: [QuickLink] = []
  
  func addMenuItemGroup(_ items: [GitHubItem], title: String) {
    if !items.isEmpty {
      let titleMenuItem = NSMenuItem.sectionHeader(title: title)
      addItem(titleMenuItem)
      
      items.forEach {
        let menuItem = NSMenuItem(title: $0.title, action: #selector(prMenuItemClick(_:)), keyEquivalent: "")
        menuItem.target = self
        menuItem.representedObject = $0.url
        addItem(menuItem)
      }
    }
  }
  
  func set(pullRequests: [GitHubItem]) {
    removeAllItems()
    
    addMenuItemGroup(pullRequests.filter { $0.reason == .toPublish }, title: "To Publish")
    addMenuItemGroup(pullRequests.filter { $0.reason == .toAddressFeddbacks }, title: "To Address Feedbacks")
    addMenuItemGroup(pullRequests.filter { $0.reason == .toMerge }, title: "To Merge")
    addMenuItemGroup(pullRequests.filter { $0.reason == .toRequestReviewers }, title: "To Request Reviewers")
    addMenuItemGroup(pullRequests.filter { $0.reason == .toReview }, title: "To Review")
    
    addAdditionalLinks()
    addGeneral()
  }
  
  private func addAdditionalLinks() {
    if !items.isEmpty {
      addItem(NSMenuItem.separator())
    }
    
    quickLinks.forEach {
      let menuItem = NSMenuItem(title: $0.title, action: #selector(linkItemClick(_:)), keyEquivalent: "")
      menuItem.representedObject = $0.url
      menuItem.target = self
      addItem(menuItem)
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
    if let menuItem = sender as? NSMenuItem, let link = menuItem.representedObject as? String, let url = URL(string: link) {
      NSWorkspace.shared.open(url)
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
