//
//  Messages+Args.swift
//  Leanplum
//
//  Created by Milos Jakovljevic on 4.2.22..
//

import Foundation
import CryptoKit

extension ActionArg {
    static let alert: [ActionArg] = [
        .init(name: LPMT_ARG_TITLE, string: Bundle.appName),
        .init(name: LPMT_ARG_MESSAGE, string: LPMT_DEFAULT_ALERT_MESSAGE),
        .init(name: LPMT_ARG_DISMISS_TEXT, string: LPMT_DEFAULT_OK_BUTTON_TEXT),
        .init(name: LPMT_ARG_DISMISS_ACTION, action: nil)
    ]
}

extension ActionArg {
    static let centerPopup: [ActionArg] = [
        .init(name: LPMT_ARG_TITLE_TEXT, string: Bundle.appName),
        .init(name: LPMT_ARG_TITLE_COLOR, color: .black),
        .init(name: LPMT_ARG_MESSAGE_TEXT, string: LPMT_DEFAULT_POPUP_MESSAGE),
        .init(name: LPMT_ARG_MESSAGE_COLOR, color: .black),
        .init(name: LPMT_ARG_BACKGROUND_IMAGE, file: nil),
        .init(name: LPMT_ARG_BACKGROUND_COLOR, color: .white),
        .init(name: LPMT_ARG_ACCEPT_BUTTON_TEXT, string: LPMT_DEFAULT_OK_BUTTON_TEXT),
        .init(name: LPMT_ARG_ACCEPT_BUTTON_BACKGROUND_COLOR, color: .white),
        .init(name: LPMT_ARG_ACCEPT_BUTTON_TEXT_COLOR, color: .blue),
        .init(name: LPMT_ARG_ACCEPT_ACTION, action: nil),
        .init(name: LPMT_ARG_LAYOUT_WIDTH, number: 300),
        .init(name: LPMT_ARG_LAYOUT_HEIGHT, number: 250)
    ]
}

extension ActionArg {
    static let confirm: [ActionArg] = [
        .init(name: LPMT_ARG_TITLE, string: Bundle.appName),
        .init(name: LPMT_ARG_MESSAGE, string: LPMT_DEFAULT_CONFIRM_MESSAGE),
        .init(name: LPMT_ARG_ACCEPT_TEXT, string: LPMT_DEFAULT_YES_BUTTON_TEXT),
        .init(name: LPMT_ARG_CANCEL_TEXT, string: LPMT_DEFAULT_NO_BUTTON_TEXT),
        .init(name: LPMT_ARG_ACCEPT_ACTION, action: nil),
        .init(name: LPMT_ARG_CANCEL_ACTION, action: nil)
    ]
}

extension ActionArg {
    static let interstitial: [ActionArg] = [
        .init(name: LPMT_ARG_TITLE_TEXT, string: Bundle.appName),
        .init(name: LPMT_ARG_TITLE_COLOR, color: .black),
        .init(name: LPMT_ARG_MESSAGE_TEXT, string: LPMT_DEFAULT_INTERSTITIAL_MESSAGE),
        .init(name: LPMT_ARG_MESSAGE_COLOR, color: .black),
        .init(name: LPMT_ARG_BACKGROUND_IMAGE, file: nil),
        .init(name: LPMT_ARG_BACKGROUND_COLOR, color: .white),
        .init(name: LPMT_ARG_ACCEPT_BUTTON_TEXT, string: LPMT_DEFAULT_OK_BUTTON_TEXT),
        .init(name: LPMT_ARG_ACCEPT_BUTTON_BACKGROUND_COLOR, color: .white),
        .init(name: LPMT_ARG_ACCEPT_BUTTON_TEXT_COLOR, color: .blue),
        .init(name: LPMT_ARG_ACCEPT_ACTION, action: nil)
    ]
}

extension ActionArg {
    static let richInterstital: [ActionArg] = [
        
    ]
}

extension ActionArg {
    static let pushAsk: [ActionArg] = [
        .init(name: LPMT_ARG_TITLE_TEXT, string: Bundle.appName),
        .init(name: LPMT_ARG_TITLE_COLOR, color: .black),
        .init(name: LPMT_ARG_MESSAGE_TEXT, string: LPMT_DEFAULT_INTERSTITIAL_MESSAGE),
        .init(name: LPMT_ARG_MESSAGE_COLOR, color: .black),
        .init(name: LPMT_ARG_BACKGROUND_IMAGE, file: nil),
        .init(name: LPMT_ARG_BACKGROUND_COLOR, color: .white),
        .init(name: LPMT_ARG_ACCEPT_BUTTON_TEXT, string: LPMT_DEFAULT_OK_BUTTON_TEXT),
        .init(name: LPMT_ARG_ACCEPT_BUTTON_BACKGROUND_COLOR, color: .white),
        .init(name: LPMT_ARG_ACCEPT_BUTTON_TEXT_COLOR, color: .blue),
        .init(name: LPMT_ARG_CANCEL_BUTTON_TEXT, string: LPMT_DEFAULT_OK_BUTTON_TEXT),
        .init(name: LPMT_ARG_CANCEL_BUTTON_BACKGROUND_COLOR, color: .white),
        .init(name: LPMT_ARG_CANCEL_BUTTON_TEXT_COLOR, color: .blue),
        .init(name: LPMT_ARG_LAYOUT_WIDTH, number: 300),
        .init(name: LPMT_ARG_LAYOUT_HEIGHT, number: 250)
    ]
}
