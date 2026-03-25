//
//  withObservationTracking.swift
//  TestManyToManyJoinTable
//
//  Created by Ben Davis on 3/25/26.
//

import Observation
import Foundation

public func withObservationTracking<T: Sendable>(of value: @Sendable @escaping @autoclosure () -> T, execute: @Sendable @escaping (T) -> Void) {
    Observation.withObservationTracking {
        execute(value())
    } onChange: {
        RunLoop.current.perform {
            withObservationTracking(of: value(), execute: execute)
        }
    }
}
