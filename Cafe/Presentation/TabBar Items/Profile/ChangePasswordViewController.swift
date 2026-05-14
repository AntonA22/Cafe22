import UIKit
import SnapKit

final class ChangePasswordViewController: UIViewController, UITextFieldDelegate {

    private let titleLabel = UILabel()
    private let newPasswordLabel = UILabel()
    private let newPasswordTF = UITextField()
    private let newPasswordToggleButton = UIButton(type: .custom)
    private let confirmPasswordLabel = UILabel()
    private let confirmPasswordTF = UITextField()
    private let confirmPasswordToggleButton = UIButton(type: .custom)
    private let errorLabel = UILabel()
    private let saveButton = UIButton(type: .system)
    private let loginInfoLabel = UILabel()

    private var isLoading = false

    override func viewDidLoad() {
        super.viewDidLoad()
        useRussianBackButtonTitle()
        setupUI()
        setupActions()
        updateSaveButtonState()
        setupHideKeyboardOnTap()
    }

    private func setupUI() {
        title = "Смена пароля"
        view.backgroundColor = .white

        titleLabel.text = "Изменение\nпароля"
        titleLabel.font = .boldSystemFont(ofSize: 28)
        titleLabel.numberOfLines = 2

        configureLabel(newPasswordLabel, text: "Новый пароль")
        configureLabel(confirmPasswordLabel, text: "Подтвердите пароль")

        configurePasswordTextField(newPasswordTF, placeholder: "Введите новый пароль", returnKey: .next)
        configurePasswordTextField(confirmPasswordTF, placeholder: "Повторите новый пароль", returnKey: .done)
        configurePasswordToggleButton(newPasswordToggleButton, for: newPasswordTF)
        configurePasswordToggleButton(confirmPasswordToggleButton, for: confirmPasswordTF)

        errorLabel.font = .systemFont(ofSize: 12)
        errorLabel.textColor = .systemRed
        errorLabel.numberOfLines = 0
        errorLabel.isHidden = true

        saveButton.setTitle("Сменить пароль", for: .normal)
        saveButton.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.5)
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.layer.cornerRadius = 10
        saveButton.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        saveButton.isEnabled = false

        loginInfoLabel.text = "После смены пароля приложение завершит текущую сессию. Затем войдите заново, используя новый пароль."
        loginInfoLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
        loginInfoLabel.numberOfLines = 0
        loginInfoLabel.textAlignment = .center
        loginInfoLabel.textColor = UIColor(red: 84/255.0, green: 110/255.0, blue: 122/255.0, alpha: 1.0)

        [
            titleLabel,
            newPasswordLabel, newPasswordTF,
            confirmPasswordLabel, confirmPasswordTF,
            errorLabel,
            saveButton,
            loginInfoLabel
        ].forEach { view.addSubview($0) }

        titleLabel.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            $0.leading.trailing.equalToSuperview().inset(16)
        }

        layoutField(newPasswordLabel, newPasswordTF, top: titleLabel.snp.bottom, offset: 24)
        layoutField(confirmPasswordLabel, confirmPasswordTF, top: newPasswordTF.snp.bottom, offset: 16)

        errorLabel.snp.makeConstraints {
            $0.top.equalTo(confirmPasswordTF.snp.bottom).offset(6)
            $0.leading.trailing.equalToSuperview().inset(16)
        }

        saveButton.snp.makeConstraints {
            $0.top.equalTo(errorLabel.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(50)
        }

        loginInfoLabel.snp.makeConstraints {
            $0.top.equalTo(saveButton.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview().inset(16)
        }
    }

    private func setupActions() {
        [newPasswordTF, confirmPasswordTF].forEach {
            $0.addTarget(self, action: #selector(textChanged), for: .editingChanged)
        }
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
    }

    @objc private func textChanged() {
        resetError()
        updateSaveButtonState()
    }

    @objc private func saveTapped() {
        let newPassword = (newPasswordTF.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let confirmPassword = (confirmPasswordTF.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

        guard !newPassword.isEmpty, !confirmPassword.isEmpty else {
            showError("Заполните все поля")
            return
        }

        guard newPassword.count >= 8 else {
            showError("Новый пароль должен быть минимум 8 символов")
            return
        }

        guard newPassword == confirmPassword else {
            showError("Новые пароли не совпадают")
            return
        }

        setLoading(true)

        Task {
            do {
                try await AuthService.shared.changePassword(
                    newPassword: newPassword,
                    confirmPassword: confirmPassword
                )

                await MainActor.run {
                    self.setLoading(false)
                    self.showSuccessAlert()
                }
            } catch {
                await MainActor.run {
                    self.setLoading(false)
                    self.showError(error.localizedDescription.isEmpty ? "Не удалось сменить пароль" : error.localizedDescription)
                }
            }
        }
    }

    private func updateSaveButtonState() {
        let filled = !(newPasswordTF.text?.isEmpty ?? true)
            && !(confirmPasswordTF.text?.isEmpty ?? true)

        let enabled = filled && !isLoading
        saveButton.isEnabled = enabled
        saveButton.backgroundColor = enabled ? .systemBlue : .systemBlue.withAlphaComponent(0.5)
    }

    private func setLoading(_ loading: Bool) {
        isLoading = loading
        saveButton.setTitle(loading ? "Сохраняем..." : "Сменить пароль", for: .normal)
        [newPasswordTF, confirmPasswordTF].forEach { $0.isEnabled = !loading }
        updateSaveButtonState()
    }

    private func showError(_ text: String) {
        errorLabel.text = text
        errorLabel.isHidden = false
    }

    private func resetError() {
        errorLabel.isHidden = true
    }

    private func showSuccessAlert() {
        let ac = UIAlertController(
            title: "Пароль изменён",
            message: "Теперь войдите в приложение с новым паролем.",
            preferredStyle: .alert
        )
        ac.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            self.openAuthScreen()
        })
        present(ac, animated: true)
    }

    private func openAuthScreen() {
        guard
            let windowScene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive }),
            let window = windowScene.windows.first(where: { $0.isKeyWindow }) ?? windowScene.windows.first
        else { return }

        let authVC = AuthViewController()
        let nav = UINavigationController(rootViewController: authVC)

        UIView.transition(with: window,
                          duration: 0.3,
                          options: [.transitionFlipFromLeft, .showHideTransitionViews],
                          animations: {
            window.rootViewController = nav
            window.makeKeyAndVisible()
        })
    }

    private func configureLabel(_ label: UILabel, text: String) {
        label.text = text
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.textColor = UIColor(red: 144/255, green: 164/255, blue: 174/255, alpha: 1)
    }

    private func configurePasswordTextField(_ tf: UITextField, placeholder: String, returnKey: UIReturnKeyType) {
        tf.placeholder = placeholder
        tf.font = .systemFont(ofSize: 15)
        tf.layer.cornerRadius = 10
        tf.layer.borderWidth = 1
        tf.layer.borderColor = UIColor(red: 207/255, green: 216/255, blue: 220/255, alpha: 1).cgColor
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 1))
        tf.leftViewMode = .always
        tf.isSecureTextEntry = true
        tf.autocapitalizationType = .none
        tf.autocorrectionType = .no
        tf.returnKeyType = returnKey
        tf.delegate = self
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
        case newPasswordToggleButton:
            textField = newPasswordTF
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

    private func layoutField(_ label: UILabel, _ field: UITextField, top: ConstraintItem, offset: CGFloat) {
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

    private func setupHideKeyboardOnTap() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case newPasswordTF:
            confirmPasswordTF.becomeFirstResponder()
        default:
            textField.resignFirstResponder()
        }
        return true
    }
}
