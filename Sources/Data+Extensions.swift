//
//  File.swift
//  
//
//  Created by Pankaj Soni on 12/05/21.
//

import Foundation

extension Data {
    init<T>(value: T) {
        self = withUnsafePointer(to: value) { (ptr: UnsafePointer<T>) -> Data in
            return Data(buffer: UnsafeBufferPointer(start: ptr, count: 1))
        }
    }

    mutating func append<T>(value: T) {
        withUnsafePointer(to: value) { (ptr: UnsafePointer<T>) in
            append(UnsafeBufferPointer(start: ptr, count: 1))
        }
    }
}
