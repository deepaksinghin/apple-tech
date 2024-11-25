//
//  ActionSheetPresentable.swift
//
//  Created by Deepak Singh on 07/10/24.
//

import UIKit

protocol ActionSheetPresentable: AnyObject {
    func showMessage(message: String, title: String, onDismiss: @escaping () -> Void)
    func showActionSheet(title: String?, message: String?, options: [String], sourceView: UIView, sourceRect: CGRect, onOptionTap: @escaping (Int, String) -> Void)
    func showAlert(title: String, message: String, buttons: [String], onOptionTap: @escaping (Int) -> Void)
    func showNetworkError()
}

extension ActionSheetPresentable where Self: UIViewController {
    
    func showMessage(message: String, title: String = "DSN REPO", onDismiss: @escaping () -> Void) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { _ in onDismiss() }))
        DispatchQueue.main.async { self.present(alert, animated: true) }
    }

    func showActionSheet(title: String?, message: String?, options: [String], sourceView: UIView, sourceRect: CGRect, onOptionTap: @escaping (Int, String) -> Void) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        
        for (index, option) in options.enumerated() {
            let style: UIAlertAction.Style = (option.lowercased().contains("delete") || option == "Cancel") ? .destructive : .default
            alert.addAction(UIAlertAction(title: option, style: style, handler: { _ in onOptionTap(index, option) }))
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = sourceView
            popoverController.sourceRect = sourceRect
            popoverController.permittedArrowDirections = [.up, .down]
        }
        
        DispatchQueue.main.async { self.present(alert, animated: true) }
    }

    func showAlert(title: String, message: String, buttons: [String], onOptionTap: @escaping (Int) -> Void) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        for (index, buttonTitle) in buttons.enumerated() {
            if buttonTitle == "Sign Out" || buttonTitle == "Delete" || buttonTitle.lowercased().contains("Delete".lowercased()) {
                alert.addAction(UIAlertAction(title: buttonTitle, style: .destructive, handler: { _ in onOptionTap(index) }))
            } else {
                alert.addAction(UIAlertAction(title: buttonTitle, style: .default, handler: { _ in onOptionTap(index) }))
            }
        }
        
        DispatchQueue.main.async { self.present(alert, animated: true) }
    }
    
    func showNetworkError() {
        showMessage(message: "No internet connection found", title: "No Internet", onDismiss: {})
    }
}
