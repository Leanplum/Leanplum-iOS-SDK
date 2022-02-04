//
//  InterstitialViewController.swift
//  Leanplum
//
//  Created by Milos Jakovljevic on 3.2.22..
//

import Foundation

@available(iOS 11.0, *)
public class InterstitialViewController: UIViewController, Actionable, ObstructableView {
    public var context: ActionContext? {
        didSet {
            if context != oldValue {
                updateView()
            }
        }
    }
    
    public var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 1
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 20.0, weight: .semibold)
        return label
    }()
    
    public var messageLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 17, weight: .regular)
        return label
    }()
    
    public var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    public var actionButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.adjustsImageWhenHighlighted = true
        button.layer.masksToBounds = true
        button.layer.cornerRadius = 8
        button.contentEdgeInsets = .init(top: 10.0,
                                         left: 20.0,
                                         bottom: 10.0,
                                         right: 20.0)
        button.addTarget(self,
                         action: #selector(didAccept(_:)),
                         for: .touchUpInside)
        return button
    }()
    
    public var closeButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(.closeImage, for: .normal)
        button.addTarget(self,
                         action: #selector(didDismiss(_:)),
                         for: .touchUpInside)
        return button
    }()
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        updateView()
    }
    
    private func setupView() {
        view.addSubview(imageView)
        imageView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        imageView.heightAnchor.constraint(equalTo: view.heightAnchor).isActive = true
        
        view.addSubview(titleLabel)
        titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 32.0).isActive = true
        titleLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20.0).isActive = true
        titleLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20.0).isActive = true
        titleLabel.setContentHuggingPriority(.defaultHigh, for: .vertical)
        titleLabel.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)

        view.addSubview(messageLabel)
        messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10.0).isActive = true
        messageLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20.0).isActive = true
        messageLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20.0).isActive = true
        messageLabel.setContentHuggingPriority(.defaultLow, for: .vertical)
        messageLabel.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        
        view.addSubview(actionButton)
        actionButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 5).isActive = true
        actionButton.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor).isActive = true
        actionButton.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 5).isActive = true
        actionButton.setContentHuggingPriority(.defaultHigh, for: .vertical)
        actionButton.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        
        view.addSubview(closeButton)
        closeButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10.0).isActive = true
        closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10).isActive = true
        closeButton.widthAnchor.constraint(equalToConstant: 44.0).isActive = true
        closeButton.heightAnchor.constraint(equalToConstant: 44.0).isActive = true
    }
    
    private func updateView() {
        guard let context = context else {
            return
        }
        // background image and color
        context.color(name: LPMT_ARG_BACKGROUND_COLOR).map { view.backgroundColor = $0 }
        context.file(name: LPMT_ARG_BACKGROUND_IMAGE).map { imageView.image = UIImage(contentsOfFile: $0) }
        
        // title label
        context.string(name: LPMT_ARG_TITLE_TEXT).map { titleLabel.text = $0 }
        context.color(name: LPMT_ARG_TITLE_COLOR).map { titleLabel.textColor = $0 }
        
        // message label
        context.string(name: LPMT_ARG_MESSAGE_TEXT).map { messageLabel.text = $0 }
        context.color(name: LPMT_ARG_MESSAGE_COLOR).map { messageLabel.textColor = $0 }
        
        // accep action button
        context.string(name: LPMT_ARG_ACCEPT_BUTTON_TEXT).map { actionButton.setTitle($0, for: .normal) }
        context.color(name: LPMT_ARG_ACCEPT_BUTTON_TEXT_COLOR).map { actionButton.setTitleColor($0, for: .normal) }
        context.color(name: LPMT_ARG_ACCEPT_BUTTON_BACKGROUND_COLOR).map { actionButton.backgroundColor = $0 }
    }
}

@available(iOS 11.0, *)
extension InterstitialViewController {
    @objc fileprivate func didAccept(_ sender: UIButton) {
        context?.runTrackedAction(name: LPMT_ARG_ACCEPT_ACTION)
        dismiss(animated: true, completion: nil)
    }
    
    @objc fileprivate func didDismiss(_ sender: UIButton) {
        context?.runTrackedAction(name: LPMT_ARG_DISMISS_ACTION)
        dismiss(animated: true, completion: nil)
    }
}
