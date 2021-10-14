//
//  LeanplumUtils.swift
//  LeanplumSDK
//
//  Created by Nikola Zagorchev on 20.09.21.
//

import Foundation

public class LeanplumUtils: NSObject {

    static func lpLog(type:Leanplum.LogTypeNew, format:String, _ args:CVarArg...) {
        LPLogv(type, format, getVaList(args))
    }
    
    static func getNotificationId(_ userInfo: [AnyHashable:Any]) -> String {
        var notifId = "-1"
        let id:Int = userInfo["id"] as? Int ?? -1
        if id == -1, let occId = userInfo["lp_occurrence_id"] as? String {
            notifId = occId
        } else {
            notifId = String(id)
        }
        
        return notifId
    }
}
