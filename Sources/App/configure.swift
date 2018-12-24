import FluentPostgreSQL
import Vapor
import Leaf
import Authentication



/// Called before your application initializes.
public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {
    /// Register providers first
    try services.register(FluentPostgreSQLProvider())
    try services.register(LeafProvider())
    try services.register(AuthenticationProvider())

    /// Register routes to the router
    let router = EngineRouter.default()
    try routes(router)
    services.register(router, as: Router.self)

    /// Register middleware
    var middlewares = MiddlewareConfig() // Create _empty_ middleware config
    middlewares.use(FileMiddleware.self) // Serves files from `Public/` directory
    middlewares.use(ErrorMiddleware.self) // Catches errors and converts to HTTP response
    middlewares.use(SessionsMiddleware.self)

    // Configure a PostgreSQL database
    let postgresqlConfig = PostgreSQLDatabaseConfig(
        hostname: "localhost",
        username: "nikolay.andonov",
        database: "healthbeam",
        password: nil
    )
    let postgresqlDatabase = PostgreSQLDatabase(config: postgresqlConfig)
    
    var databases = DatabasesConfig()
    databases.add(database: postgresqlDatabase, as: .psql)
    services.register(databases)


    /// Configure migrations
    var migrations = MigrationConfig()
    migrations.add(model: User.self, database: .psql)
    migrations.add(model: Patient.self, database: .psql)
    migrations.add(model: HealthRecord.self, database: .psql)
    migrations.add(model: TokenRecord.self, database: .psql)
    migrations.add(model: UserPatient.self, database: .psql)
    migrations.add(model: PatientTag.self, database: .psql)
    migrations.add(model: PatientAlert.self, database: .psql)
    migrations.add(model: Device.self, database: .psql)
    services.register(migrations)
    
    config.prefer(LeafRenderer.self, for: ViewRenderer.self)
    config.prefer(MemoryKeyedCache.self, for: KeyedCache.self)
}