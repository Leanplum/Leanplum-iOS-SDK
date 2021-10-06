//
//  MessageControllerDelegate.swift
//  LeanplumSDK
//
//  Created by Milos Jakovljevic on 21.09.21.
//

import Foundation

public enum MessageDisplayChoice {
    case show
    case discard
    case delay(seconds: Int)
}

public protocol MessageControllerDelegate {
    
    /// called per message to decide whether to show/discard or delay it
    func shouldDisplayMessage(action: ActionContext) -> MessageDisplayChoice
    
    /// called when there are multiple messages to be desplay for client to order
    /// or remove from chain message that we dont want to present
    func messageDisplayOrder(trigger: [String: String], actions: [ActionContext]) -> [ActionContext]
}
