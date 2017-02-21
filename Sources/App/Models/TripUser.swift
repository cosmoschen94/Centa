//
//  TripUser.swift
//  Centa
//
//  Created by Shawn Gong on 2/17/17.
//
//

import Vapor
import Fluent

/**

 Discussion: Multiple owner? 1 owner and multiple admin? Admin expires?
 
 Trip's join, watch, quit rules:
 1. Only 1 row per trip & user
 2. Find existing row & update relation
 3. If non-existing, create
 4. When GET trip, query for all rows with the tripId, then separate the results to owningUsers & joinedUsers (& later number of watchers?)
 
 */
final class TripUser: Model {

    // Mutual exclusive
    enum Relation: String {
        case none, owning, watching, joined
    }

    // Used by Vapor Pivot
    static var entity = Prop.tripUser

    var id: Node?
    var exists: Bool = false

    var tripId: Node
    var userId: Node

    // enum Relation except none, which should delete the row
    var relation: String

    func makeNode(context: Context) throws -> Node {
        return try Node(node: [
            Prop.id: id,
            Prop.tripId: tripId,
            Prop.userId: userId,
            Prop.relation: relation,
            ])
    }

    init(tripId: Node, userId: Node, relation: Relation) {
        self.tripId = tripId
        self.userId = userId
        self.relation = relation.rawValue
    }

    init(node: Node, in context: Context) throws {
        self.id = try node.extract(Prop.id)
        self.tripId = try node.extract(Prop.tripId)
        self.userId = try node.extract(Prop.userId)
        self.relation = try node.extract(Prop.relation)
    }
}

extension TripUser: Preparation {
    static func prepare(_ database: Database) throws {
        try database.create(Prop.tripUser) { tripUser in
            tripUser.id()
            tripUser.int(Prop.tripId)
            tripUser.int(Prop.userId)
            tripUser.string(Prop.relation)
        }
    }

    static func revert(_ database: Database) throws {
        try database.delete(Prop.tripUser)
    }
}

extension Trip {
    func owningUsers() throws -> [User] {
        guard let id = id else { return [] }

        return try User.query()
            .union(TripUser.self, localKey: Prop.id, foreignKey: Prop.userId)
            .filter(TripUser.self, Prop.tripId, id)
            .filter(TripUser.self, Prop.relation, TripUser.Relation.owning.rawValue)
            .all()
    }

    func joinedUsers() throws -> [User] {
        guard let id = id else { return [] }

        return try User.query()
            .union(TripUser.self, localKey: Prop.id, foreignKey: Prop.userId)
            .filter(TripUser.self, Prop.tripId, id)
            .filter(TripUser.self, Prop.relation, TripUser.Relation.joined.rawValue)
            .all()
    }

    func upsertUser(_ userUid: String, relation: TripUser.Relation) throws {
        guard let tripId = id,
            let user = try User.find(uid: userUid),
            let userId = user.id else
        {
            return
        }

        // Existing
        if var tripUser = try TripUser.query()
            .filter(Prop.tripId, tripId)
            .filter(Prop.userId, userId)
            .first()
        {
            // Delete relation
            if relation == TripUser.Relation.none {
                try tripUser.delete()
                return
            }

            // Update relation
            tripUser.relation = relation.rawValue
            try tripUser.save()
            return
        }

        // Non-existing

        // Delete is no-op
        guard relation != TripUser.Relation.none else { return }

        // Save new relation
        var newTripUser = TripUser(tripId: tripId, userId: userId, relation: relation)
        try newTripUser.save()
    }
}

extension User {
    func trips() throws -> [Trip] {
        guard let id = id else { return [] }

        return try Trip.query()
            .union(TripUser.self, localKey: Prop.id, foreignKey: Prop.tripId)
            .filter(TripUser.self, Prop.userId, id)
            .all()
    }

    func owningTrips() throws -> [Trip] {
        guard let id = id else { return [] }

        return try Trip.query()
            .union(TripUser.self, localKey: Prop.id, foreignKey: Prop.tripId)
            .filter(TripUser.self, Prop.userId, id)
            .filter(TripUser.self, Prop.relation, TripUser.Relation.owning.rawValue)
            .all()
    }

    func joinedTrips() throws -> [Trip] {
        guard let id = id else { return [] }

        return try Trip.query()
            .union(TripUser.self, localKey: Prop.id, foreignKey: Prop.tripId)
            .filter(TripUser.self, Prop.userId, id)
            .filter(TripUser.self, Prop.relation, TripUser.Relation.joined.rawValue)
            .all()
    }

    func watchingTrips() throws -> [Trip] {
        guard let id = id else { return [] }

        return try Trip.query()
            .union(TripUser.self, localKey: Prop.id, foreignKey: Prop.tripId)
            .filter(TripUser.self, Prop.userId, id)
            .filter(TripUser.self, Prop.relation, TripUser.Relation.watching.rawValue)
            .all()
    }
}
