import UIKit

final class CakeDesignerViewController: UIViewController {

    private enum DraftKey {
        static let designID = "customCake.designID"
        static let weightIndex = "customCake.weightIndex"
        static let inscription = "customCake.inscription"
        static let wishes = "customCake.wishes"
    }

    private let designs = CakeDesign.mockDesigns
    private var selectedDesignIndex = 0
    private var preferredWeightIndex = 1
    private var isPreviewGenerated = false
    private var isPreviewOutdated = false
    private var generatedPreviewImage: UIImage?
    private var optionViews: [CakeDesignOptionView] = []

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let introTitleLabel = UILabel()
    private let introSubtitleLabel = UILabel()
    private let previewCard = UIView()
    private let previewImageView = UIImageView()
    private let previewPlaceholderLabel = UILabel()
    private let sectionTitleLabel = UILabel()
    private let designScrollView = UIScrollView()
    private let designStackView = UIStackView()
    private let descriptionTitleLabel = UILabel()
    private let designInfoCard = UIView()
    private let fillingLabel = UILabel()
    private let accentLabel = UILabel()
    private let kcalLabel = UILabel()
    private let priceLabel = UILabel()
    private let weightTitleLabel = UILabel()
    private let weightControl = UISegmentedControl()
    private let inscriptionTitleLabel = UILabel()
    private let inscriptionField = UITextField()
    private let wishesTitleLabel = UILabel()
    private let wishesTextView = UITextView()
    private let wishesPlaceholderLabel = UILabel()
    private let actionsStack = UIStackView()
    private let generateButton = UIButton(type: .system)
    private let refreshPreviewButton = UIButton(type: .system)
    private let orderButton = UIButton(type: .system)

    private var selectedDesign: CakeDesign {
        designs[selectedDesignIndex]
    }

    private var selectedWeightIndex: Int {
        guard weightControl.numberOfSegments > 0 else {
            return min(max(preferredWeightIndex, 0), max(selectedDesign.availableWeights.count - 1, 0))
        }
        let maxIndex = max(selectedDesign.availableWeights.count - 1, 0)
        return min(weightControl.selectedSegmentIndex >= 0 ? weightControl.selectedSegmentIndex : 0, maxIndex)
    }

    private var selectedWeight: CakeWeightOption {
        selectedDesign.availableWeights[selectedWeightIndex]
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Торты"
        view.backgroundColor = .systemGroupedBackground
        setupHierarchy()
        setupStyle()
        restoreDraftIfNeeded()
        reloadWeightControl()
        refreshUI(animated: false)
        setupKeyboardDismiss()
    }

