import Cocoa
import SwiftyUserDefaults
import LaunchAtLogin

protocol LoginWindowControllerDelegate: NSObject {
  func settingUpdated(_ sender: Any) -> Void
}

class LoginWindowController: NSWindowController {
  @IBOutlet private var tokenTextField: NSSecureTextField!
  @IBOutlet private var okButton: NSButton!
  @IBOutlet var settingsTextView: NSTextView!
  @IBOutlet var launchAtLoginButton: NSButton!
  
  weak var delegate: LoginWindowControllerDelegate?
  
  override func windowDidLoad() {
    super.windowDidLoad()
    
    tokenTextField.delegate = self
    
    tokenTextField.stringValue = TokenManager.shared.get() ?? ""
    settingsTextView.string = Defaults.settings
    launchAtLoginButton.state = LaunchAtLogin.isEnabled ? .on : .off
    
    settingsTextView.font = NSFont.monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
    settingsTextView.isAutomaticQuoteSubstitutionEnabled = false
  }
  
  @IBAction private func cancelButtonClick(_ sender: Any) {
    close()
  }
  
  @IBAction private func OKButtonClick(_ sender: Any) {
    Defaults.settings = settingsTextView.string
    TokenManager.shared.set(tokenTextField.stringValue)
    delegate?.settingUpdated(sender)
    LaunchAtLogin.isEnabled = launchAtLoginButton.state == .on
    close()
  }
}

extension LoginWindowController: NSTextFieldDelegate {
  func controlTextDidChange(_ obj: Notification) {
    okButton.isEnabled = !tokenTextField.stringValue.isEmpty
  }
}
