import UIKit
import SnapKit



struct RegistrationRequest: Codable {
    let login: String
    let email: String
    let name: String
    let password1: String
    let password2: String
}

struct UserInsert: Codable {
    let username: String
    let email: String
    let name: String
    let password: String
}

struct ProfileInsert: Codable {
    let email: String
    let name: String
    let password: String
}

final class RegistrationViewController: UIViewController, UITextFieldDelegate {
    
    // MARK: - UI

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let titleLabel = UILabel()

    private let emailLabel = UILabel()
    private let emailTF = UITextField()

    private let loginLabel = UILabel()
    private let loginTF = UITextField()

    private let firstNameLabel = UILabel()
    private let firstNameTF = UITextField()

    private let lastNameLabel = UILabel()
    private let lastNameTF = UITextField()

    private let phoneLabel = UILabel()
    private let phoneTF = UITextField()

    private let passwordLabel = UILabel()
    private let passwordTF = UITextField()
    private let passwordToggleButton = UIButton(type: .custom)
    private let passwordHintLabel = UILabel()
    private let confirmPasswordLabel = UILabel()
    private let confirmPasswordTF = UITextField()
    private let confirmPasswordToggleButton = UIButton(type: .custom)
    private let confirmPasswordHintLabel = UILabel()

    private let errorLabel = UILabel()

    private let registerButton = UIButton(type: .system)
    private let infoLabel = UILabel()
    private let backButton = UIButton(type: .system)
    private weak var activeTextField: UITextField?

    // MARK: - Services

    private let supabase = SupabaseService.shared.client

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        useRussianBackButtonTitle()
        setupUI()
        setupActions()
        updateRegisterButton()
        setupHideKeyboardOnTap()
        setupKeyboardObservers()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func dismissKeyboard(_ gesture: UITapGestureRecognizer) {
        view.endEditing(true)
    }

