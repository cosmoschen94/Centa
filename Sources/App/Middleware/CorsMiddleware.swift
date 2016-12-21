//
//  CorsMiddleware.swift
//  Centa
//
//  Created by Shawn Gong on 11/15/16.
//
//

import Foundation
import HTTP

final class CorsMiddleware: Middleware {
    func respond(to request: Request, chainingTo next: Responder) throws -> Response {
        let response: Response
        if request.isPreflight {
            response = "".makeResponse()
        } else {
            response = try next.respond(to: request)
        }
        
        response.headers["Access-Control-Allow-Origin"] = request.headers["Origin"] ?? "*";
        response.headers["Access-Control-Allow-Headers"] = "X-Requested-With, Origin, Content-Type, Accept"
        response.headers["Access-Control-Allow-Methods"] = "POST, GET, PUT, OPTIONS, DELETE, PATCH"
        return response
    }
}

extension Request {
    var isPreflight: Bool {
        return method == .options
            && headers["Access-Control-Request-Method"] != nil
    }
}
