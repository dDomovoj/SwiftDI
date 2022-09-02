//
//  Resolver.swift
//  SwiftDI
//
//  Created by Roberto Frontado on 23/02/2020.
//  Modifed by dDomovoj on 02/09/22
//  Copyright © 2020 Roberto Frontado. All rights reserved.
//

internal enum Resolver {
  case shared(object: Any)
  case factory(block: () -> Any)
  
  func resolve() -> Any {
    switch self {
    case .shared(let object): return object
    case .factory(let block): return block()
    }
  }
}
