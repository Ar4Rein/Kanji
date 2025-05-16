//
//  SpecificLanguageTextFieldView.swift
//  KanjiQuizApp
//
//  Created by Muhammad Ardiansyah on 09/05/25.
//

import SwiftUI
import UIKit

class SpecificLanguageTextField: UITextField {
    var language: String? {
        didSet {
            if self.isFirstResponder {
                self.resignFirstResponder()
                self.becomeFirstResponder()
            }
        }
    }
    
    let padding = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }
    
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }

    override var textInputMode: UITextInputMode? {
        if let language = self.language {
            for inputMode in UITextInputMode.activeInputModes {
                if inputMode.primaryLanguage == language {
                    return inputMode
                }
            }
        }
        return super.textInputMode
    }
}

struct SpecificLanguageTextFieldView: UIViewRepresentable {
    let placeHolder: String
    var language: String = "ja-JP"
    @Binding var text: String

    func makeUIView(context: Context) -> UITextField {
        let textField = SpecificLanguageTextField(frame: .zero)
        textField.placeholder = self.placeHolder
        textField.language = self.language
        textField.delegate = context.coordinator
        
        textField.borderStyle = .none
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.gray.cgColor
        textField.layer.cornerRadius = 10
        textField.layer.masksToBounds = true
        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        uiView.text = text
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: SpecificLanguageTextFieldView

        init(_ parent: SpecificLanguageTextFieldView) {
            self.parent = parent
        }

        func textFieldDidChangeSelection(_ textField: UITextField) {
            parent.text = textField.text ?? ""
        }
    }
}
