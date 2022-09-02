//
//  Injected.swift
//  SwiftDI
//
//  Created by Roberto Frontado on 30/01/2020.
//  Modifed by dDomovoj on 02/09/22
//  Copyright © 2020 Roberto Frontado. All rights reserved.
//

import Foundation

@propertyWrapper
public struct Injected<Value> {
  
  private var value: Value?
  
  public var wrappedValue: Value {
    get {
      return value ?? DI.default.resolve()
    }
    set {
      value = newValue
    }
  }
  
  public init() {}
}