    private func setupHideKeyboardOnTap() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard(_:)))
        tapGesture.cancelsTouchesInView = false
        scrollView.addGestureRecognizer(tapGesture)
    }

    // MARK: - UI Setup

    private func setupUI() {
        view.backgroundColor = .white

        scrollView.keyboardDismissMode = .interactive
        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        scrollView.snp.makeConstraints {
            $0.edges.equalTo(view.safeAreaLayoutGuide)
        }

        contentView.snp.makeConstraints {
            $0.edges.equalTo(scrollView.contentLayoutGuide)
            $0.width.equalTo(scrollView.frameLayoutGuide)
        }

        // Title
        titleLabel.text = "Регистрация нового\nаккаунта"
        titleLabel.font = .boldSystemFont(ofSize: 28)
        titleLabel.numberOfLines = 2

        // Labels
        configureLabel(emailLabel, text: "Email")
        configureLabel(loginLabel, text: "Логин")
        configureLabel(firstNameLabel, text: "Имя")
        configureLabel(lastNameLabel, text: "Фамилия")
        configureLabel(phoneLabel, text: "Телефон")
        configureLabel(passwordLabel, text: "Пароль")
        configureLabel(confirmPasswordLabel, text: "Повторите пароль")

        // TextFields
        configureTextField(
            emailTF,
            placeholder: "Введите почту",
            keyboard: .emailAddress,
            returnKey: .next,
            autocapitalization: .none,
            autocorrection: .no
        )
        configureTextField(
            loginTF,
            placeholder: "Введите логин",
            returnKey: .next,
            autocapitalization: .none,
            autocorrection: .no
        )
        configureTextField(
            firstNameTF,
            placeholder: "Введите имя",
            returnKey: .next,
            autocapitalization: .words,
            autocorrection: .no
        )
        configureTextField(
            lastNameTF,
            placeholder: "Введите фамилию",
            returnKey: .next,
            autocapitalization: .words,
            autocorrection: .no
        )
        configureTextField(
            phoneTF,
            placeholder: "+7 (999) 123-45-67",
            keyboard: .phonePad,
            returnKey: .next,
            autocapitalization: .none,
            autocorrection: .no
        )
        configureTextField(passwordTF, placeholder: "Введите пароль", secure: true, returnKey: .next)
        configureTextField(confirmPasswordTF, placeholder: "Повторите пароль", secure: true, returnKey: .done)
        configurePasswordToggleButton(passwordToggleButton, for: passwordTF)
        configurePasswordToggleButton(confirmPasswordToggleButton, for: confirmPasswordTF)
        configurePasswordHintLabel()
        configureConfirmPasswordHintLabel()

        // Error
        errorLabel.text = "Ошибка регистрации"
        errorLabel.font = .systemFont(ofSize: 12)
        errorLabel.textColor = .systemRed
        errorLabel.isHidden = true

        // Register button
        registerButton.setTitle("Зарегистрироваться", for: .normal)
        registerButton.layer.cornerRadius = 10
        registerButton.setTitleColor(.white, for: .normal)
        registerButton.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.5)
        registerButton.isEnabled = false

        // Info
        infoLabel.text = "Уже есть аккаунт в системе?"
        infoLabel.font = .systemFont(ofSize: 13)
        infoLabel.textColor = UIColor(hex: "#546E7A")
        infoLabel.textAlignment = .center

        // Назад
        backButton.setTitle("Вернуться к авторизации", for: .normal)
        backButton.layer.cornerRadius = 10
        backButton.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.15)
        backButton.setTitleColor(.systemBlue, for: .normal)

        // Add
        [
            titleLabel,
            emailLabel, emailTF,
            errorLabel,
            loginLabel, loginTF,
            firstNameLabel, firstNameTF,
            lastNameLabel, lastNameTF,
            phoneLabel, phoneTF,
            passwordLabel, passwordTF,
            passwordHintLabel,
            confirmPasswordLabel, confirmPasswordTF,
            confirmPasswordHintLabel,
            registerButton,
            infoLabel,
            backButton
        ].forEach { contentView.addSubview($0) }

        // Layout
        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(16)
            $0.leading.trailing.equalToSuperview().inset(16)
        }

        layoutField(emailLabel, emailTF, top: titleLabel.snp.bottom, offset: 24)
        errorLabel.snp.makeConstraints {
            $0.top.equalTo(emailTF.snp.bottom).offset(6)
            $0.leading.trailing.equalToSuperview().inset(16)
        }
        layoutField(loginLabel, loginTF, top: errorLabel.snp.bottom, offset: 16)
        layoutField(firstNameLabel, firstNameTF, top: loginTF.snp.bottom, offset: 16)
        layoutField(lastNameLabel, lastNameTF, top: firstNameTF.snp.bottom, offset: 16)
        layoutField(phoneLabel, phoneTF, top: lastNameTF.snp.bottom, offset: 16)
        layoutField(passwordLabel, passwordTF, top: phoneTF.snp.bottom, offset: 16)
        passwordHintLabel.snp.makeConstraints {
            $0.top.equalTo(passwordTF.snp.bottom).offset(6)
            $0.leading.trailing.equalToSuperview().inset(16)
        }
        layoutField(confirmPasswordLabel, confirmPasswordTF, top: passwordHintLabel.snp.bottom, offset: 16)
        confirmPasswordHintLabel.snp.makeConstraints {
            $0.top.equalTo(confirmPasswordTF.snp.bottom).offset(6)
            $0.leading.trailing.equalToSuperview().inset(16)
        }

        registerButton.snp.makeConstraints {
            $0.top.equalTo(confirmPasswordHintLabel.snp.bottom).offset(24)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(50)
        }

        infoLabel.snp.makeConstraints {
            $0.top.equalTo(registerButton.snp.bottom).offset(20)
            $0.centerX.equalToSuperview()
        }

        backButton.snp.makeConstraints {
            $0.top.equalTo(infoLabel.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(50)
            $0.bottom.equalToSuperview().inset(24)
        }
    }

    // MARK: - Actions

    private func setupActions() {
        [emailTF, loginTF, firstNameTF, lastNameTF, phoneTF, passwordTF, confirmPasswordTF].forEach {
            $0.addTarget(self, action: #selector(textChanged), for: .editingChanged)
        }
        registerButton.addTarget(self, action: #selector(registerTapped), for: .touchUpInside)
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
    }

    @objc private func textChanged() {
        resetError()
        updateRegisterButton()
    }

    @objc private func registerTapped() {
        guard
            let email = emailTF.text?.trimmingCharacters(in: .whitespacesAndNewlines), !email.isEmpty,
            let login = loginTF.text?.trimmingCharacters(in: .whitespacesAndNewlines), !login.isEmpty,
            let firstName = firstNameTF.text?.trimmingCharacters(in: .whitespacesAndNewlines), !firstName.isEmpty,
            let lastName = lastNameTF.text?.trimmingCharacters(in: .whitespacesAndNewlines), !lastName.isEmpty,
            let phoneText = phoneTF.text?.trimmingCharacters(in: .whitespacesAndNewlines), !phoneText.isEmpty,
            let password = passwordTF.text, !password.isEmpty,
            let confirmPassword = confirmPasswordTF.text, !confirmPassword.isEmpty
        else {
            showError("Заполните все поля")
            return
        }

        let normalizedPhone = normalizedPhoneForAPI(from: phoneText)
        guard normalizedPhone.count == 12 else {
            showError("Введите телефон полностью")
            return
        }

        guard password.count >= 6 else {
            showError("Пароль должен быть не короче 6 символов")
            return
        }

        guard password == confirmPassword else {
            showError("Пароли не совпадают")
            return
        }

        Task {
            do {
                try await AuthService.shared.register(
                    username: login,
                    email: email,
                    phone: normalizedPhone,
                    firstName: firstName,
                    lastName: lastName,
                    password: password,
                    passwordConfirmation: confirmPassword
                )

                await MainActor.run {
                    navigationController?.popViewController(animated: true)
                }

            } catch {
                await MainActor.run {
                    // если у тебя APIError: LocalizedError (как я делал) — покажет текст с сервера/422
                    showError(error.localizedDescription.isEmpty ? "Ошибка регистрации" : error.localizedDescription)
                }
                print("Register error:", error)
            }
        }
    }

    @objc private func backTapped() {
        if let nav = navigationController {
            nav.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }

    // MARK: - Helpers

    private func updateRegisterButton() {
        let phoneFilled = normalizedPhoneForAPI(from: phoneTF.text ?? "").count == 12
        let passwordValid = (passwordTF.text?.count ?? 0) >= 6
        let passwordsMatch = !(confirmPasswordTF.text?.isEmpty ?? true) && passwordTF.text == confirmPasswordTF.text
        let filled = !(emailTF.text?.isEmpty ?? true)
            && !(loginTF.text?.isEmpty ?? true)
            && !(firstNameTF.text?.isEmpty ?? true)
            && !(lastNameTF.text?.isEmpty ?? true)
            && phoneFilled
            && passwordValid
            && passwordsMatch

        passwordHintLabel.textColor = passwordTF.text?.isEmpty ?? true ? UIColor(hex: "#90A4AE") : (passwordValid ? .systemGreen : .systemRed)
        confirmPasswordHintLabel.textColor = confirmPasswordTF.text?.isEmpty ?? true ? UIColor(hex: "#90A4AE") : (passwordsMatch ? .systemGreen : .systemRed)

        registerButton.isEnabled = filled
        registerButton.backgroundColor = filled ? .systemBlue : .systemBlue.withAlphaComponent(0.5)
    }

    private func showError(_ text: String) {
        errorLabel.text = text
        errorLabel.isHidden = false
    }

    private func resetError() {
        errorLabel.isHidden = true
    }

    private func configurePasswordHintLabel() {
        passwordHintLabel.text = "Минимум 6 символов"
        passwordHintLabel.font = .systemFont(ofSize: 12)
        passwordHintLabel.textColor = UIColor(hex: "#90A4AE")
        passwordHintLabel.numberOfLines = 0
    }

    private func configureConfirmPasswordHintLabel() {
        confirmPasswordHintLabel.text = "Пароли должны совпадать"
        confirmPasswordHintLabel.font = .systemFont(ofSize: 12)
        confirmPasswordHintLabel.textColor = UIColor(hex: "#90A4AE")
        confirmPasswordHintLabel.numberOfLines = 0
    }

    private func configureLabel(_ label: UILabel, text: String) {
        label.text = text
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.textColor = UIColor(red: 144/255, green: 164/255, blue: 174/255, alpha: 1)
    }

    private func configureTextField(
        _ tf: UITextField,
        placeholder: String,
        keyboard: UIKeyboardType = .default,
        secure: Bool = false,
        returnKey: UIReturnKeyType = .default,
        autocapitalization: UITextAutocapitalizationType = .sentences,
        autocorrection: UITextAutocorrectionType = .default
    ) {
        tf.placeholder = placeholder
        tf.font = .systemFont(ofSize: 15)
        tf.layer.cornerRadius = 10
        tf.layer.borderWidth = 1
        tf.layer.borderColor = UIColor(red: 207/255, green: 216/255, blue: 220/255, alpha: 1).cgColor
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 1))
        tf.leftViewMode = .always
        tf.keyboardType = keyboard
        tf.returnKeyType = returnKey
        tf.isSecureTextEntry = secure
        tf.autocapitalizationType = autocapitalization
        tf.autocorrectionType = autocorrection
        tf.delegate = self

        if keyboard == .phonePad {
            let toolbar = UIToolbar()
            toolbar.sizeToFit()
            let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
            let doneBtn = UIBarButtonItem(title: "Готово", style: .done, target: tf, action: #selector(UITextField.resignFirstResponder))
            toolbar.items = [spacer, doneBtn]
            tf.inputAccessoryView = toolbar
        }
    }

    private func configurePasswordToggleButton(_ button: UIButton, for textField: UITextField) {
        button.setImage(UIImage(systemName: "eye.slash"), for: .normal)
        button.tintColor = UIColor(red: 144/255, green: 164/255, blue: 174/255, alpha: 1)
        button.addTarget(self, action: #selector(togglePasswordVisibility(_:)), for: .touchUpInside)

        let container = UIView(frame: CGRect(x: 0, y: 0, width: 48, height: 40))
        button.frame = CGRect(x: 0, y: 0, width: 36, height: 40)
        container.addSubview(button)
        textField.rightView = container
        textField.rightViewMode = .always
    }

    @objc private func togglePasswordVisibility(_ sender: UIButton) {
        let textField: UITextField?

        switch sender {
        case passwordToggleButton:
            textField = passwordTF
        case confirmPasswordToggleButton:
            textField = confirmPasswordTF
        default:
            textField = nil
        }

        guard let textField else { return }

        textField.isSecureTextEntry.toggle()
        let imageName = textField.isSecureTextEntry ? "eye.slash" : "eye"
        sender.setImage(UIImage(systemName: imageName), for: .normal)
    }

    private func layoutField(
        _ label: UILabel,
        _ field: UITextField,
        top: ConstraintItem,
        offset: CGFloat
    ) {
        label.snp.makeConstraints {
            $0.top.equalTo(top).offset(offset)
            $0.leading.trailing.equalToSuperview().inset(16)
        }
        field.snp.makeConstraints {
            $0.top.equalTo(label.snp.bottom).offset(4)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(50)
        }
    }

    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillChangeFrame),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    @objc private func keyboardWillChangeFrame(_ notification: Notification) {
        guard
            let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue,
            let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
            let curveValue = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt
        else { return }

        let keyboardInView = view.convert(keyboardValue.cgRectValue, from: nil)
        let coveredHeight = max(0, view.bounds.maxY - keyboardInView.minY - view.safeAreaInsets.bottom)
        let inset = coveredHeight + 16
        let options = UIView.AnimationOptions(rawValue: curveValue << 16)

        UIView.animate(withDuration: duration, delay: 0, options: options) {
            self.scrollView.contentInset.bottom = inset
            self.scrollView.verticalScrollIndicatorInsets.bottom = inset
        } completion: { _ in
            self.scrollActiveFieldIntoView()
        }
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval ?? 0.25
        let curveValue = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt ?? 0
        let options = UIView.AnimationOptions(rawValue: curveValue << 16)

        UIView.animate(withDuration: duration, delay: 0, options: options) {
            self.scrollView.contentInset.bottom = 0
            self.scrollView.verticalScrollIndicatorInsets.bottom = 0
        }
    }

    private func scrollActiveFieldIntoView() {
        guard let activeTextField else { return }

        let fieldFrame = activeTextField.convert(activeTextField.bounds, to: scrollView)
        scrollView.scrollRectToVisible(fieldFrame.insetBy(dx: 0, dy: -24), animated: true)
    }

    private func formatPhone(_ input: String) -> String {
        var digits = input.filter { $0.isNumber }
        guard !digits.isEmpty else { return "" }

        if digits.hasPrefix("8") {
            digits = "7" + digits.dropFirst()
        }
        if !digits.hasPrefix("7") {
            digits = "7" + digits
        }
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

    private func normalizedPhoneForAPI(from input: String) -> String {
        var digits = input.filter { $0.isNumber }
        guard !digits.isEmpty else { return "" }

        if digits.hasPrefix("8") {
            digits = "7" + digits.dropFirst()
        }
        if !digits.hasPrefix("7") {
            digits = "7" + digits
        }

        digits = String(digits.prefix(11))
        return "+" + digits
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard textField === phoneTF else { return true }

        let current = textField.text ?? ""
        guard let swiftRange = Range(range, in: current) else { return false }
        let updated = current.replacingCharacters(in: swiftRange, with: string)

        textField.text = formatPhone(updated)
        resetError()
        updateRegisterButton()
        return false
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        activeTextField = textField
        scrollActiveFieldIntoView()
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        if activeTextField === textField {
            activeTextField = nil
        }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case emailTF:
            loginTF.becomeFirstResponder()
        case loginTF:
            firstNameTF.becomeFirstResponder()
        case firstNameTF:
            lastNameTF.becomeFirstResponder()
        case lastNameTF:
            phoneTF.becomeFirstResponder()
        case phoneTF:
            passwordTF.becomeFirstResponder()
        case passwordTF:
            confirmPasswordTF.becomeFirstResponder()
        default:
            textField.resignFirstResponder()
        }
        return true
    }
}

// MARK: - UIColor HEX

private extension UIColor {
    convenience init(hex: String) {
        var hex = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hex.removeFirst()
        var rgb: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&rgb)
        self.init(
            red: CGFloat((rgb >> 16) & 0xff) / 255,
            green: CGFloat((rgb >> 8) & 0xff) / 255,
            blue: CGFloat(rgb & 0xff) / 255,
            alpha: 1
        )
    }
}
