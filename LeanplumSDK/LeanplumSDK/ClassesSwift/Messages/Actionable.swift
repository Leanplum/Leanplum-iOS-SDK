//
//  TemplateProtocol.swift
//  Leanplum
//
//  Created by Milos Jakovljevic on 3.2.22..
//

import Foundation

/// A protocol that indicates that conforming view is presenting an action
public protocol Actionable {
    var context: ActionContext? { get set }
    
    func dismissAction()
}

extension Actionable {
    public func dismissAction() {
        #warning("Call context.actionDismissed() when its merged with IAM handlers")
    }
}

/// A protocol to indicate that conforming view is obstructing the screen
/// (e.g. interstitial view).
public protocol ObstructableView { }

