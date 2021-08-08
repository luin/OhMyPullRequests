//
//  LoginWindowController.swift
//  OhMyPullRequests
//
//  Created by Zihua Li on 2021/8/7.
//

import Cocoa
import SwiftyUserDefaults

protocol LoginWindowControllerDelegate: NSObject {
    func settingUpdated(_ sender: Any) -> Void
}

class LoginWindowController: NSWindowController {
    @IBOutlet private var tokenTextField: NSSecureTextField!
    @IBOutlet private var repoTextField: NSTextField!
    @IBOutlet private var okButton: NSButton!
    @IBOutlet var additionalLinksTextView: NSTextView!
    
    weak var delegate: LoginWindowControllerDelegate?
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        tokenTextField.delegate = self
        repoTextField.delegate = self
        
        tokenTextField.stringValue = TokenManager.shared.get() ?? ""
        repoTextField.stringValue = Defaults.repository
        additionalLinksTextView.string = Defaults.links
    }
    
    @IBAction private func cancelButtonClick(_ sender: Any) {
        close()
    }
    
    @IBAction private func OKButtonClick(_ sender: Any) {
        Defaults.repository = repoTextField.stringValue
        Defaults.links = additionalLinksTextView.string
        TokenManager.shared.set(tokenTextField.stringValue)
        delegate?.settingUpdated(sender)
        close()
    }
}

extension LoginWindowController: NSTextFieldDelegate {
    func controlTextDidChange(_ obj: Notification) {
        okButton.isEnabled = !tokenTextField.stringValue.isEmpty && repoTextField.stringValue.contains("/")
    }
}
