//
//  Scope.swift
//
//  Created by Dzmitry Duleba on 02/09/2022.
//

import Foundation

public protocol IDependencies {}

@dynamicMemberLookup
public protocol IScoped {
  
  associatedtype ScopeDependencies: IDependencies
  
  var __dependencies: ScopeDependencies { get }
  
}

public extension IScoped {
  
  subscript<T>(dynamicMember keyPath: KeyPath<ScopeDependencies, T>) -> T {
    __dependencies[keyPath: keyPath]
  }
  
}
