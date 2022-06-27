import XCTest
@testable import Factory


final class FactoryRegistrationTests: XCTestCase {

    override func setUp() {
        super.setUp()
        Container.Registrations.reset()
        Container.Scope.reset()
    }

    func testRegistrationAndResolution() throws {
        Container.Registrations.register { MyService() }
        let service: MyService? = Container.Registrations.resolve(MyService.self)
        XCTAssertTrue(service?.text() == "MyService")
    }

    func testRegistrationAndInferredResolution() throws {
        Container.Registrations.register { MyService() }
        let service: MyService = Container.Registrations.resolve()!
        XCTAssertTrue(service.text() == "MyService")
    }

    func testProtocolRegistrationAndResolution() throws {
        Container.Registrations.register { MyService() as MyServiceType }
        let service: MyServiceType? = Container.Registrations.resolve(MyServiceType.self)
        XCTAssertTrue(service?.text() == "MyService")
    }

    func testRegistrationAndOptionalResolution() throws {
        Container.Registrations.register { MyService() }
        let service: MyService? = Container.Registrations.resolve(MyService.self)
        XCTAssertTrue(service?.text() == "MyService")
    }

    func testRegistrationAndOptionalInferredResolution() throws {
        Container.Registrations.register { MyService() }
        let service: MyService? = Container.Registrations.resolve(MyService.self)
        XCTAssertTrue(service?.text() == "MyService")
    }

    func testProtocolRegistrationAndOptionalResolution() throws {
        Container.Registrations.register { MyService() as MyServiceType }
        let service: MyServiceType? = Container.Registrations.resolve(MyServiceType.self)
        XCTAssertTrue(service?.text() == "MyService")
    }

    func testProtocolRegistrationAndInferredOptionalResolution() throws {
        Container.Registrations.register { MyService() as MyServiceType }
        let service: MyServiceType? = Container.Registrations.resolve()
        XCTAssertTrue(service?.text() == "MyService")
    }

    func testPromisedRegistrationAndOptionalResolution() throws {
        let service1: MyServiceType? = Container.promisedService()
        XCTAssertTrue(service1?.text() == nil)
        Container.promisedService.register { MyService() }
        let service2: MyServiceType? = Container.promisedService()
        XCTAssertTrue(service2?.text() == "MyService")
    }

    func testPushPop() throws {
        let service1 = Container.myServiceType()
        XCTAssertTrue(service1.text() == "MyService")

        // add registrtion and test initial state
        Container.myServiceType.register(factory: { MockServiceN(1) })
        let service2 = Container.myServiceType()
        XCTAssertTrue(service2.text() == "MockService1")

        // push and test changed state
        Container.Registrations.push()
        Container.myServiceType.register(factory: { MockServiceN(2) })
        let service3 = Container.myServiceType()
        XCTAssertTrue(service3.text() == "MockService2")

        // pop and ensure we're back to initial state
        Container.Registrations.pop()
        let service4 = Container.myServiceType()
        XCTAssertTrue(service4.text() == "MockService1")

        // pop again (which does nothing) and test for initial state
        Container.Registrations.pop()
        let service5 = Container.myServiceType()
        XCTAssertTrue(service5.text() == "MockService1")
    }

    func testReset() throws {
        let service1 = Container.myServiceType()
        XCTAssertTrue(service1.text() == "MyService")

        Container.myServiceType.register(factory: { MockService() })
        let service2 = Container.myServiceType()
        XCTAssertTrue(service2.text() == "MockService")

        Container.Registrations.reset()

        let service3 = Container.myServiceType()
        XCTAssertTrue(service3.text() == "MyService")
    }

}
