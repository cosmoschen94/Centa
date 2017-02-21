import Vapor
import Fluent
import Foundation

// MARK: Client Schema - don't remove fields after production

struct TripModel {
    var uid: String // TODO: Make it unique
    var title: String
    var date: String
    var address: String
    var info: String
    var owningUsers: [UserModel]
    var joinedUsers: [UserModel]

    init(_ trip: Trip) throws {
        uid = trip.uid
        title = trip.title
        date = trip.date
        address = trip.address
        info = trip.info
        owningUsers = try trip.owningUsers().map{
            try UserModel($0)
        }
        joinedUsers = try trip.joinedUsers().map{
            try UserModel($0)
        }
    }

    func makeNode() throws -> Node {
        var owningUserNodes = [Node]()
        for user in owningUsers {
            owningUserNodes.append(try user.makeNode())
        }

        var joinedUserNodes = [Node]()
        for user in joinedUsers {
            joinedUserNodes.append(try user.makeNode())
        }

        return try Node(node: [
            Prop.uid: uid,
            Prop.title: title,
            Prop.date: date,
            Prop.address: address,
            Prop.info: info,
            Prop.owningUsers: owningUserNodes.makeNode(),
            Prop.joinedUsers: joinedUserNodes.makeNode()
            ])
    }
}

// MARK: Fluent Model

final class Trip: Model {

    var id: Node?
    var uid: String // TODO: Make it unique
    var title: String
    // yyyy-MM-dd'T'HH:mm'Z': 2016-12-24T17:09Z - conforms to ISO 8601
    var date: String
    var address: String
    var info: String

    // Non-persistent
    var exists: Bool = false
    
    init(title: String, date: String, address: String, info: String) {
        self.uid = genUid()
        self.title = title
        self.date = date
        self.address = address
        self.info = info
    }
    
    init(node: Node, in context: Context) throws {
        id = try node.extract(Prop.id)
        let incomingUid = try node.extract(Prop.uid) ?? ""
        uid = incomingUid.isEmpty ? genUid() : incomingUid
        title = try node.extract(Prop.title)
        date = try node.extract(Prop.date)
        address = try node.extract(Prop.address)
        info = try node.extract(Prop.info)
    }
    
    convenience init() {
        self.init(title: "", date: "", address: "", info: "")
    }
    
    func makeNode(context: Context) throws -> Node {
        return try Node(node: [
            Prop.id: id,
            Prop.uid: uid,
            Prop.title: title,
            Prop.date: date,
            Prop.address: address,
            Prop.info: info
            ])
    }

    func merge(from trip: Trip) {
        title = trip.title
        date = trip.date
        address = trip.address
        info = trip.info
    }

    static func find(uid: String) throws -> Trip? {
        return try Trip.query().filter(Prop.uid, uid).first()
    }
}

extension Trip: Preparation {
    static func prepare(_ database: Database) throws {
        try database.create(Prop.trips) { trips in
            trips.id()
            trips.string(Prop.uid)
            trips.string(Prop.title)
            trips.string(Prop.date)
            trips.string(Prop.address)
            trips.string(Prop.info)
        }
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(Prop.trips)
    }
}
