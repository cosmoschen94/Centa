import Vapor
import Fluent
import Foundation

final class Trip: Model {
    var id: Node?
    var uid: String // TODO: Make it unique
    var name: String
    var info: String
    var exists: Bool = false
    
    init(name: String, info: String) {
        self.uid = genUid()
        self.name = name
        self.info = info
    }
    
    init(node: Node, in context: Context) throws {
        id = try node.extract("id")
        uid = try node.extract("uid") ?? genUid()
        name = try node.extract("name")
        info = try node.extract("info")
    }
    
    func makeNode(context: Context) throws -> Node {
        return try Node(node: [
            "id": id,
            "uid": uid,
            "name": name,
            "info": info
            ])
    }
    
    func merge(from trip: Trip) {
        name = trip.name
        info = trip.info
    }
}

extension Trip {
    func users() throws -> Siblings<User> {
        return try siblings()
    }
}

extension Trip: Preparation {
    static func prepare(_ database: Database) throws {
        try database.create("trips") { trips in
            trips.id()
            trips.string("uid")
            trips.string("name")
            trips.string("info")
        }
    }
    
    static func revert(_ database: Database) throws {
        try database.delete("trips")
    }
}