    private func setupHierarchy() {
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        scrollView.addSubview(contentStack)
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.axis = .vertical
        contentStack.spacing = 16
        contentStack.layoutMargins = UIEdgeInsets(top: 20, left: 16, bottom: 24, right: 16)
        contentStack.isLayoutMarginsRelativeArrangement = true

        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])

        introTitleLabel.text = "Соберите свой торт"
        introSubtitleLabel.text = "Сначала выберите дизайн и параметры, затем сгенерируйте фотографию торта и оформите заказ."

        contentStack.addArrangedSubview(makeTextSection(title: introTitleLabel, subtitle: introSubtitleLabel))

        sectionTitleLabel.text = "Выбор дизайна"
        sectionTitleLabel.font = .systemFont(ofSize: 20, weight: .bold)
        contentStack.addArrangedSubview(sectionTitleLabel)

        setupDesignSelector()
        contentStack.addArrangedSubview(designScrollView)

        descriptionTitleLabel.text = "Описание"
        descriptionTitleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        contentStack.addArrangedSubview(descriptionTitleLabel)

        setupDesignInfoCard()
        contentStack.addArrangedSubview(designInfoCard)
        contentStack.setCustomSpacing(8, after: descriptionTitleLabel)

        weightTitleLabel.text = "Вес"
        weightTitleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        contentStack.addArrangedSubview(weightTitleLabel)
        contentStack.addArrangedSubview(weightControl)

        setupInputFields()
        contentStack.addArrangedSubview(inscriptionTitleLabel)
        contentStack.addArrangedSubview(inscriptionField)
        contentStack.addArrangedSubview(wishesTitleLabel)
        contentStack.addArrangedSubview(wishesTextViewContainer())

        setupPreviewCard()
        contentStack.addArrangedSubview(previewCard)

        setupActions()
        contentStack.addArrangedSubview(actionsStack)
    }

    private func setupStyle() {
        introTitleLabel.font = .systemFont(ofSize: 30, weight: .bold)
        introTitleLabel.numberOfLines = 0

        introSubtitleLabel.font = .systemFont(ofSize: 15, weight: .regular)
        introSubtitleLabel.textColor = .secondaryLabel
        introSubtitleLabel.numberOfLines = 0

        weightControl.addTarget(self, action: #selector(weightChanged), for: .valueChanged)
        inscriptionField.addTarget(self, action: #selector(textDidChange), for: .editingChanged)
        wishesTextView.delegate = self
        generateButton.addTarget(self, action: #selector(generateTapped), for: .touchUpInside)
        refreshPreviewButton.addTarget(self, action: #selector(generateTapped), for: .touchUpInside)
    }

    private func makeTextSection(title: UILabel, subtitle: UILabel) -> UIStackView {
        let stack = UIStackView(arrangedSubviews: [title, subtitle])
        stack.axis = .vertical
        stack.spacing = 6
        return stack
    }

    private func setupPreviewCard() {
        previewCard.translatesAutoresizingMaskIntoConstraints = false
        previewCard.backgroundColor = .clear
        previewCard.layer.cornerRadius = 24
        previewCard.layer.cornerCurve = .continuous

        previewImageView.contentMode = .scaleAspectFill
        previewImageView.clipsToBounds = true
        previewImageView.layer.cornerRadius = 24
        previewImageView.layer.cornerCurve = .continuous
        previewImageView.backgroundColor = .white
        previewImageView.layer.borderWidth = 1
        previewImageView.layer.borderColor = UIColor.systemGray5.cgColor

        previewPlaceholderLabel.text = "Здесь появится фотография торта"
        previewPlaceholderLabel.font = .systemFont(ofSize: 16, weight: .medium)
        previewPlaceholderLabel.textColor = .secondaryLabel
        previewPlaceholderLabel.numberOfLines = 2
        previewPlaceholderLabel.textAlignment = .center

        configureButton(generateButton, title: "Сгенерировать фотографию торта", backgroundColor: .systemPink)

        var refreshConfiguration = UIButton.Configuration.filled()
        refreshConfiguration.image = UIImage(systemName: "arrow.clockwise")
        refreshConfiguration.cornerStyle = .capsule
        refreshConfiguration.baseBackgroundColor = .systemPink
        refreshConfiguration.baseForegroundColor = .white
        refreshConfiguration.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12)
        refreshPreviewButton.configuration = refreshConfiguration
        refreshPreviewButton.layer.shadowColor = UIColor.black.withAlphaComponent(0.18).cgColor
        refreshPreviewButton.layer.shadowOpacity = 1
        refreshPreviewButton.layer.shadowRadius = 10
        refreshPreviewButton.layer.shadowOffset = CGSize(width: 0, height: 4)

        previewCard.addSubview(previewImageView)
        previewCard.addSubview(previewPlaceholderLabel)
        previewCard.addSubview(generateButton)
        previewCard.addSubview(refreshPreviewButton)

        previewImageView.translatesAutoresizingMaskIntoConstraints = false
        previewPlaceholderLabel.translatesAutoresizingMaskIntoConstraints = false
        generateButton.translatesAutoresizingMaskIntoConstraints = false
        refreshPreviewButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            previewImageView.topAnchor.constraint(equalTo: previewCard.topAnchor),
            previewImageView.leadingAnchor.constraint(equalTo: previewCard.leadingAnchor),
            previewImageView.trailingAnchor.constraint(equalTo: previewCard.trailingAnchor),
            previewImageView.bottomAnchor.constraint(equalTo: previewCard.bottomAnchor),
            previewCard.heightAnchor.constraint(equalToConstant: 240),

            previewPlaceholderLabel.centerXAnchor.constraint(equalTo: previewCard.centerXAnchor),
            previewPlaceholderLabel.centerYAnchor.constraint(equalTo: previewCard.centerYAnchor, constant: -28),
            previewPlaceholderLabel.leadingAnchor.constraint(greaterThanOrEqualTo: previewCard.leadingAnchor, constant: 24),
            previewPlaceholderLabel.trailingAnchor.constraint(lessThanOrEqualTo: previewCard.trailingAnchor, constant: -24),

            generateButton.centerXAnchor.constraint(equalTo: previewCard.centerXAnchor),
            generateButton.topAnchor.constraint(equalTo: previewPlaceholderLabel.bottomAnchor, constant: 16),
            generateButton.leadingAnchor.constraint(greaterThanOrEqualTo: previewCard.leadingAnchor, constant: 20),
            generateButton.trailingAnchor.constraint(lessThanOrEqualTo: previewCard.trailingAnchor, constant: -20),

            refreshPreviewButton.topAnchor.constraint(equalTo: previewCard.topAnchor, constant: 14),
            refreshPreviewButton.trailingAnchor.constraint(equalTo: previewCard.trailingAnchor, constant: -14),
            refreshPreviewButton.widthAnchor.constraint(equalToConstant: 46),
            refreshPreviewButton.heightAnchor.constraint(equalToConstant: 46)
        ])
    }

    private func setupDesignSelector() {
        designScrollView.showsHorizontalScrollIndicator = false
        designStackView.axis = .horizontal
        designStackView.spacing = 12

        designScrollView.addSubview(designStackView)
        designStackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            designStackView.topAnchor.constraint(equalTo: designScrollView.contentLayoutGuide.topAnchor),
            designStackView.leadingAnchor.constraint(equalTo: designScrollView.contentLayoutGuide.leadingAnchor, constant: 16),
            designStackView.trailingAnchor.constraint(equalTo: designScrollView.contentLayoutGuide.trailingAnchor, constant: -16),
            designStackView.bottomAnchor.constraint(equalTo: designScrollView.contentLayoutGuide.bottomAnchor),
            designStackView.heightAnchor.constraint(equalTo: designScrollView.frameLayoutGuide.heightAnchor),
            designScrollView.heightAnchor.constraint(equalToConstant: 210)
        ])

        for (index, design) in designs.enumerated() {
            let optionView = CakeDesignOptionView(design: design)
            optionView.tag = index
            optionView.addTarget(self, action: #selector(designTapped(_:)), for: .touchUpInside)
            optionViews.append(optionView)
            designStackView.addArrangedSubview(optionView)
            optionView.widthAnchor.constraint(equalToConstant: 220).isActive = true
        }
    }

    private func setupDesignInfoCard() {
        designInfoCard.backgroundColor = .secondarySystemBackground
        designInfoCard.layer.cornerRadius = 18
        designInfoCard.layer.cornerCurve = .continuous

        fillingLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        fillingLabel.numberOfLines = 2

        accentLabel.font = .systemFont(ofSize: 14, weight: .regular)
        accentLabel.textColor = .secondaryLabel
        accentLabel.numberOfLines = 2

        kcalLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        kcalLabel.numberOfLines = 2

        priceLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        priceLabel.numberOfLines = 2

        let stack = UIStackView(arrangedSubviews: [fillingLabel, accentLabel, kcalLabel, priceLabel])
        stack.axis = .vertical
        stack.spacing = 6

        designInfoCard.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: designInfoCard.topAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: designInfoCard.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: designInfoCard.trailingAnchor, constant: -12),
            stack.bottomAnchor.constraint(equalTo: designInfoCard.bottomAnchor, constant: -12)
        ])
    }

    private func setupInputFields() {
        inscriptionTitleLabel.text = "Надпись на торте"
        inscriptionTitleLabel.font = .systemFont(ofSize: 18, weight: .semibold)

        inscriptionField.borderStyle = .roundedRect
        inscriptionField.placeholder = "Введите надпись"
        inscriptionField.font = .systemFont(ofSize: 16, weight: .medium)
        inscriptionField.returnKeyType = .done

        wishesTitleLabel.text = "Дополнительные пожелания"
        wishesTitleLabel.font = .systemFont(ofSize: 18, weight: .semibold)

        wishesTextView.font = .systemFont(ofSize: 16)
        wishesTextView.backgroundColor = .white
        wishesTextView.layer.cornerRadius = 16
        wishesTextView.layer.cornerCurve = .continuous
        wishesTextView.textContainerInset = UIEdgeInsets(top: 14, left: 12, bottom: 14, right: 12)

        wishesPlaceholderLabel.text = "Опишите цвет, ягоды, фигурки, упаковку, аллергии или любые другие детали"
        wishesPlaceholderLabel.font = .systemFont(ofSize: 15)
        wishesPlaceholderLabel.textColor = .placeholderText
        wishesPlaceholderLabel.numberOfLines = 0
    }

    private func wishesTextViewContainer() -> UIView {
        let container = UIView()
        container.addSubview(wishesTextView)
        wishesTextView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            wishesTextView.topAnchor.constraint(equalTo: container.topAnchor),
            wishesTextView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            wishesTextView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            wishesTextView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            wishesTextView.heightAnchor.constraint(equalToConstant: 140)
        ])

        wishesTextView.addSubview(wishesPlaceholderLabel)
        wishesPlaceholderLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            wishesPlaceholderLabel.topAnchor.constraint(equalTo: wishesTextView.topAnchor, constant: 14),
            wishesPlaceholderLabel.leadingAnchor.constraint(equalTo: wishesTextView.leadingAnchor, constant: 17),
            wishesPlaceholderLabel.trailingAnchor.constraint(equalTo: wishesTextView.trailingAnchor, constant: -17)
        ])
        return container
    }

    private func setupActions() {
        actionsStack.axis = .vertical
        actionsStack.spacing = 12

        configureButton(orderButton, title: "Заказать", backgroundColor: .systemBlue)

        orderButton.addTarget(self, action: #selector(orderTapped), for: .touchUpInside)

        actionsStack.addArrangedSubview(orderButton)
    }

    private func configureButton(_ button: UIButton, title: String, backgroundColor: UIColor) {
        var configuration = UIButton.Configuration.filled()
        configuration.title = title
        configuration.cornerStyle = .large
        configuration.baseBackgroundColor = backgroundColor
        configuration.baseForegroundColor = .white
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 20, bottom: 16, trailing: 20)
        button.configuration = configuration
    }

    private func reloadWeightControl() {
        weightControl.removeAllSegments()
        for (index, option) in selectedDesign.availableWeights.enumerated() {
            weightControl.insertSegment(withTitle: option.title, at: index, animated: false)
        }

        let restoredIndex = min(max(preferredWeightIndex, 0), selectedDesign.availableWeights.count - 1)
        weightControl.selectedSegmentIndex = restoredIndex >= 0 ? restoredIndex : 0
        preferredWeightIndex = weightControl.selectedSegmentIndex
    }

    private func refreshUI(animated: Bool) {
        for (index, optionView) in optionViews.enumerated() {
            optionView.setSelected(index == selectedDesignIndex, animated: animated)
        }

        fillingLabel.text = "Начинка: \(selectedDesign.filling)"
        accentLabel.text = selectedDesign.accent
        kcalLabel.text = "Калорийность: \(selectedDesign.kcalPer100g) ккал / 100 г"
        priceLabel.text = "Цена: \(selectedDesign.price(for: selectedWeight.grams)) ₽"

        updatePreviewImage(animated: animated)
        updateWishesPlaceholder()
        updateOrderButtonState()
        updatePreviewControls()
    }

    private func updatePreviewImage(animated: Bool) {
        guard isPreviewGenerated else {
            previewImageView.image = nil
            previewImageView.backgroundColor = .white
            return
        }

        previewImageView.backgroundColor = .clear
        previewImageView.image = generatedPreviewImage

        guard animated else { return }
        UIView.animate(withDuration: 0.18, animations: {
            self.previewCard.transform = CGAffineTransform(scaleX: 0.98, y: 0.98)
        }, completion: { _ in
            UIView.animate(withDuration: 0.18) {
                self.previewCard.transform = .identity
            }
        })
    }

    private func updatePreviewControls() {
        previewPlaceholderLabel.isHidden = isPreviewGenerated
        generateButton.isHidden = isPreviewGenerated
        refreshPreviewButton.isHidden = !(isPreviewGenerated && isPreviewOutdated)
        previewImageView.alpha = isPreviewGenerated ? 1 : 0.96
    }

    private func makeCurrentPreviewImage() -> UIImage? {
        let baseImage = UIImage(named: selectedDesign.imageName)
        let inscription = trimmed(inscriptionField.text)
        let wishes = trimmed(wishesTextView.text)

        if inscription.isEmpty && wishes.isEmpty {
            return baseImage
        }

        return renderPreviewImage(baseImage: baseImage, inscription: inscription, wishes: wishes)
    }

    private func renderPreviewImage(baseImage: UIImage?, inscription: String, wishes: String) -> UIImage? {
        let size = CGSize(width: 1200, height: 720)
        let renderer = UIGraphicsImageRenderer(size: size)
        let badgeFont = UIFont.systemFont(ofSize: 34, weight: .semibold)
        let inscriptionFont = UIFont.systemFont(ofSize: 58, weight: .bold)
        let wishesFont = UIFont.systemFont(ofSize: 32, weight: .medium)

        return renderer.image { context in
            let rect = CGRect(origin: .zero, size: size)

            if let baseImage {
                baseImage.draw(in: rect)
            } else {
                UIColor.systemGray5.setFill()
                context.fill(rect)
            }

            UIColor.black.withAlphaComponent(0.34).setFill()
            context.fill(rect)

            let badgeText = "Ваш выбор"
            let badgeAttributes: [NSAttributedString.Key: Any] = [
                .font: badgeFont,
                .foregroundColor: UIColor.white
            ]
            badgeText.draw(at: CGPoint(x: 48, y: 48), withAttributes: badgeAttributes)

            let inscriptionText = inscription.isEmpty ? "Без надписи" : inscription
            let inscriptionRect = CGRect(x: 48, y: 230, width: size.width - 96, height: 180)
            let inscriptionAttributes: [NSAttributedString.Key: Any] = [
                .font: inscriptionFont,
                .foregroundColor: UIColor.white
            ]
            inscriptionText.draw(in: inscriptionRect, withAttributes: inscriptionAttributes)

            let footerText = wishes.isEmpty ? selectedWeight.title : "\(selectedWeight.title) • \(wishes)"
            let footerRect = CGRect(x: 48, y: size.height - 150, width: size.width - 96, height: 96)
            let footerAttributes: [NSAttributedString.Key: Any] = [
                .font: wishesFont,
                .foregroundColor: UIColor.white.withAlphaComponent(0.92)
            ]
            footerText.draw(in: footerRect, withAttributes: footerAttributes)
        }
    }

    private func buildPreviewText() -> String {
        let inscription = trimmed(inscriptionField.text)
        let wishes = trimmed(wishesTextView.text)
        let inscriptionText = inscription.isEmpty ? "Надпись не указана" : "Надпись: \(inscription)"
        let wishesText = wishes.isEmpty ? "Пожелания не указаны" : "Пожелания: \(wishes)"

        return "\(selectedWeight.title)\n\(inscriptionText)\n\(wishesText)"
    }

    private func buildSummary() -> String {
        let inscription = trimmed(inscriptionField.text)
        let wishes = trimmed(wishesTextView.text)
        let totalCalories = selectedDesign.totalCalories(for: selectedWeight.grams)
        let price = selectedDesign.price(for: selectedWeight.grams)
        let inscriptionLine = inscription.isEmpty ? "Надпись: без текста" : "Надпись: \(inscription)"
        let wishesLine = wishes.isEmpty ? "Пожелания: не указаны" : "Пожелания: \(wishes)"

        return """
        \(selectedDesign.name), \(selectedWeight.title)
        \(inscriptionLine)
        \(wishesLine)
        Начинка: \(selectedDesign.filling)
        Калорийность: ~\(totalCalories) ккал за весь торт
        Стоимость: \(price) ₽
        """
    }

    private func restoreDraftIfNeeded() {
        let defaults = UserDefaults.standard

        if let designID = defaults.string(forKey: DraftKey.designID),
           let index = designs.firstIndex(where: { $0.id == designID }) {
            selectedDesignIndex = index
        }

        inscriptionField.text = defaults.string(forKey: DraftKey.inscription)
        wishesTextView.text = defaults.string(forKey: DraftKey.wishes)

        if let weightIndex = defaults.object(forKey: DraftKey.weightIndex) as? Int {
            preferredWeightIndex = weightIndex
        }
    }

    private func persistDraft() {
        let defaults = UserDefaults.standard
        defaults.set(selectedDesign.id, forKey: DraftKey.designID)
        defaults.set(selectedWeightIndex, forKey: DraftKey.weightIndex)
        defaults.set(trimmed(inscriptionField.text), forKey: DraftKey.inscription)
        defaults.set(trimmed(wishesTextView.text), forKey: DraftKey.wishes)
    }

    private func updateWishesPlaceholder() {
        wishesPlaceholderLabel.isHidden = !trimmed(wishesTextView.text).isEmpty
    }

    private func invalidateGeneratedPreview() {
        guard isPreviewGenerated else { return }
        isPreviewOutdated = true
    }

    private func updateOrderButtonState() {
        orderButton.isEnabled = isPreviewGenerated && !isPreviewOutdated
        var configuration = orderButton.configuration
        configuration?.baseBackgroundColor = (isPreviewGenerated && !isPreviewOutdated) ? .systemBlue : .systemGray3
        configuration?.baseForegroundColor = .white
        orderButton.configuration = configuration
        orderButton.alpha = (isPreviewGenerated && !isPreviewOutdated) ? 1 : 0.85
    }

    private func trimmed(_ text: String?) -> String {
        (text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func setupKeyboardDismiss() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(endEditingTapped))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc private func endEditingTapped() {
        view.endEditing(true)
    }

    @objc private func designTapped(_ sender: UIControl) {
        guard sender.tag != selectedDesignIndex else { return }
        selectedDesignIndex = sender.tag
        reloadWeightControl()
        invalidateGeneratedPreview()
        persistDraft()
        refreshUI(animated: true)
    }

    @objc private func weightChanged() {
        preferredWeightIndex = weightControl.selectedSegmentIndex
        invalidateGeneratedPreview()
        persistDraft()
        refreshUI(animated: false)
    }

    @objc private func textDidChange() {
        invalidateGeneratedPreview()
        persistDraft()
        refreshUI(animated: false)
    }

    @objc private func generateTapped() {
        view.endEditing(true)
        isPreviewGenerated = true
        isPreviewOutdated = false
        generatedPreviewImage = makeCurrentPreviewImage()
        persistDraft()
        refreshUI(animated: true)
    }

    @objc private func orderTapped() {
        view.endEditing(true)
        persistDraft()

        let alert = UIAlertController(
            title: "Заявка на торт",
            message: buildSummary(),
            preferredStyle: .actionSheet
        )
        alert.addAction(UIAlertAction(title: "Отправить заказ", style: .default))
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))

        if let popover = alert.popoverPresentationController {
            popover.sourceView = orderButton
            popover.sourceRect = orderButton.bounds
        }

        present(alert, animated: true)
    }
}

