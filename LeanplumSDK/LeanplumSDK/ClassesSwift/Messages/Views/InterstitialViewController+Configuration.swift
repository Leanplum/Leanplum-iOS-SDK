//
//  InterstitialViewController+Configuration.swift
//  Leanplum
//
//  Created by Milos Jakovljevic on 5.2.22..
//

import Foundation

@available(iOS 11.0, *)
extension InterstitialViewController {
    public struct Configuration {
        public var titleFont: UIFont
        public var messageFont: UIFont
        
        public init(titleFont: UIFont, messageFont: UIFont) {
            self.titleFont = titleFont
            self.messageFont = messageFont
        }
    }
}

@available(iOS 11.0, *)
extension InterstitialViewController.Configuration {
    public static var `default`: Self {
        .init(titleFont: .systemFont(ofSize: 20, weight: .semibold),
              messageFont: .systemFont(ofSize: 17, weight: .regular)
        )
    }
}
