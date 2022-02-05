//
//  Configurable.swift
//  Leanplum
//
//  Created by Milos Jakovljevic on 5.2.22..
//

import Foundation

public protocol Configurable {
    associatedtype ConfigurationType
    var configuration: ConfigurationType { get set }
}
