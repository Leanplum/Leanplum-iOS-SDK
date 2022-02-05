//
//  Messages.swift
//  Leanplum
//
//  Created by Milos Jakovljevic on 4.2.22..
//

import Foundation

public enum Messages { }

extension Messages {
    @available(iOS 11.0, *)
    public enum Kind {
        case alert
        case centerPopup
        case confirm
        case interstitial(configuration: InterstitialViewController.Configuration?)
        case richInterstitial
        case webInterstitial
        case appRating
        case openURL
        case iconChange
        case pushAsk
        case registerPush
        
        var name: String {
            switch self {
                case .interstitial:
                    return LPMT_INTERSTITIAL_NAME
                default:
                    return ""
            }
        }
        
        var kind: Leanplum.ActionKind {
            switch self {
                case .interstitial:
                    return [.action, .message]
                default:
                    return .action
            }
        }
        
        var arguments: [ActionArg] {
            switch self {
                case .interstitial:
                    return ActionArg.interstitial
                default:
                    return []
            }
        }
        
        var presentHandler: LeanplumActionBlock? {
            switch self {
                case .interstitial(let configuration):
                    return viewController(type: InterstitialViewController.self, configuration: configuration)
                default:
                    return nil
            }
        }
        
        var dismissHandler: LeanplumActionBlock? {
            switch self {
                case .interstitial:
                    return nil
                default:
                    return nil
            }
        }
    }
}

@available(iOS 11.0, *)
extension Messages.Kind {
    /// Default case should have configuration set
    static var interstitial: Self {
        .interstitial(configuration: .default)
    }
}

@available(iOS 11.0, *)
extension Messages.Kind {
    fileprivate func viewController<ViewController: UIViewController>(type: ViewController.Type,
                                                                      configuration: AnyConfiguration? = nil) -> LeanplumActionBlock? where ViewController: Actionable & Configurable {
        return { context in
            var vc = type.init()
            vc.context = context
            if let configuration = configuration as? ViewController.ConfigurationType {
                vc.configuration = configuration
            }
            vc.modalPresentationStyle = .overFullScreen
            LPMessageTemplateUtilities.presentOverVisible(vc)
            return true
        }
    }
}

@available(iOS 11.0, *)
extension Messages {
    public static func defineActions() {
        let templates: [Kind] = [
            .interstitial
        ]
        templates.forEach {
            Leanplum.defineAction(name: $0.name,
                                  kind: $0.kind,
                                  args: $0.arguments,
                                  completion: $0.presentHandler)
        }
    }
    
    /// Defines an existing action with ability to use custom configuration
    public static func defineAction(kind: Kind) {
        Leanplum.defineAction(name: kind.name,
                              kind: kind.kind,
                              args: kind.arguments,
                              completion: kind.presentHandler)
    }
}
