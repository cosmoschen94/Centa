//
//  Prop.swift
//  Centa
//
//  Created by Shawn Gong on 2/18/17.
//
//

struct Prop {
    // Common
    static let id = "id"
    static let uid = "uid"

    // User
    static let name = "name"
    static let email = "email"
    static let password = "password"
    static let salt = "salt"
    static let token = "token"

    // Trip
    static let title = "title"
    static let date = "date"
    static let address = "address"
    static let info = "info"
    static let owningUsers = "owningUsers"
    static let joinedUsers = "joinedUsers"

    // TripUser
    static let tripId = "trip_id"
    static let userId = "user_id"
    static let relation = "relation"

    // Entity names
    static let trips = "trips"
    static let users = "users"
    static let tripUser = "trip_user"
}
