//
//  Lock.swift
//
//  Created by Dzmitry Duleba on 18/11/2022.
//

import Foundation

protocol ILock {
  
  func lock()
  func unlock()
  func `try`() -> Bool
  
}

#if canImport(os)

import os

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
private final class OSAutomaticAllocatedUnfairLock: ILock {
  
  private let _lock = OSAllocatedUnfairLock()
  
  // MARK: - Public
  
  func lock() { _lock.lock() }
  func `try`() -> Bool { _lock.lockIfAvailable() }
  func unlock() { _lock.unlock() }
  
}

@available(iOS 10.0, macOS 10.12, tvOS 10.0, watchOS 3.0, *)
private final class OSManualAllocatedUnfairLock: ILock {
  
  private let _lock: os_unfair_lock_t

  init() {
    _lock = .allocate(capacity: 1)
    _lock.initialize(to: os_unfair_lock())
  }
  
  deinit {
    _lock.deinitialize(count: 1)
    _lock.deallocate()
  }
  
  // MARK: - Public

  func lock() { os_unfair_lock_lock(_lock) }
  func unlock() { os_unfair_lock_unlock(_lock) }
  func `try`() -> Bool { os_unfair_lock_trylock(_lock) }

}

#else

private final class PthreadLock: ILock {
  
  private let _lock: UnsafeMutablePointer<pthread_mutex_t>
  
  init(recursive: Bool = false) {
    _lock = .allocate(capacity: 1)
    _lock.initialize(to: pthread_mutex_t())
    
    let attr = UnsafeMutablePointer<pthread_mutexattr_t>.allocate(capacity: 1)
    attr.initialize(to: pthread_mutexattr_t())
    pthread_mutexattr_init(attr)
    
    defer {
      pthread_mutexattr_destroy(attr)
      attr.deinitialize(count: 1)
      attr.deallocate()
    }
    
    pthread_mutexattr_settype(attr, Int32(recursive ? PTHREAD_MUTEX_RECURSIVE : PTHREAD_MUTEX_ERRORCHECK))
    
    let status = pthread_mutex_init(_lock, attr)
    assert(status == 0, "Unexpected pthread mutex error code: \(status)")
  }
  
  deinit {
    let status = pthread_mutex_destroy(_lock)
    assert(status == 0, "Unexpected pthread mutex error code: \(status)")

    _lock.deinitialize(count: 1)
    _lock.deallocate()
  }
  
  // MARK: - Public
  
  func lock() {
    let status = pthread_mutex_lock(_lock)
    assert(status == 0, "Unexpected pthread mutex error code: \(status)")
  }
  
  func unlock() {
    let status = pthread_mutex_unlock(_lock)
    assert(status == 0, "Unexpected pthread mutex error code: \(status)")
  }
  
  func `try`() -> Bool {
    let status = pthread_mutex_trylock(_lock)
    switch status {
    case 0:
      return true
    case EBUSY, EAGAIN:
      return false
    default:
      assertionFailure("Unexpected pthread mutex error code: \(status)")
      return false
    }
  }
  
}

#endif

internal class Lock: ILock {
  
  private let impl: ILock
  
  private init(_ impl: ILock) {
    self.impl = impl
  }

  static func make() -> Lock {
    let impl: ILock
#if canImport(os)
    if #available(iOS 16.0, *) {
      impl = OSAutomaticAllocatedUnfairLock()
    } else {
      impl = OSManualAllocatedUnfairLock()
    }
#else
      impl = PthreadLock()
#endif
    
    return Lock(impl)
  }

  func lock() { impl.lock() }
  func unlock() { impl.unlock() }
  func `try`() -> Bool { impl.try() }
  
}
