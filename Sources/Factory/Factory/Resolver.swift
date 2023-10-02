//
// Resolver.swift
//  
// GitHub Repo and Documentation: https://github.com/hmlongco/Factory
//
// Copyright © 2022 Michael Long. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//
//  Created by Michael Long on 4/30/23.
//

import Foundation

/// When protocol is applied to a container it enables a typed registration/resolution mode.
public protocol Resolving: ManagedContainer {

    /// Registers a new type and associated factory closure with this container.
    func register<T>(_ type: T.Type, factory: @escaping () -> T) -> Factory<T>

    /// Registers a new type and associated factory closure with this container.
    func register<P,T>(_ type: T.Type, factory: @escaping (P) -> T) -> ParameterFactory<P,T>

   /// Returns a registered factory for this type from this container.
    func factory<T>(_ type: T.Type) -> Factory<T>?

    /// Returns a registered parameter factory for this type from this container.
    func factory<P,T>(_ type: T.Type, _ parameterType: P.Type) -> ParameterFactory<P,T>?

    /// Resolves a type from this container.
    func resolve<T>(_ type: T.Type) -> T?

    /// Resolves a parameterized type from this container.
    func resolve<P,T>(_ type: T.Type, parameters: P) -> T?

}

extension Resolving {

    /// Registers a new type and associated factory closure with this container.
    ///
    /// Also returns Factory for further specialization for scopes, decorators, etc.
    @discardableResult
    public func register<T>(_ type: T.Type = T.self, factory: @escaping () -> T) -> Factory<T> {
        defer { globalRecursiveLock.unlock() }
        globalRecursiveLock.lock()
        // Perform autoRegistration check
        unsafeCheckAutoRegistration()
        // Add register to persist in container, and return factory so user can specialize if desired
        return Factory(self, key: globalResolverKey, factory).register(factory: factory)
    }

    /// Registers a new parameterized type and associated factory closure with this container.
    ///
    /// Also returns ParameterFactory for further specialization for scopes, decorators, etc.
    @discardableResult
    public func register<P,T>(_ type: T.Type = T.self, factory: @escaping (P) -> T) -> ParameterFactory<P,T> {
        defer { globalRecursiveLock.unlock() }
        globalRecursiveLock.lock()
        // Perform autoRegistration check
        unsafeCheckAutoRegistration()
        // Add register to persist in container, and return factory so user can specialize if desired
        return ParameterFactory(self, key: globalResolverKey, factory).register(factory: factory)
    }

    /// Returns a registered factory for this type from this container. Use this function to set options and previews after the initial
    /// registration.
    ///
    /// Note that nothing will be applied if initial registration is not found.
    public func factory<T>(_ type: T.Type = T.self) -> Factory<T>? {
        defer { globalRecursiveLock.unlock() }
        globalRecursiveLock.lock()
        // Perform autoRegistration check
        unsafeCheckAutoRegistration()
        // if we have a registration for this type, then build registration and factory for it
        let key = FactoryKey(type: T.self, key: globalResolverKey)
        if let factory = manager.registrations[key] as? TypedFactory<Void,T> {
            return Factory(FactoryRegistration<Void,T>(key: globalResolverKey, container: self, factory: factory.factory))
        }
        // otherwise return nil
        return nil
    }

    public func factory<P,T>(_ type: T.Type, _ parameterType: P.Type) -> ParameterFactory<P,T>? {
        defer { globalRecursiveLock.unlock() }
        globalRecursiveLock.lock()
        // Perform autoRegistration check
        unsafeCheckAutoRegistration()
        // if we have a registration for this type, then build registration and factory for it
        let key = FactoryKey(type: T.self, key: globalResolverKey)
        if let factory = manager.registrations[key] as? TypedFactory<P,T> {
            return ParameterFactory(FactoryRegistration<P,T>(key: globalResolverKey, container: self, factory: factory.factory))
        }
        // otherwise return nil
        return nil
    }

    /// Resolves a type from this container.
    public func resolve<T>(_ type: T.Type = T.self) -> T? {
        return factory(type)?.registration.resolve(with: ())
    }

    /// Resolves a type from this container.
    public func resolve<P,T>(_ type: T.Type = T.self, parameters: P) -> T? {
        return factory(type, P.self)?.registration.resolve(with: parameters)
    }

