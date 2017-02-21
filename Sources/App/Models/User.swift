import Vapor
import Fluent
import Foundation
import Auth
import Turnstile
import BCrypt
import HTTP
import JWT

// MARK: Client Schema - don't remove fields after production

struct UserModel {
    var uid: String
    var name: String

    init(_ user: User) throws {
        uid = user.uid
        name = user.name
    }

    func makeNode() throws -> Node {
        return try Node(node: [
            Prop.uid: uid,
            Prop.name: name,
            ])
    }
}

struct AuthUserModel {
    var uid: String
    var name: String
    var email: String
    var password: String
    var token: String

    init(_ user: User) throws {
        uid = user.uid
        name = user.name
        email = user.email
        password = user.password
        token = user.token
    }

    func makeNode() throws -> Node {
        return try Node(node: [
            Prop.uid: uid,
            Prop.name: name,
            Prop.email: email,
            Prop.password: password,
            Prop.token: token,
            ])
    }
}

// MARK: Fluent Model

final class User: Model {
    var id: Node?
    var uid: String // TODO: Make it unique
    var name: String
    var email: String // unique
    // var email: Email
    var password: String
    var salt: String

    // Short-lived
    var token: String

    // Non-persistent
    var exists: Bool = false

    init(name: String,
         email: String, // Valid<Email>
         rawPassword: String,
         salt: String,
         token: String = "")
    {
        self.uid = genUid()
        self.name = name.isEmpty ? email : name
        self.email = email
        self.password = BCrypt.hash(password: rawPassword)
        self.salt = salt
        self.token = token
    }
    
    init(node: Node, in context: Context) throws {
        id = try node.extract(Prop.id)
        let incomingUid = try node.extract(Prop.uid) ?? ""
        uid = incomingUid.isEmpty ? genUid() : incomingUid
        name = try node.extract(Prop.name)
        email = try node.extract(Prop.email)
        password = try node.extract(Prop.password)
        salt = try node.extract(Prop.salt)
        token = try node.extract(Prop.token)
    }

    func makeNode(context: Context) throws -> Node {
        return try Node(node: [
            Prop.id: id,
            Prop.uid: uid,
            Prop.name: name,
            Prop.email: email,
            Prop.password: password,
            Prop.salt: salt,
            Prop.token: token
            ])
    }

    static func find(uid: String) throws -> User? {
        return try User.query().filter(Prop.uid, uid).first()
    }

    static func find(email: String) throws -> User? {
        return try User.query().filter(Prop.email, email).first()
    }

    static func find(email: Email) throws -> User? {
        return try User.query().filter(Prop.email, email.value).first()
    }
}

extension Request {
    func user() throws -> User {
        guard let user = try auth.user() as? User else {
            throw Abort.custom(status: .badRequest, message: "Invalid user type.")
        }
        return user
    }
}

// MARK: Auth

extension User: Auth.User {
    static func authenticate(credentials: Credentials) throws -> Auth.User {
        var fetchedUser: User?

        switch credentials {
        case let id as Identifier:
            guard let user = try User.find(id.id) else {
                throw Abort.custom(status: .forbidden,
                                   message: "Invalid user identifier.")
            }
            fetchedUser = user
            
        case let accessToken as AccessToken:
            guard let user = try User.query()
                .filter(Prop.token, accessToken.string)
                .first() else
            {
                throw Abort.custom(status: .forbidden,
                                   message: "Invalid access token.")
            }
            fetchedUser = user
            
        case let usernamePassword as UsernamePassword:
            guard let user = try User.query()
                .filter(Prop.email, usernamePassword.username)
                .first() else
            {
               throw Abort.custom(status: .badRequest, message: "User not found.")
            }

            guard try BCrypt.verify(password: usernamePassword.password,
                                    matchesHash: user.password) else
            {
                throw Abort.custom(status: .networkAuthenticationRequired, message: "Incorrect password.")
            }

            print("auth set fetchedUser")
            fetchedUser = user
            
        default:
            throw UnsupportedCredentialsError()
        }

        guard var user = fetchedUser else {
            throw IncorrectCredentialsError()
        }

        // Check if we have an accessToken first, if not, create a new one
        if !user.token.isEmpty {
            // Check if our authentication token has expired, if so, lets generate a new one as this is a fresh login
            let receivedJWT = try JWT(token: user.token)

            // Validate it's time stamp
            if !receivedJWT.verifyClaims([ExpirationTimeClaim()]) {
                try user.generateToken()
            }
        } else {
            // We don't have a valid access token
            try user.generateToken()
        }

        try user.save()

        return user
    }

    static func register(credentials: Credentials) throws -> Auth.User {
        switch credentials {
        case let usernamePassword as UsernamePassword:
            let email = usernamePassword.username
            let password = usernamePassword.password
            guard !email.isEmpty && !password.isEmpty else {
                throw UnsupportedCredentialsError()
            }
            if let _ = try User.query().filter(Prop.email, email).first() {
                throw AccountTakenError()
            }
            var newUser = User(
                name: "",
                email: email,
                rawPassword: password,
                salt: "")
            try newUser.generateToken()
            do {
                try newUser.save()
            } catch let e {
                throw Abort.custom(status: Status.badRequest, message: e.localizedDescription)
            }

            return newUser

        default:
            throw UnsupportedCredentialsError()
        }
    }
}

// MARK: Token Generation

extension User {
    static let accessTokenSigningKey: Bytes = Array("CHANGE_ME".utf8)
    static let accessTokenDuration = Date() + 60 * 5 // 5 Minutes

    func generateToken() throws {
        let jwt = try JWT(
            payload: Node(ExpirationTimeClaim(User.accessTokenDuration)),
            signer: HS256(key: User.accessTokenSigningKey))

        self.token = try jwt.createToken()
    }

    func validateToken() throws -> Bool {
        guard !token.isEmpty else { return false }
        // Validate our current access token
        let receivedJWT = try JWT(token: token)
        if try receivedJWT.verifySignatureWith(
            HS256(key: User.accessTokenSigningKey))
        {
            if receivedJWT.verifyClaims([ExpirationTimeClaim()]) {
                return true
            } else {
                //try self.generateToken()
            }
        }
        return false
    }
}

// MARK: Helpers

struct Email: ValidationSuite, Validatable {
    let value: String

    public static func validate(input value: Email) throws {
        try Vapor.Email.validate(input: value.value)
    }
}

struct Username: ValidationSuite, Validatable {
    let value: String

    public static func validate(input value: Username) throws {
        let evaluation = OnlyAlphanumeric.self
            && Count.min(2)
            && Count.max(30)

        try evaluation.validate(input: value.value)
    }
}

extension User: Preparation {
    static func prepare(_ database: Database) throws {
        try database.create(Prop.users) { users in
            users.id()
            users.string(Prop.uid)
            users.string(Prop.name)
            users.string(Prop.email, unique: true)
            users.string(Prop.password)
            users.string(Prop.salt)
            users.string(Prop.token)
        }
    }
    
    public static func revert(_ database: Database) throws {
        try database.delete(Prop.users)
    }
}

