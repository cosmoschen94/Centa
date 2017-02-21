import Vapor
import VaporPostgreSQL
import Fluent
import HTTP
import Auth
import Cookies
import Foundation

let cors = CorsMiddleware()
let auth = AuthMiddleware(user: User.self) { value in
    return Cookie(
        name: "centa-auth",
        value: value,
        expires: Date().addingTimeInterval(60 * 60 * 5), // 5 hours
        secure: true,
        httpOnly: true
    )
}

var drop = Droplet()
try drop.addProvider(VaporPostgreSQL.Provider.self)

drop.middleware += cors
drop.middleware += auth

drop.preparations += Trip.self
drop.preparations += User.self
drop.preparations += TripUser.self

// MARK: User

drop.resource("trips", TripController())

let userController = UserController()

drop.post("register", handler: userController.register)
drop.post("login", handler: userController.login)
drop.post("logout", handler: userController.logout)

/*
 * Secured Endpoints
 * Anything in here requires the Authorication header:
 * Example: "Authorization: Bearer TOKEN"
 */
let protect = ProtectMiddleware(error: Abort.custom(status: .unauthorized, message: "Unauthorized"))
drop.group(BearerAuthMiddleware(), protect) { secured in

    let users = secured.grouped("users")
    /*
     * Validation: I use this to check on the token periodically to see
     * if I need a new token while the user is using the app.
     */
    users.post("validate", handler: userController.validateAccessToken)

    /*
     * Me
     * Get the current users info
     */
    users.get("me", handler: userController.me)
}

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
        "trip": TripModel(trip).makeNode(),
        "isNew": isNew
        ])
}

drop.get("id", String.self) { req, uid in
    guard let trip = try Trip.find(uid: uid) else {
        throw Abort.notFound
    }
    redirectToTrip = trip
    return Response(redirect: "/")
}

// MARK: API

// Upsert trip
drop.post("trip/join") { req in
    print("post path:\(req.uri.path)")

    // Validate json input
    guard let tripUserIdJson = req.json else {
        assertionFailure("trip no json:\(req.body)")
        throw Abort.badRequest
    }
    guard let tripUid = tripUserIdJson["tripId"]?.string,
        let userUid = tripUserIdJson["userId"]?.string else
    {
        throw Abort.badRequest
    }
    print("tripId:\(tripUid)")
    print("userId:\(userUid)")

    // Check existing trip to update
    guard let trip = try Trip.find(uid: tripUid) else {
        throw Abort.notFound
    }

    try trip.upsertUser(userUid, relation: .joined)

    return try TripModel(trip).makeNode().converted(to: JSON.self)
}

drop.post("trip/leave") { req in
    print("post path:\(req.uri.path)")

    // Validate json input
    guard let tripUserIdJson = req.json else {
        assertionFailure("trip no json:\(req.body)")
        throw Abort.badRequest
    }
    guard let tripUid = tripUserIdJson["tripId"]?.string,
        let userUid = tripUserIdJson["userId"]?.string else
    {
        throw Abort.badRequest
    }
    print("tripId:\(tripUid)")
    print("userId:\(userUid)")

    // Check existing trip to update
    guard let trip = try Trip.find(uid: tripUid) else {
        throw Abort.notFound
    }

    try trip.upsertUser(userUid, relation: .none)

    return try TripModel(trip).makeNode().converted(to: JSON.self)
}

// Upsert trip
drop.post("trip") { req in
    print("post path:\(req.uri.path)")

    // Validate json input
    guard let tripJson = req.json else {
        assertionFailure("trip no json:\(req.body)")
        throw Abort.badRequest
    }
    var trip = try Trip(node: tripJson)
    print("trip:\(trip)")

    // Check existing trip to update
    if let existingTrip = try Trip.find(uid: trip.uid) {
        print("existing - update")
        existingTrip.merge(from: trip)
        trip = existingTrip
    }

    try trip.save()

    return try TripModel(trip).makeNode().converted(to: JSON.self)
}

// Fetch trip
drop.get("trip", String.self) { req, uid in
    print("path:\(req.uri.path)")
    
    guard let trip = try Trip.find(uid: uid) else {
        throw Abort.notFound
    }
    
    print("trip:\(trip)")
    
    return try TripModel(trip).makeNode().converted(to: JSON.self)
}



// Fetch trips
// TODO: owning + joined + watching + public
drop.get("trips") { req in
    print("path:\(req.uri.path)")

    let trips = try Trip.query().all()

    print("trips count:\(trips.count)")

    var tripNodes = [Node]()
    for trip in trips {
        tripNodes.append(try TripModel(trip).makeNode())
    }
    return try tripNodes.makeNode().converted(to: JSON.self)
    //    return try trips.makeNode().converted(to: JSON.self)
}

drop.run()