    /// Shortcut resolves a type from this container.
    public func callAsFunction<T>(_ type: T.Type = T.self) -> T? {
        return factory(type)?.registration.resolve(with: ())
    }

    /// Shortcut resolves a type from this container.
    public func callAsFunction<P,T>(_ type: T.Type = T.self, parameters: P) -> T? {
        return factory(type, P.self)?.registration.resolve(with: parameters)
    }

}

extension Factory {
    fileprivate init(_ registration: FactoryRegistration<Void,T>) {
        self.registration = registration
    }
}

extension ParameterFactory {
    fileprivate init(_ registration: FactoryRegistration<P,T>) {
        self.registration = registration
    }
}

/// Basic property wrapper for optional injected types
@propertyWrapper public struct InjectedType<T> {
    private var dependency: T?
    /// Initializes the property wrapper from the default Container. The dependency is resolved on initialization.
    public init() {
        self.dependency = (Container.shared as? Resolving)?.resolve()
    }
    /// Initializes the property wrapper from the default Container. The dependency is resolved on initialization.
    public init(_ container: ManagedContainer) {
        self.dependency = (container as? Resolving)?.resolve()
    }
    /// Manages the wrapped dependency.
    public var wrappedValue: T? {
        get { return dependency }
        mutating set { dependency = newValue }
    }
}

/// Basic property wrapper for optional lazy injected types
@propertyWrapper public struct LazyInjectedType<T> {
    private var container: Resolving?
    private var dependency: T?
    /// Initializes the property wrapper from the default Container. The dependency is resolved on first access.
    public init() {
        self.container = Container.shared as? Resolving
    }
    /// Initializes the property wrapper from a container. The dependency is resolved on first access.
    public init(_ container: ManagedContainer) {
        self.container = container as? Resolving
    }
    /// Manages the wrapped dependency.
    public var wrappedValue: T? {
        mutating get {
            defer { globalRecursiveLock.unlock()  }
            globalRecursiveLock.lock()
            if let container = container {
                dependency = container.resolve(T.self)
                self.container = nil
            }
            return dependency
        }
        mutating set {
            dependency = newValue
        }
    }
    /// Unwraps the property wrapper granting access to the resolve/reset function.
    public var projectedValue: LazyInjectedType<T> {
        get { return self }
        mutating set { self = newValue }
    }
    /// Projected function returns resolved instance if it exists.
    ///
    /// This can come in handy when you need to perform some sort of cleanup, but you don't want to resolve
    /// the property wrapper instance if it hasn't already been resolved.
    /// ```swift
    /// deinit {
    ///     $myService.resolvedOrNil()?.cleanup()
    /// }
    public func resolvedOrNil() -> T? {
        dependency
    }
}

/// Basic property wrapper for optional weak lazy injected types
@propertyWrapper public struct WeakLazyInjectedType<T:AnyObject> {
    private var container: Resolving?
    private weak var dependency: AnyObject?
    /// Initializes the property wrapper from the default Container. The dependency is resolved on first access.
    public init() {
        self.container = Container.shared as? Resolving
    }
    /// Initializes the property wrapper from a container. The dependency is resolved on first access.
    public init(_ container: ManagedContainer) {
        self.container = container as? Resolving
    }
    /// Manages the wrapped dependency.
    public var wrappedValue: T? {
        mutating get {
            defer { globalRecursiveLock.unlock() }
            globalRecursiveLock.lock()
            if let container = container {
                dependency = container.resolve(T.self)
                self.container = nil
            }
            return dependency as? T
        }
        mutating set {
            dependency = newValue
        }
    }
    /// Unwraps the property wrapper granting access to the resolve/reset function.
    public var projectedValue: WeakLazyInjectedType<T> {
        get { return self }
        mutating set { self = newValue }
    }
    /// Projected function returns resolved instance if it exists.
    ///
    /// This can come in handy when you need to perform some sort of cleanup, but you don't want to resolve
    /// the property wrapper instance if it hasn't already been resolved.
    /// ```swift
    /// deinit {
    ///     $myService.resolvedOrNil()?.cleanup()
    /// }
    public func resolvedOrNil() -> T? {
        dependency as? T
    }

}
