//
//  ForgotViewController.swift
//  Cafe-iOS-Anton
//
//  Created by Антон Абалуев on 06.12.2025.
//

import UIKit
import SnapKit

// MARK: - Protocols


final class ForgotViewController: UIViewController, UITextFieldDelegate {

    // MARK: - UI

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let logoImageView = UIImageView()
    private let passwordRecoveryLabel = UILabel()

    private let loginLabel = UILabel()
    private let loginTF = UITextField()

    private let errorLabel = UILabel()
    private let passwordRecoveryButton = UIButton(type: .system)

    private let attentionMessageLabel2 = UILabel()
    private let attentionMessageLabel = UILabel()

    private let backButton = UIButton(type: .system)
    private var isLoading = false
    private weak var activeTextField: UITextField?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        useRussianBackButtonTitle()
        setupUI()
        updatePasswordRecoveryButtonState()
        setupKeyboardObservers()
        setupHideKeyboardOnTap()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
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

        // Logo
        contentView.addSubview(logoImageView)
        logoImageView.image = UIImage(named: "cafe") // <- положи лого в Assets и назови "AppLogo"
        logoImageView.contentMode = .scaleAspectFit
        logoImageView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalToSuperview().offset(24)
            $0.width.equalToSuperview().multipliedBy(0.6).priority(.high)
            $0.width.lessThanOrEqualTo(260)
            $0.height.equalTo(logoImageView.snp.width)
        }

        // Title
        contentView.addSubview(passwordRecoveryLabel)
        passwordRecoveryLabel.text = "Получение\nвременного пароля"
        passwordRecoveryLabel.font = .boldSystemFont(ofSize: 28)
        passwordRecoveryLabel.numberOfLines = 2
        passwordRecoveryLabel.snp.makeConstraints {
            $0.top.equalTo(logoImageView.snp.bottom).offset(24)
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.lessThanOrEqualToSuperview().inset(16)
        }

        // Login label
        contentView.addSubview(loginLabel)
        loginLabel.text = "Email"
        loginLabel.textColor = UIColor(red: 144/255.0, green: 164/255.0, blue: 174/255.0, alpha: 1.0)
        loginLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
        loginLabel.snp.makeConstraints {
            $0.top.equalTo(passwordRecoveryLabel.snp.bottom).offset(24)
            $0.leading.equalToSuperview().offset(16)
        }

        // TextField
        contentView.addSubview(loginTF)
        loginTF.placeholder = "Введите email"
        loginTF.font = UIFont.systemFont(ofSize: 15)
        loginTF.backgroundColor = .clear
        loginTF.layer.cornerRadius = 10
        loginTF.layer.borderWidth = 1
        loginTF.layer.borderColor = UIColor(red: 207/255.0, green: 216/255.0, blue: 220/255.0, alpha: 1.0).cgColor
        loginTF.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 1))
        loginTF.leftViewMode = .always
        loginTF.keyboardType = .emailAddress
        loginTF.autocapitalizationType = .none
        loginTF.autocorrectionType = .no
        loginTF.returnKeyType = .done
        loginTF.delegate = self
        loginTF.addTarget(self, action: #selector(loginTextFiledDidTapped(_:)), for: .editingChanged)
        loginTF.snp.makeConstraints {
            $0.left.right.equalToSuperview().inset(16)
            $0.top.equalTo(loginLabel.snp.bottom).offset(4)
            $0.height.equalTo(50)
        }

        // Error
        contentView.addSubview(errorLabel)
        errorLabel.text = "Не удалось отправить временный пароль"
        errorLabel.font = .systemFont(ofSize: 12)
        errorLabel.textColor = .red
        errorLabel.isHidden = true
        errorLabel.snp.makeConstraints {
            $0.left.right.equalToSuperview().inset(18)
            $0.top.equalTo(loginTF.snp.bottom).offset(6)
        }

        // Button
        contentView.addSubview(passwordRecoveryButton)
        passwordRecoveryButton.setTitle("Отправить временный пароль", for: .normal)
        passwordRecoveryButton.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        passwordRecoveryButton.layer.cornerRadius = 10
        passwordRecoveryButton.setTitleColor(.white, for: .normal)
        passwordRecoveryButton.backgroundColor = UIColor(red: 0/255, green: 122/255, blue: 255/255, alpha: 0.5)
        passwordRecoveryButton.isEnabled = false
        passwordRecoveryButton.addTarget(self, action: #selector(passwordRecoveryButtonTapped), for: .touchUpInside)
        passwordRecoveryButton.snp.makeConstraints {
            $0.left.right.equalToSuperview().inset(16)
            $0.top.equalTo(errorLabel.snp.bottom).offset(16)
            $0.height.equalTo(50)
        }

        // Success label (hidden by default)
        contentView.addSubview(attentionMessageLabel2)
        attentionMessageLabel2.text = "Временный пароль отправлен\nна указанную почту"
        attentionMessageLabel2.textColor = .black
        attentionMessageLabel2.numberOfLines = 2
        attentionMessageLabel2.font = .boldSystemFont(ofSize: 19)
        attentionMessageLabel2.isHidden = true
        attentionMessageLabel2.snp.makeConstraints {
            $0.top.equalTo(errorLabel.snp.bottom).offset(16)
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.equalToSuperview().inset(16)
        }

        // Info label
        contentView.addSubview(attentionMessageLabel)
        attentionMessageLabel.text = "Укажите email, который привязан к аккаунту. Мы отправим на него временный пароль. После входа рекомендуем сразу сменить пароль в профиле."
        attentionMessageLabel.textColor = UIColor(named: "#546E7A")
        attentionMessageLabel.numberOfLines = 0
        attentionMessageLabel.font = UIFont.systemFont(ofSize: 13)
        attentionMessageLabel.snp.makeConstraints {
            $0.top.equalTo(passwordRecoveryButton.snp.bottom).offset(24)
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.equalToSuperview().inset(16)
        }

        // Назад
        contentView.addSubview(backButton)
        backButton.setTitle("Вернуться к авторизации", for: .normal)
        backButton.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        backButton.layer.cornerRadius = 10
        backButton.backgroundColor = UIColor(red: 0/255, green: 122/255, blue: 255/255, alpha: 0.15)
        backButton.setTitleColor(.systemBlue, for: .normal)
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        backButton.snp.makeConstraints {
            $0.left.right.equalToSuperview().inset(16)
            $0.top.equalTo(attentionMessageLabel.snp.bottom).offset(20)
            $0.height.equalTo(50)
            $0.bottom.equalToSuperview().inset(24)
        }
    }

    // MARK: - Actions

    @objc private func loginTextFiledDidTapped(_ textField: UITextField) {
        resetAuthorizationError()
        updatePasswordRecoveryButtonState()
    }

    @objc private func passwordRecoveryButtonTapped() {
        guard let email = loginTF.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !email.isEmpty else {
            showAuthorizationError()
            return
        }

        resetAuthorizationError()
        setLoading(true)

        Task {
            do {
                try await AuthService.shared.forgotPassword(email: email)

                await MainActor.run {
                    self.setLoading(false)
                    self.showSuccess()
                }
            } catch {
                await MainActor.run {
                    self.setLoading(false)
                    self.showAuthorizationError(message: error.localizedDescription.isEmpty ? "Не удалось отправить временный пароль" : error.localizedDescription)
                }
            }
        }
    }

    @objc private func backButtonTapped() {
        if let nav = navigationController {
            nav.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }

    // MARK: - UI State

    private func updatePasswordRecoveryButtonState() {
        let isEmpty = loginTF.text?.isEmpty ?? true
        let isEnabled = !isEmpty && !isLoading
        passwordRecoveryButton.isEnabled = isEnabled
        passwordRecoveryButton.backgroundColor = isEnabled
            ? UIColor.systemBlue
            : UIColor(red: 0/255, green: 122/255, blue: 255/255, alpha: 0.5)
    }

    private func resetAuthorizationError() {
        loginTF.layer.borderColor = UIColor(red: 207/255.0, green: 216/255.0, blue: 220/255.0, alpha: 1.0).cgColor
        errorLabel.isHidden = true
    }

    func showAuthorizationError(message: String? = nil) {
        errorLabel.text = message ?? "Не удалось отправить временный пароль"
        loginTF.layer.borderColor = UIColor.red.cgColor
        errorLabel.isHidden = false
    }

    /// Вызывай это из presenter после успешной отправки письма
    func showSuccess() {
        attentionMessageLabel2.isHidden = false
        loginTF.isHidden = true
        loginLabel.isHidden = true
        passwordRecoveryButton.isHidden = true
        errorLabel.isHidden = true
        attentionMessageLabel.text = "Проверьте почту, войдите с временным паролем и затем поменяйте его в профиле."
    }

    private func setLoading(_ loading: Bool) {
        isLoading = loading
        passwordRecoveryButton.setTitle(loading ? "Отправляем..." : "Отправить временный пароль", for: .normal)
        loginTF.isEnabled = !loading
        backButton.isEnabled = !loading
        updatePasswordRecoveryButtonState()
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

    private func setupHideKeyboardOnTap() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        scrollView.addGestureRecognizer(tapGesture)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
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

    // MARK: - UITextFieldDelegate

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
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
}
