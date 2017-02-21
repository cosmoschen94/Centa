//
//  UserController.swift
//  Centa
//
//  Created by Shawn Gong on 11/6/16.
//
//

import Foundation

import Vapor
import HTTP
import Auth
import Turnstile

final class UserController {

    func register(_ request: Request) throws -> ResponseRepresentable {
        guard let email = request.data[Prop.email]?.string,
            let password = request.data[Prop.password]?.string else
        {
            throw Abort.custom(status: Status.badRequest, message: "Missing email or password")
        }

        let credentials = UsernamePassword(username: email,
                                           password: password)

        // Try to register the user
        do {
            let user = try User.register(credentials: credentials) as? User
            if var user = user,
                let name = request.data[Prop.name]?.string
            {
                user.name = name
                try user.save()
            }
            try request.auth.login(credentials)

            return try JSON(node: AuthUserModel(request.user()).makeNode())

        } catch let e as TurnstileError {
            throw Abort.custom(status: Status.badRequest, message: e.description)
        }
    }

    func login(_ request: Request)throws -> ResponseRepresentable {
        guard let email = request.data[Prop.email]?.string,
            let password = request.data[Prop.password]?.string else
        {
                throw Abort.custom(status: Status.badRequest, message: "Missing email or password")
        }

        let credentials = UsernamePassword(username: email,
                                           password: password)

        do {
            try request.auth.login(credentials)
            return try JSON(node: AuthUserModel(request.user()).makeNode())

        } catch let e {
            throw Abort.custom(status: Status.badRequest, message: e.localizedDescription)
//            throw Abort.custom(status: Status.badRequest, message: "Invalid username or password")
        }
    }

    func logout(request: Request) throws -> ResponseRepresentable {
        // Invalidate the current access token
        var user = try request.user()
        user.token = ""
        try user.save()

        // Clear the session
        request.subject.logout()
        return Response()
    }

    func validateAccessToken(request: Request) throws -> ResponseRepresentable {
        var user = try request.user()
        guard !user.token.isEmpty else {
            throw Abort.badRequest
        }

        // ???
        // Check if the token is expired, or invalid and generate a new one
        if try user.validateToken() {
            try user.save()
        }

        return Response()
    }

    // MARK: Custom Endpoints

    func me(request: Request) throws -> ResponseRepresentable {
        return try JSON(node: request.user().makeNode())
    }
}

extension Request {

    // ???
    // Base URL returns the hostname, scheme, and port in a URL string form.
    var baseURL: String {
        return uri.scheme + "://" + uri.host + (uri.port == nil ? "" : ":\(uri.port!)")
    }

    // ???
    // Exposes the Turnstile subject, as Vapor has a facade on it.
    var subject: Subject {
        return storage["subject"] as! Subject
    }
}
