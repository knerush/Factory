import XCTest
@testable import Factory

final class FactoryResolverTests: XCTestCase {

    fileprivate var container: ResolvingContainer!

    override func setUp() {
        super.setUp()
        container = ResolvingContainer()
    }

    func testBasicResolve() throws {
        let service1: MyService? = container.resolve()
        let service2: MyService? = container()
        XCTAssertNotNil(service1)
        XCTAssertNotNil(service2)
        // Unique item ids should not match
        XCTAssertTrue(service1?.id != service2?.id)
    }

    func testBasicParameterResolve() throws {
        let service1: ParameterService? = container.resolve(parameters: 1)
        let service2: ParameterService? = container(parameters: 2)
        XCTAssertNotNil(service1)
        XCTAssertNotNil(service2)
        XCTAssertEqual(service1?.value, 1)
        XCTAssertEqual(service2?.value, 2)
        // Unique item ids should not match
        XCTAssertTrue(service1?.id != service2?.id)
    }

    func testResolvingScope() throws {
        let service0: MyServiceType? = container.resolve()
        XCTAssertNil(service0)
        container.register { MyService() as MyServiceType }
            .scope(.singleton)
        let service1: MyServiceType? = container.resolve()
        let service2: MyServiceType? = container()
        XCTAssertNotNil(service1)
        XCTAssertNotNil(service2)
        // Shared cached item ids should match
        XCTAssertTrue(service1?.id == service2?.id)
    }

    func testFactoryScope() throws {
        container.factory(MyService.self)?
            .scope(.singleton)
        let service1: MyService? = container.resolve()
        let service2: MyService? = container()
        XCTAssertNotNil(service1)
        XCTAssertNotNil(service2)
        // Item ids should match
        XCTAssertTrue(service1?.id == service2?.id)
    }

    func testParameterFactoryScope() throws {
        container.factory(ParameterService.self, Int.self)?
            .scope(.singleton)
        let service1: ParameterService? = container.resolve(parameters: 1)
        let service2: ParameterService? = container(parameters: 2)
        XCTAssertNotNil(service1)
        XCTAssertNotNil(service2)
        XCTAssertEqual(service1?.value, 1)
        XCTAssertEqual(service2?.value, 1) // cached, parameter ignored
        // Item ids should match
        XCTAssertTrue(service1?.id == service2?.id)
    }

    func testMissingResolve() throws {
        let service1: Int? = container.resolve(Int.self)
        let service2: Int? = container(Int.self)
        XCTAssertNil(service1)
        XCTAssertNil(service2)
    }

    func testMissingParameterResolve() throws {
        let service1: Int? = container.resolve(Int.self, parameters: 1)
        let service2: Int? = container(Int.self, parameters: 1)
        XCTAssertNil(service1)
        XCTAssertNil(service2)
    }

}

fileprivate final class ResolvingContainer: SharedContainer, AutoRegistering, Resolving {    
    static let shared = ResolvingContainer()
    func autoRegister() {
        register { MyService() }
        register { ParameterService(value: $0) }
    }
    let manager = ContainerManager()
}
