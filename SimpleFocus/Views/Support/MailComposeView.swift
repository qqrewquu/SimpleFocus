//
//  MailComposeView.swift
//  SimpleFocus
//
//  Created by Codex on 2025-11-09.
//

import MessageUI
import SwiftUI

struct MailComposeView: UIViewControllerRepresentable {
    final class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let parent: MailComposeView

        init(parent: MailComposeView) {
            self.parent = parent
        }

        func mailComposeController(_ controller: MFMailComposeViewController,
                                   didFinishWith result: MFMailComposeResult,
                                   error: Error?) {
            controller.dismiss(animated: true) { [weak self] in
                guard let self else { return }
                if let error {
                    self.parent.completion(.failure(error))
                } else {
                    self.parent.completion(.success(result))
                }
            }
        }
    }

    var recipients: [String]
    var subject: String
    var body: String
    var completion: (Result<MFMailComposeResult, Error>) -> Void

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        vc.mailComposeDelegate = context.coordinator
        vc.setToRecipients(recipients)
        vc.setSubject(subject)
        vc.setMessageBody(body, isHTML: false)
        return vc
    }

    func updateUIViewController(_ controller: MFMailComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
}
