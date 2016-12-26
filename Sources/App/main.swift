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

// MARK: Http

var redirectToTrip: Trip?

drop.get { req in
    var isNew = false
    let trip: Trip
    if let targetTrip = redirectToTrip {
        trip = targetTrip
        redirectToTrip = nil
    } else {
        trip = Trip()
        isNew = true
    }
    return try drop.view.make("trip", [
        "message": "Welcome!",
        "trip": trip.makeNode(),
        "isNew": isNew
        ])
}

drop.get("id", String.self) { req, uid in
    guard let trip = try Trip.query().filter("uid", uid).first() else {
        throw Abort.notFound
    }
    redirectToTrip = trip
    return Response(redirect: "/")
}

// MARK: API

drop.get("api", "trips") { req in
    print("path:\(req.uri.path)")
   
    let trips = try Trip.query().all()
    
    print("trips count:\(trips.count)")
    
    return try trips.makeNode().converted(to: JSON.self)
}

drop.get("api", "trip", String.self) { req, uid in
    print("path:\(req.uri.path)")
    
    guard let trip = try Trip.query().filter("uid", uid).first() else {
        throw Abort.notFound
    }
    
    print("trip:\(trip)")
    
    return try trip.makeNode().converted(to: JSON.self)
}

// Upsert trip
drop.post("api", "trip") { req in
    print("post path:\(req.uri.path)")
    
    // Validate json input
    guard let tripJson = req.json else {
        assertionFailure("trip no json:\(req.body)")
        throw Abort.badRequest
    }
    var trip = try Trip(node: tripJson)
    print("trip:\(trip)")
    
    // Check existing trip to update
    if let existingTrip = try Trip.query().filter("uid", trip.uid).first() {
        print("existing - update")
        existingTrip.merge(from: trip)
        trip = existingTrip
    }
    
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
