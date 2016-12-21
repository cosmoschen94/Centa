import Vapor
import Fluent
import Foundation

final class User: Model {
    var id: Node?
    var uid: String
    var name: String
    var exists: Bool = false
    
    init(name: String) {
        self.uid = genUid()
        self.name = name
    }
    
    init(node: Node, in context: Context) throws {
        id = try node.extract("id")
        uid = try node.extract("uid") ?? genUid()
        name = try node.extract("name")
    }
    
    func makeNode(context: Context) throws -> Node {
        return try Node(node: [
            "id": id,
            "uid": uid,
            "name": name,
            ])
    }
}

extension User {
    func trips() throws -> Siblings<Trip> {
        return try siblings()
    }
}

extension User: Preparation {
    static func prepare(_ database: Database) throws {
        try database.create("users") { users in
            users.id()
            users.string("uid")
            users.string("name")
        }
    }
    
    public static func revert(_ database: Database) throws {
        try database.delete("users")
    }
}
