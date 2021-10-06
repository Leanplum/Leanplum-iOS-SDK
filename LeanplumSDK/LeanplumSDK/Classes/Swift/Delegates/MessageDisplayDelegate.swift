//
//  MessageDisplayDelegate.swift
//  LeanplumSDK
//
//  Created by Milos Jakovljevic on 21.09.21.
//

import Foundation

public protocol MessageDisplayDelegate {

    /// callend when the message is displayed
    func onMessageDisplayed(action: ActionContext)
    
    /// called when the message is dismissed
    func onMessageDismissed(action: ActionContext)
    
    /// called when the message is clicked
    func onMessageClicked(action: ActionContext)
}
