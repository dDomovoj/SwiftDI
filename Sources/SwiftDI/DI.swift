//
//  DI.swift
//  SwiftDI
//
//  Created by Roberto Frontado on 30/01/2020.
//  Modifed by dDomovoj on 02/09/22
//  Copyright © 2020 Roberto Frontado. All rights reserved.
//

import Foundation
import os

internal protocol WrappingProtocol {
  
  static var wrappedType: Any.Type { get }
  
}

extension Optional: WrappingProtocol {
  
  static var wrappedType: Any.Type { Wrapped.self }
  
}

final public class DI {
  
  internal static let `default` = DI()
  
  private let lock: os_unfair_lock_t
  
  private var dependencies = [String: Resolver]()
  
  private init() {
    lock = .allocate(capacity: 1)
    lock.initialize(to: os_unfair_lock())
  }
  
  private func key(for type: Any.Type) -> String {
    if let wrappingType = type as? WrappingProtocol.Type {
      return key(for: wrappingType.wrappedType)
    }
    return String(reflecting: type.self)
  }
  
  public static func configure(_ block: (DI) -> Void) {
    block(.default)
  }
  
  public func shared<T>(_ block: () -> T) {
    let key = self.key(for: T.self)
    let obj = block()
    
    os_unfair_lock_lock(lock)
    dependencies[key] = Resolver.shared(object: obj)
    os_unfair_lock_unlock(lock)
  }
  
  public func factory<T>(_ factory: @escaping () -> T) {
    let key = self.key(for: T.self)
    
    os_unfair_lock_lock(lock)
    dependencies[key] = Resolver.factory(block: factory)
    os_unfair_lock_unlock(lock)
  }
  
  internal func resolve<T>() -> T {
    let key = self.key(for: T.self)
    
    os_unfair_lock_lock(lock)
    let dep = dependencies[key]
    os_unfair_lock_unlock(lock)
    
    if let obj = dep?.resolve() as? T {
      return obj
    }
    
    fatalError("Non optional dependency '\(T.self)' not resolved!")
  }
  
}
