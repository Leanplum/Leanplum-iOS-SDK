//
//  Dictionary+ValueKeyPath.swift
//  LeanplumSDK
//
//  Created by Nikola Zagorchev on 13.04.22.
//  Original source from https://oleb.net/blog/2017/01/dictionary-key-paths/
//

import Foundation

public struct ValueKeyPath {
    public static let defaultSeparator = "."
    
    var separator: String
    var segments: [String]
    
    var isEmpty: Bool { return segments.isEmpty }
    var path: String {
        return segments.joined(separator: separator)
    }
    
    init(_ string: String, _ separator: String = defaultSeparator) {
        segments = string.components(separatedBy: separator)
        self.separator = separator
    }
    
    init(segments: [String], separator: String = defaultSeparator) {
        self.segments = segments
        self.separator = separator
    }
    
    /// Strips off the first segment and returns a pair
    /// consisting of the first segment and the remaining key path.
    /// Returns nil if the key path has no segments.
    func headAndTail() -> (head: String, tail: ValueKeyPath)? {
        guard !isEmpty else { return nil }
        var tail = segments
        let head = tail.removeFirst()
        return (head, ValueKeyPath(segments: tail, separator: separator))
    }
}

/// Express ValueKeyPath as a string literal e.g. "some.key.path"
/// Uses default separator
extension ValueKeyPath: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(value)
    }
    public init(unicodeScalarLiteral value: String) {
        self.init(value)
    }
    public init(extendedGraphemeClusterLiteral value: String) {
        self.init(value)
    }
}

public extension Dictionary where Key == AnyHashable {
    subscript(valueKeyPath keyPath: ValueKeyPath) -> Any? {
        get {
            switch keyPath.headAndTail() {
            case nil:
                // key path is empty.
                return nil
            case let (head, remainingKeyPath)? where remainingKeyPath.isEmpty:
                // Reached the end of the key path.
                let key = Key(head)
                return self[key]
            case let (head, remainingKeyPath)?:
                // Key path has a tail we need to traverse.
                let key = Key(head)
                switch self[key] {
                case let nestedDict as [Key: Any]:
                    // Next nest level is a dictionary.
                    // Start over with remaining key path.
                    return nestedDict[valueKeyPath: remainingKeyPath]
                default:
                    // Next nest level isn't a dictionary.
                    // Invalid key path, abort.
                    return nil
                }
            }
        }
        
        set {
            switch keyPath.headAndTail() {
            case nil:
                // key path is empty.
                return
            case let (head, remainingKeyPath)? where remainingKeyPath.isEmpty:
                // Reached the end of the key path.
                let key = Key(head)
                self[key] = newValue as? Value
            case let (head, remainingKeyPath)?:
                let key = Key(head)
                let value = self[key]
                switch value {
                case var nestedDict as [Key: Any]:
                    // Key path has a tail we need to traverse
                    nestedDict[valueKeyPath: remainingKeyPath] = newValue
                    self[key] = nestedDict as? Value
                default:
                    // Store a new empty dictionary and continue
                    var nestedDict = [Key: Any]()
                    nestedDict[valueKeyPath: remainingKeyPath] = newValue
                    self[key] = nestedDict as? Value
                    return
                }
            }
        }
    }
    
    /// Access using string variable e.g. [myString]
    /// Uses default separator
    subscript(stringKeyPath keyPath: String) -> Any? {
        get {
            return self[valueKeyPath: ValueKeyPath(keyPath)]
        }
        set {
            self[valueKeyPath: ValueKeyPath(keyPath)] = newValue
        }
    }
}

