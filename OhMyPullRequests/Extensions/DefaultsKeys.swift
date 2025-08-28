import Foundation
import SwiftyUserDefaults

extension DefaultsKeys {
  var settings: DefaultsKey<String> { .init("settings", defaultValue: "{\n  \"repos\": [],\n  \"quickLinks\": [{\n    \"title\": \"Oh My Pull Requests\",\n    \"url\": \"https://github.com/luin/ohmypullrequests\"\n  }]\n}") }
}
