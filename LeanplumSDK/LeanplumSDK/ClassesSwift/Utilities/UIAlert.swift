//
//  UIAlert.swift
//  LeanplumSDK
//
//  Created by Nikola Zagorchev on 4.06.22.
//

import Foundation

@objc public class UIAlert: NSObject {
    
    public typealias LeanplumUIAlertCompletionBlock = (Int) -> ()
    
    @objc public class func show(title: String, message: String, cancelButtonTitle: String, otherButtonTitles: [String], actionBlock: LeanplumUIAlertCompletionBlock?) {
        
        guard !ActionManager.shared.isPaused,
              ActionManager.shared.isEnabled else {
            return
        }
        
        let unpauseQueue: () -> () = {
            Log.debug("[ActionManager]: UIAlert dismissed, continuing queue.")
            ActionManager.shared.isPaused = false
        }

        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)

        let action = UIAlertAction(title: cancelButtonTitle, style: otherButtonTitles.isEmpty ? .cancel : .default) { _ in
            actionBlock?(0)
            unpauseQueue()
        }
        
        alertController.addAction(action)
        
        for (index, title) in otherButtonTitles.enumerated() {
            let action = UIAlertAction(title: title, style: .default) { _ in
                actionBlock?(index+1)
                unpauseQueue()
            }
            alertController.addAction(action)
        }
        
        let showAlert: () -> () = {
            UIApplication.shared.keyWindow?.rootViewController?.present(alertController, animated: true)
            LPCountAggregator.shared().incrementCount("show_With_title")
        }
        
        Log.debug("[ActionManager]: pausing queue to present UIAlert.")
        ActionManager.shared.isPaused = true
        if let action = ActionManager.shared.state.currentAction {
            Log.debug("[ActionManager]: asking for dismissal: \(action.context).")
            let definition = ActionManager.shared.definitions.first { $0.name == action.context.name }
            
            action.context.actionDidDismiss = {
                ActionManager.shared.state.currentAction = nil
                showAlert()
            }
            
            let _ = definition?.dismissAction?(action.context)
        } else {
            showAlert()
        }
    }
}
