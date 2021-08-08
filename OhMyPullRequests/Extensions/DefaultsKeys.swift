//
//  DefaultsKeys.swift
//  OhMyPullRequests
//
//  Created by Zihua Li on 2021/8/7.
//

import Foundation
import SwiftyUserDefaults

extension DefaultsKeys {
    var repository: DefaultsKey<String> { .init("repository", defaultValue: "") }
    var links: DefaultsKey<String> { .init("links", defaultValue: "Homepage|https://github.com/luin/OhMyPullRequests") }
}
