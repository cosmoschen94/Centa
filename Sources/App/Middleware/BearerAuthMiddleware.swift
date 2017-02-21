//
//  BearerAuthMiddleware.swift
//  JWTAuthentication
//
//  Created by Anthony Castelli on 11/12/16.
//
//

import Vapor
import HTTP
import Turnstile
import Auth
import JWT

class BearerAuthMiddleware: Middleware {
    func respond(to request: Request, chainingTo next: Responder) throws -> Response {

        // Authorization: Bearer Token
        if let accessToken = request.auth.header?.bearer {
            // Verify the token
            do {
                let receivedJWT = try JWT(token: accessToken.string)
                try receivedJWT.verifySignature(using:
                    HS256(key: User.accessTokenSigningKey))
                // Valide it's time stamp
                if receivedJWT.verifyClaims([ExpirationTimeClaim()]) {
                    try? request.auth.login(accessToken, persist: false)
                } else {
                    throw Abort.custom(status: .unauthorized, message: "Please reauthenticate with the server.")
                }
            } catch {
                throw Abort.custom(status: .unauthorized, message: "Please reauthenticate with the server.")
            }
        }

        return try next.respond(to: request)
    }
}
