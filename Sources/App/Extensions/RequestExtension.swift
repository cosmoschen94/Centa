//
//  RequestExtension.swift
//  Centa
//
//  Created by Shawn Gong on 11/20/16.
//
//

import Foundation
import HTTP

extension HTTP.Request {
    func idFromReferer() -> String? {
        guard let referer = headers["Referer"] else { return nil }
        let comps = referer.components(separatedBy: "/")
        guard comps.count >= 2 && comps[comps.count - 2] == "id" else { return nil }
        return comps.last
    }
}
