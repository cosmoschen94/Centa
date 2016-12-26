import Vapor
import Fluent
import Foundation

final class Trip: Model {
    var id: Node?
    var uid: String // TODO: Make it unique
    var name: String
    // yyyy-mm-dd: 2016-12-24 can also do string compare correctly
    var date: String
    var address: String
    var info: String
    var exists: Bool = false
    
    init(name: String, date: String, address: String, info: String) {
        self.uid = genUid()
        self.name = name
        self.date = date
        self.address = address
        self.info = info
    }
    
    init(node: Node, in context: Context) throws {
        id = try node.extract("id")
        uid = try node.extract("uid") ?? genUid()
        name = try node.extract("name")
        date = try node.extract("date")
        address = try node.extract("address")
        info = try node.extract("info")
    }
    
    convenience init() {
        self.init(name: "", date: "", address: "", info: "")
    }
    
    func makeNode(context: Context) throws -> Node {
        return try Node(node: [
            "id": id,
            "uid": uid,
            "name": name,
            "date": date,
            "address": address,
            "info": info
            ])
    }
    
    func merge(from trip: Trip) {
        name = trip.name
        date = trip.date
        address = trip.address
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
            trips.string("date")
            trips.string("address")
            trips.string("info")
        }
    }
    
    static func revert(_ database: Database) throws {
        try database.delete("trips")
    }
}
