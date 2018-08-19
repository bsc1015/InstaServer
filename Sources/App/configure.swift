import Authentication
import FluentSQLite
import Routing
import Vapor

/// Called before your application initializes.
public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {
    
    config.prefer(MemoryKeyedCache.self, for: KeyedCache.self)
    
    /// Register providers first
    try services.register(FluentSQLiteProvider())

    /// Register routes to the router
    let router = EngineRouter.default()
    try routes(router)
    services.register(router, as: Router.self)

    /// Register middleware
    var middlewares = MiddlewareConfig() // Create _empty_ middleware config
    /// middlewares.use(FileMiddleware.self) // Serves files from `Public/` directory
    middlewares.use(ErrorMiddleware.self) // Catches errors and converts to HTTP response
    middlewares.use(SessionsMiddleware.self)
    services.register(middlewares)

    // Configure a SQLite database
    let sqlite = try SQLiteDatabase(storage: .file(path: NSTemporaryDirectory() + "sql.sqlite"))
    
    /// Register the configured SQLite database to the database config.
    var databases = DatabasesConfig()
    databases.add(database: sqlite, as: .sqlite)
    services.register(databases)

    /// Configure migrations
    var migrations = MigrationConfig()
    migrations.add(model: Todo.self, database: .sqlite)
    migrations.add(model: UserCredentials.self, database: .sqlite)
    migrations.add(model: Post.self, database: .sqlite)
    services.register(migrations)

    let authProvider = AuthenticationProvider()
    try services.register(authProvider)
    
    
    
    
    
    // create auth sessions middleware for user
    let session = UserCredentials.basicAuthMiddleware(using: PlaintextVerifier())
    UserCredentials.defaultDatabase = DatabaseIdentifier<SQLiteDatabase>.sqlite
    Post.defaultDatabase = DatabaseIdentifier<SQLiteDatabase>.sqlite
    
    // create a route group wrapped by this middleware
    let auth = router.grouped(session)
    try authRoutes(auth)
    
    // create new route in this route group
    auth.get("hello" as String)
    { (request: Request) throws -> String in
        let user = try request.requireAuthenticated(UserCredentials.self)
        return "Hello, \(user.username)."
    }
    
    // create new route in this route group
    auth.get("users" as String)
    { (request: Request) throws -> Future<Response> in
        try UserCredentials.query(on: request).all().encode(for: request)
    }
}
