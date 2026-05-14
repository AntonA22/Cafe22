//
//  TextFieldCell.swift
//  Cafe
//
//  Created by Антон Абалуев on 05.01.2026.
//

import UIKit

final class TextFieldCell: UITableViewCell, UITextFieldDelegate {

    static let reuseId = "TextFieldCell"

    private let titleLabel = UILabel()
    private let textField = UITextField()
    private var onChange: ((String) -> Void)?
    private var onReturn: (() -> Void)?
    private var isPhone = false

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        selectionStyle = .none

        titleLabel.font = .systemFont(ofSize: 16)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        textField.font = .systemFont(ofSize: 16)
        textField.textAlignment = .right
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.delegate = self
        textField.addTarget(self, action: #selector(textChanged), for: .editingChanged)

        contentView.addSubview(titleLabel)
        contentView.addSubview(textField)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            textField.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: 12),
            textField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            textField.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(
        title: String,
        value: String,
        keyboard: UIKeyboardType,
        autocap: UITextAutocapitalizationType,
        returnKey: UIReturnKeyType = .default,
        onReturn: (() -> Void)? = nil,
        onChange: @escaping (String) -> Void
    ) {
        titleLabel.text = title
        textField.keyboardType = keyboard
        textField.returnKeyType = returnKey
        textField.autocapitalizationType = autocap
        textField.autocorrectionType = .no
        self.onChange = onChange
        self.onReturn = onReturn

        isPhone = (keyboard == .phonePad)

        if isPhone {
            textField.text = value.isEmpty ? "" : formatPhone(value)
            let toolbar = UIToolbar()
            toolbar.sizeToFit()
            let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
            let doneBtn = UIBarButtonItem(title: "Готово", style: .done, target: textField, action: #selector(UITextField.resignFirstResponder))
            toolbar.items = [spacer, doneBtn]
            textField.inputAccessoryView = toolbar
        } else {
            textField.text = value
            textField.inputAccessoryView = nil
        }
    }

    // MARK: - Phone formatting

    private func formatPhone(_ input: String) -> String {
        var digits = input.filter { $0.isNumber }
        guard !digits.isEmpty else { return "" }

        if digits.hasPrefix("8") { digits = "7" + digits.dropFirst() }
        if !digits.hasPrefix("7") { digits = "7" + digits }
        digits = String(digits.prefix(11))

        let chars = Array(digits.dropFirst())
        var result = "+7"

        if !chars.isEmpty {
            result += " (" + String(chars.prefix(3))
            if chars.count >= 3 { result += ")" }
        }
        if chars.count > 3 {
            result += " " + String(chars[3..<min(6, chars.count)])
        }
        if chars.count > 6 {
            result += "-" + String(chars[6..<min(8, chars.count)])
        }
        if chars.count > 8 {
            result += "-" + String(chars[8..<min(10, chars.count)])
        }

        return result
    }

    // MARK: - UITextFieldDelegate

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard isPhone else { return true }

        let current = textField.text ?? ""
        guard let swiftRange = Range(range, in: current) else { return false }
        let updated = current.replacingCharacters(in: swiftRange, with: string)

        let formatted = formatPhone(updated)
        textField.text = formatted
        onChange?(formatted)
        return false
    }

    func activateTextField() {
        textField.becomeFirstResponder()
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        onReturn?()
        return true
    }

    @objc private func textChanged() {
        guard !isPhone else { return }
        onChange?(textField.text ?? "")
    }
}