extension CakeDesignerViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        invalidateGeneratedPreview()
        persistDraft()
        refreshUI(animated: false)
    }
}

private final class CakeDesignOptionView: UIControl {
    private let cardView = UIView()
    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let statsLabel = UILabel()

    init(design: CakeDesign) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        cardView.backgroundColor = .secondarySystemBackground
        cardView.layer.cornerRadius = 20
        cardView.layer.cornerCurve = .continuous
        cardView.layer.borderWidth = 1
        cardView.layer.borderColor = UIColor.systemGray4.cgColor
        cardView.isUserInteractionEnabled = false

        imageView.image = UIImage(named: design.imageName)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 16
        imageView.layer.cornerCurve = .continuous

        titleLabel.text = design.name
        titleLabel.font = .systemFont(ofSize: 18, weight: .bold)
        titleLabel.numberOfLines = 2

        subtitleLabel.text = design.subtitle
        subtitleLabel.font = .systemFont(ofSize: 14, weight: .regular)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 3

        if let smallestWeight = design.availableWeights.first {
            statsLabel.text = "\(smallestWeight.title) • от \(design.price(for: smallestWeight.grams)) ₽ • \(design.kcalPer100g) ккал/100 г"
        } else {
            statsLabel.text = "\(design.kcalPer100g) ккал/100 г"
        }
        statsLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        statsLabel.textColor = .systemOrange
        statsLabel.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [imageView, titleLabel, subtitleLabel, statsLabel])
        stack.axis = .vertical
        stack.spacing = 10

        addSubview(cardView)
        cardView.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: topAnchor),
            cardView.leadingAnchor.constraint(equalTo: leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: trailingAnchor),
            cardView.bottomAnchor.constraint(equalTo: bottomAnchor),
            stack.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -12),
            stack.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -12),
            imageView.heightAnchor.constraint(equalToConstant: 110)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setSelected(_ selected: Bool, animated: Bool) {
        let updates = {
            self.cardView.layer.borderColor = (selected ? UIColor.systemPink : UIColor.systemGray4).cgColor
            self.cardView.layer.borderWidth = selected ? 2 : 1
            self.cardView.backgroundColor = selected ? UIColor.systemPink.withAlphaComponent(0.12) : .secondarySystemBackground
            self.cardView.layer.shadowColor = selected ? UIColor.systemPink.withAlphaComponent(0.22).cgColor : UIColor.clear.cgColor
            self.cardView.layer.shadowOpacity = selected ? 1 : 0
            self.cardView.layer.shadowRadius = selected ? 10 : 0
            self.cardView.layer.shadowOffset = .zero
        }

        if animated {
            UIView.animate(withDuration: 0.2, animations: updates)
        } else {
            updates()
        }
    }
}
