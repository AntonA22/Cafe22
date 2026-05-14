import UIKit
import SnapKit
import Supabase

final class AuthViewController: UIViewController, UITextFieldDelegate {

    // MARK: - UI
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let logoImageView = UIImageView()

    private let loginLabel = UILabel()
    private let loginTF = UITextField()

    private let passwordLabel = UILabel()
    private let passwordTF = UITextField()

    private let errorLabel = UILabel()

    private let forgotPasswordButton = UIButton(type: .system)
    private let loginButton = UIButton(type: .system)

    private let registrationLabel = UILabel()
    private let registrButton = UIButton(type: .system)

    private let passwordToggleButton = UIButton(type: .custom)

    private let loadingOverlay = UIView()
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private weak var activeTextField: UITextField?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        useRussianBackButtonTitle()
        setupUI()
        setupKeyboardObservers()
        setupHideKeyboardOnTap()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    private func setupHideKeyboardOnTap() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard(_:)))
        tapGesture.cancelsTouchesInView = false
        scrollView.addGestureRecognizer(tapGesture)
    }
       
    @objc private func dismissKeyboard(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: view)
        let tappedView = view.hitTest(location, with: nil)
        let excludedView: UIView = passwordToggleButton
        
        if tappedView?.isDescendant(of: excludedView) == true {
            return
        }
           
        view.endEditing(true)
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

        loginTF.delegate = self
        passwordTF.delegate = self

        // Logo
        logoImageView.image = UIImage(named: "cafe") // <-- поменяй на свой ассет (или Shark.I.logoImage если есть)
        logoImageView.contentMode = .scaleAspectFit

        // Labels
        loginLabel.text = "Логин или Email"
        loginLabel.textColor = UIColor(red: 144/255.0, green: 164/255.0, blue: 174/255.0, alpha: 1.0)
        loginLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)

        passwordLabel.text = "Пароль"
        passwordLabel.textColor = UIColor(red: 144/255.0, green: 164/255.0, blue: 174/255.0, alpha: 1.0)
        passwordLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)

        // TextFields
        configureTextField(loginTF, placeholder: "Введите логин или email", isSecure: false)
        loginTF.returnKeyType = .next
        loginTF.autocapitalizationType = .none
        loginTF.autocorrectionType = .no
        loginTF.keyboardType = .emailAddress
        loginTF.addTarget(self, action: #selector(textDidChange(_:)), for: .editingChanged)

        configurePasswordToggleButton()
        configureTextField(passwordTF, placeholder: "Введите пароль", isSecure: true)
        passwordTF.returnKeyType = .done
        passwordTF.autocapitalizationType = .none
        passwordTF.autocorrectionType = .no
        setPasswordRightView(passwordToggleButton, for: passwordTF)
        passwordTF.addTarget(self, action: #selector(textDidChange(_:)), for: .editingChanged)

        // Error label
        errorLabel.text = "Неверный логин или пароль."
        errorLabel.font = .systemFont(ofSize: 12)
        errorLabel.textColor = .red
        errorLabel.isHidden = true

        // Buttons
        forgotPasswordButton.setTitle("Забыли пароль?", for: .normal)
        forgotPasswordButton.contentHorizontalAlignment = .left
        forgotPasswordButton.addTarget(self, action: #selector(forgotPasswordButtonTapped), for: .touchUpInside)

        loginButton.setTitle("Войти в систему", for: .normal)
        loginButton.backgroundColor = .systemBlue
        loginButton.setTitleColor(.white, for: .normal)
        loginButton.layer.cornerRadius = 10
        loginButton.addTarget(self, action: #selector(loginButtonTapped), for: .touchUpInside)

        registrationLabel.text = "Нет аккаунта в системе?"
        registrationLabel.textColor = UIColor(red: 84/255.0, green: 110/255.0, blue: 122/255.0, alpha: 1.0)
        registrationLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)

        registrButton.setTitle("Регистрация", for: .normal)
        registrButton.backgroundColor = UIColor(red: 0/255, green: 122/255, blue: 255/255, alpha: 0.15)
        registrButton.setTitleColor(UIColor(red: 0/255, green: 101/255, blue: 255/255, alpha: 1), for: .normal)
        registrButton.layer.cornerRadius = 10
        registrButton.addTarget(self, action: #selector(registrButtonTapped), for: .touchUpInside)

        // Add subviews
        [logoImageView, loginLabel, loginTF, passwordLabel, passwordTF, errorLabel, forgotPasswordButton, loginButton, registrationLabel, registrButton].forEach {
            contentView.addSubview($0)
        }

        setupConstraints()
        setupLoadingOverlay()
    }

    private func setupConstraints() {
        logoImageView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalToSuperview().offset(40)
            $0.width.equalToSuperview().multipliedBy(0.6).priority(.high)
            $0.width.lessThanOrEqualTo(260)
            $0.height.equalTo(logoImageView.snp.width)
        }

        loginLabel.snp.makeConstraints {
            $0.top.equalTo(logoImageView.snp.bottom).offset(40)
            $0.leading.equalToSuperview().offset(16)
        }

        loginTF.snp.makeConstraints {
            $0.top.equalTo(loginLabel.snp.bottom).offset(4)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(50)
        }

        passwordLabel.snp.makeConstraints {
            $0.top.equalTo(loginTF.snp.bottom).offset(16)
            $0.leading.equalTo(loginLabel)
        }

        passwordTF.snp.makeConstraints {
            $0.top.equalTo(passwordLabel.snp.bottom).offset(4)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(50)
        }

        errorLabel.snp.makeConstraints {
            $0.top.equalTo(passwordTF.snp.bottom).offset(4)
            $0.leading.trailing.equalToSuperview().inset(16)
        }

        forgotPasswordButton.snp.makeConstraints {
            $0.top.equalTo(errorLabel.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(22)
        }

        loginButton.snp.makeConstraints {
            $0.top.equalTo(forgotPasswordButton.snp.bottom).offset(24)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(50)
        }

        registrationLabel.snp.makeConstraints {
            $0.top.equalTo(loginButton.snp.bottom).offset(28)
            $0.centerX.equalToSuperview()
        }

        registrButton.snp.makeConstraints {
            $0.top.equalTo(registrationLabel.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(50)
            $0.bottom.equalToSuperview().inset(24)
        }
    }

    private func configureTextField(_ tf: UITextField, placeholder: String, isSecure: Bool) {
        tf.placeholder = placeholder
        tf.font = UIFont.systemFont(ofSize: 15)
        tf.backgroundColor = .clear
        tf.layer.cornerRadius = 10
        tf.layer.borderWidth = 1
        tf.layer.borderColor = UIColor(red: 207/255.0, green: 216/255.0, blue: 220/255.0, alpha: 1.0).cgColor
        tf.isSecureTextEntry = isSecure

        let leftPadding = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 50))
        tf.leftView = leftPadding
        tf.leftViewMode = .always
    }

    private func configurePasswordToggleButton() {
        passwordToggleButton.setImage(UIImage(systemName: "eye.slash"), for: .normal)
        passwordToggleButton.tintColor = UIColor(red: 144/255.0, green: 164/255.0, blue: 174/255.0, alpha: 1.0)
        passwordToggleButton.addTarget(self, action: #selector(togglePasswordVisibility), for: .touchUpInside)
    }

    private func setPasswordRightView(_ button: UIButton, for textField: UITextField) {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 48, height: 40))
        button.frame = CGRect(x: 0, y: 0, width: 36, height: 40)
        container.addSubview(button)
        textField.rightView = container
        textField.rightViewMode = .always
    }

    private func setupLoadingOverlay() {
        loadingOverlay.isHidden = true
        loadingOverlay.backgroundColor = UIColor.black.withAlphaComponent(0.18)

        activityIndicator.hidesWhenStopped = true
        activityIndicator.color = .white

        view.addSubview(loadingOverlay)
        loadingOverlay.addSubview(activityIndicator)

        loadingOverlay.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        activityIndicator.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
    }

    @MainActor
    private func setLoading(_ isLoading: Bool) {
        loadingOverlay.isHidden = !isLoading
        if isLoading {
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
        }

        view.isUserInteractionEnabled = !isLoading
        loginButton.isEnabled = !isLoading
        registrButton.isEnabled = !isLoading
        forgotPasswordButton.isEnabled = !isLoading
    }

    // MARK: - Actions
    @objc private func textDidChange(_ sender: UITextField) {
        resetAuthorizationError()
    }

    @objc private func forgotPasswordButtonTapped() {
        let vc = ForgotViewController()
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func registrButtonTapped() {
        let vc = RegistrationViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc private func loginButtonTapped() {
        let login = (loginTF.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let password = (passwordTF.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

        guard !login.isEmpty, !password.isEmpty else {
            showAuthorizationError()
            return
        }

        Task {
            await setLoading(true)
            defer { Task { @MainActor in await self.setLoading(false) } }

            do {
                print("LOGIN TAP: start")

                try await AuthService.shared.login(login: login, password: password)
                print("LOGIN: success, token =", AuthService.shared.currentToken() ?? "nil")

                let user = try await AuthService.shared.fetchMe()
                print("FETCH ME: success, user id =", user.id)

                await MainActor.run {
                    self.openMainTabBar(user: user)
                }

            } catch {
                print("LOGIN ERROR:", error)
                await MainActor.run {
                    self.showAuthorizationError()
                }
            }
        }
    }

    private func openMainTabBar(user: UserDTO) {
        let tabBarVC = MainTabBarController(user: user)

        guard
            let windowScene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive }),
            let window = windowScene.windows.first(where: { $0.isKeyWindow }) ?? windowScene.windows.first
        else { return }

        UIView.transition(with: window,
                          duration: 0.3,
                          options: [.transitionFlipFromRight, .showHideTransitionViews],
                          animations: {
            window.rootViewController = tabBarVC
            window.makeKeyAndVisible()
        })
    }

    // MARK: - Error UI
    private func resetAuthorizationError() {
        loginTF.layer.borderColor = UIColor(red: 207/255.0, green: 216/255.0, blue: 220/255.0, alpha: 1.0).cgColor
        passwordTF.layer.borderColor = UIColor(red: 207/255.0, green: 216/255.0, blue: 220/255.0, alpha: 1.0).cgColor
        errorLabel.isHidden = true
    }

    private func showAuthorizationError() {
        loginTF.layer.borderColor = UIColor.red.cgColor
        passwordTF.layer.borderColor = UIColor.red.cgColor
        errorLabel.isHidden = false
    }

    // MARK: - Password toggle
    @objc private func togglePasswordVisibility() {
        passwordTF.isSecureTextEntry.toggle()
        let imageName = passwordTF.isSecureTextEntry ? "eye.slash" : "eye"
        passwordToggleButton.setImage(UIImage(systemName: imageName), for: .normal)
    }

    // MARK: - Keyboard
    //дает возможность что-то изменить при появлении/скрытии клавиатуры
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow),
                                               name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide),
                                               name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc private func keyboardWillShow(notification: NSNotification) {
        updateKeyboardInset(notification: notification)
    }

    @objc private func keyboardWillHide(notification: NSNotification) {
        let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval ?? 0.25
        let curveValue = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt ?? 0
        let options = UIView.AnimationOptions(rawValue: curveValue << 16)

        UIView.animate(withDuration: duration, delay: 0, options: options) {
            self.scrollView.contentInset.bottom = 0
            self.scrollView.verticalScrollIndicatorInsets.bottom = 0
        }
    }

    private func updateKeyboardInset(notification: NSNotification) {
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

    private func scrollActiveFieldIntoView() {
        guard let activeTextField else { return }

        let fieldFrame = activeTextField.convert(activeTextField.bounds, to: scrollView)
        scrollView.scrollRectToVisible(fieldFrame.insetBy(dx: 0, dy: -24), animated: true)
    }

    // MARK: - UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == loginTF {
            passwordTF.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
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
