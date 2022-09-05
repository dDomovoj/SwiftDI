//
//  DI.swift
//  SwiftDI
//
//  Created by Roberto Frontado on 30/01/2020.
//  Modifed by dDomovoj on 02/09/22
//  Copyright © 2020 Roberto Frontado. All rights reserved.
//

import Foundation

protocol WrappingProtocol {
  
  static var wrappedType: Any.Type { get }
  
}

extension Optional: WrappingProtocol {
  
  static var wrappedType: Any.Type { Wrapped.self }
  
}

final public class DI {
  
  internal static let `default` = DI()
  
  private var dependencies = [String: Resolver]()
  
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
    dependencies[key] = Resolver.shared(object: block())
  }
  
  public func factory<T>(_ factory: @escaping () -> T) {
    let key = self.key(for: T.self)
    dependencies[key] = Resolver.factory(block: factory)
  }
  
  public func resolve<T>() -> T {
    let key = self.key(for: T.self)
    
    if let obj = dependencies[key]?.resolve() as? T {
      return obj
    }
    // is optional type
    else if T.self is ExpressibleByNilLiteral.Type {
      let _result: T? = nil
      let result = _result!
      return result
    }
    
    fatalError("Non optional dependency '\(T.self)' not resolved!")
  }
  
}
