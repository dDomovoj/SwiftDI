//
//  DI.swift
//  SwiftDI
//
//  Created by Roberto Frontado on 30/01/2020.
//  Modifed by dDomovoj on 02/09/22
//  Copyright © 2020 Roberto Frontado. All rights reserved.
//

import Foundation

final public class DI {
  
  internal static let `default` = DI()
  
  private var dependencies = [String: Resolver]()
  
  public static func configure(_ block: (DI) -> Void) {
    block(.default)
  }
  
  public func shared<T>(_ block: () -> T) {
    let key = String(describing: T.self)
    dependencies[key] = Resolver.shared(object: block())
  }
  
  public func factory<T>(_ factory: @escaping () -> T) {
    let key = String(describing: T.self)
    dependencies[key] = Resolver.factory(block: factory)
  }
  
  public func resolve<T>() -> T {
    let key = String(describing: T.self)
    print()
    guard let object = dependencies[key]?.resolve() as? T else {
      fatalError("Dependency '\(T.self)' not resolved!")
    }
    
    return object
  }
}
