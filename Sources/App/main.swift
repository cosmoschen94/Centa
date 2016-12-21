import Vapor
import VaporPostgreSQL
import Sessions
import Fluent
import HTTP

let memory = MemorySessions()
let sessions = SessionsMiddleware(sessions: memory)
let cors = CorsMiddleware()

var drop = Droplet()
drop.middleware.append(sessions)
drop.middleware.append(cors)
try drop.addProvider(VaporPostgreSQL.Provider.self)
drop.preparations.append(Trip.self)
drop.preparations.append(User.self)
drop.preparations.append(Pivot<Trip, User>.self)

// MARK: Welcome

drop.get { req in
    var newTrip = Trip(name: "", info: "")
    try newTrip.save()
    return try drop.view.make("trip", [
        "message": "Welcome!",
        "trip": newTrip.makeNode()
        ])
}

// MARK: Trip Html

drop.get("id", String.self) { req, uid in
    guard let trip = try Trip.query().filter("uid", uid).first() else {
        throw Abort.notFound
    }
    let trips = try Trip.query().all()
    return try drop.view.make("trip", [
        "message": "Welcome!",
        "trip": trip.makeNode()
        ])
    
    //     return Response(redirect: "/id/\(newTrip.uid)")
}

// MARK: Trip API

drop.get("api", "trips") { req in
    print("path:\(req.uri.path)")
   
    let trips = try Trip.query().all()
    
    return try trips.makeNode().converted(to: JSON.self)
}

drop.get("api", "trip", String.self) { req, uid in
    guard let trip = try Trip.query().filter("uid", uid).first() else {
        throw Abort.notFound
    }
    
    return try trip.makeNode().converted(to: JSON.self)
}

// Upsert trip
drop.post("api", "trip") { req in
    print("post api trip req:\(req)")
    guard let tripJson = req.json else {
        assertionFailure("trip no json:\(req.body)")
        throw Abort.badRequest
    }
    var trip = try Trip(node: tripJson)
    print("trip:\(trip)")
    
    try trip.save()
    
    return try trip.makeNode().converted(to: JSON.self)
}

// MARK: Generated APIs

drop.resource("trips", TripController())
drop.resource("users", UserController())

// MARK: Session examples

drop.post("remember") { req in
    guard let name = req.data["name"]?.string else {
        throw Abort.badRequest
    }
    
    try req.session().data["name"] = Node.string(name)
    
    return "Remebered name."
}

drop.get("remember") { req in
    guard let name = try req.session().data["name"]?.string else {
        throw Abort.custom(status: .badRequest, message: "Please POST the name first.")
    }
    
    return name
}

drop.run()
