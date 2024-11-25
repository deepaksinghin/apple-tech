//
//  Atomic.swift
//  SpeechToText
//
//  Created by Deepak Singh on 25/11/24.
//

import Foundation

final class Atomic<A> {
    private let queue = DispatchQueue(label: "atomic-serial-queue")
    private var _value: A
    init(_ value: A) {
        _value = value
    }

    var value: A {
        return queue.sync { self._value }
    }

    func mutate(_ transform: (inout A) -> Void) {
        queue.sync {
            transform(&self._value)
        }
    }
}
