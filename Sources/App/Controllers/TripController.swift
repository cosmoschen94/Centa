import Vapor
import HTTP

final class TripController: ResourceRepresentable {
    func index(request: Request) throws -> ResponseRepresentable {
        return try Trip.all().makeNode().converted(to: JSON.self)
    }
    
    func create(request: Request) throws -> ResponseRepresentable {
        var trip = try request.trip()
        try trip.save()
        return trip
    }
    
    func show(request: Request, trip: Trip) throws -> ResponseRepresentable {
        return trip
    }
    
    func delete(request: Request, trip: Trip) throws -> ResponseRepresentable {
        try trip.delete()
        return JSON([:])
    }
    
    func clear(request: Request) throws -> ResponseRepresentable {
        try Trip.query().delete()
        return JSON([])
    }
    
    func update(request: Request, trip: Trip) throws -> ResponseRepresentable {
        let new = try request.trip()
        var trip = trip
        trip.uid = new.uid
        trip.title = new.title
        trip.info = new.info
        try trip.save()
        return trip
    }
    
    func replace(request: Request, trip: Trip) throws -> ResponseRepresentable {
        try trip.delete()
        return try create(request: request)
    }
    
    func makeResource() -> Resource<Trip> {
        return Resource(
            index: index,
            store: create,
            show: show,
            replace: replace,
            modify: update,
            destroy: delete,
            clear: clear
        )
    }
}

extension Request {
    func trip() throws -> Trip {
        guard let json = json else { throw Abort.badRequest }
        return try Trip(node: json)
    }
}
