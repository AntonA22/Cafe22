import UIKit
import Vision

final class CakeDesignerViewController: UIViewController {

    private enum DraftKey {
        static let designID = "customCake.designID"
        static let weightIndex = "customCake.weightIndex"
        static let inscription = "customCake.inscription"
        static let wishes = "customCake.wishes"
    }

    private var designs = CakeDesign.mockDesigns
    private var selectedDesignIndex = 0
    private var preferredWeightIndex = 1
    private var isPreviewGenerated = false
    private var isPreviewOutdated = false
    private var isGeneratingPreview = false
    private var generatedPreviewImage: UIImage?
    private var generationTask: Task<Void, Never>?
    private var designsTask: Task<Void, Never>?
    private var previewImageTask: URLSessionDataTask?
    private var selectedPreviewBaseImage: UIImage?
    private var selectedPreviewDesignID: String?
    private weak var activeInputView: UIView?
    private var optionViews: [CakeDesignOptionView] = []
    private let imageEditService = GeminiImageEditService.shared

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let introTitleLabel = UILabel()
    private let introSubtitleLabel = UILabel()
    private let previewCard = UIView()
    private let previewImageView = UIImageView()
    private let previewPlaceholderLabel = UILabel()
    private let previewLoadingIndicator = UIActivityIndicatorView(style: .large)
    private let sectionTitleLabel = UILabel()
    private let designScrollView = UIScrollView()
    private let designStackView = UIStackView()
    private let galleryTitleLabel = UILabel()
    private let galleryCard = DessertGalleryView()
    private let descriptionTitleLabel = UILabel()
    private let designInfoCard = UIView()
    private let fillingLabel = UILabel()
    private let accentLabel = UILabel()
    private let compositionLabel = UILabel()
    private let storageLabel = UILabel()
    private let recommendationLabel = UILabel()
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
        guard designs.indices.contains(selectedDesignIndex) else {
            return CakeDesign.mockDesigns[0]
        }
        return designs[selectedDesignIndex]
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
        useRussianBackButtonTitle()
        navigationItem.title = "Торты с надписью"
        view.backgroundColor = .systemGroupedBackground
        setupHierarchy()
        setupStyle()
        restoreDraftIfNeeded()
        reloadWeightControl()
        refreshUI(animated: false)
        loadDesignsFromBackend()
        setupKeyboardDismiss()
        setupKeyboardObservers()
    }

    deinit {
        generationTask?.cancel()
        designsTask?.cancel()
        previewImageTask?.cancel()
        NotificationCenter.default.removeObserver(self)
    }

    private func setupHierarchy() {
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
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

        introTitleLabel.text = "Торт с вашей надписью"
        introSubtitleLabel.text = "Выберите готовый дизайн, напишите фразу и получите аккуратное превью перед оформлением."

        contentStack.addArrangedSubview(makeTextSection(title: introTitleLabel, subtitle: introSubtitleLabel))

        setupPreviewCard()

        sectionTitleLabel.text = "Дизайн"
        sectionTitleLabel.font = .systemFont(ofSize: 20, weight: .bold)
        contentStack.addArrangedSubview(sectionTitleLabel)

        setupDesignSelector()
        contentStack.addArrangedSubview(designScrollView)

        galleryTitleLabel.text = "Фотографии"
        galleryTitleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        contentStack.addArrangedSubview(galleryTitleLabel)
        contentStack.addArrangedSubview(galleryCard)
        galleryCard.onItemTap = { [weak self] index in
            self?.showDessertGallery(startIndex: index)
        }
        contentStack.setCustomSpacing(8, after: galleryTitleLabel)

        descriptionTitleLabel.text = "Детали"
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
        inscriptionField.delegate = self
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
        previewCard.backgroundColor = .secondarySystemGroupedBackground
        previewCard.layer.cornerRadius = 22
        previewCard.layer.cornerCurve = .continuous
        previewCard.layer.shadowColor = UIColor.black.withAlphaComponent(0.12).cgColor
        previewCard.layer.shadowOpacity = 1
        previewCard.layer.shadowRadius = 18
        previewCard.layer.shadowOffset = CGSize(width: 0, height: 8)

        previewImageView.contentMode = .scaleAspectFill
        previewImageView.clipsToBounds = true
        previewImageView.layer.cornerRadius = 22
        previewImageView.layer.cornerCurve = .continuous
        previewImageView.backgroundColor = .secondarySystemBackground
        previewImageView.layer.borderWidth = 1
        previewImageView.layer.borderColor = UIColor.white.withAlphaComponent(0.8).cgColor

        previewPlaceholderLabel.text = "Надпись появится после генерации"
        previewPlaceholderLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        previewPlaceholderLabel.textColor = .white
        previewPlaceholderLabel.backgroundColor = UIColor.black.withAlphaComponent(0.34)
        previewPlaceholderLabel.layer.cornerRadius = 14
        previewPlaceholderLabel.clipsToBounds = true
        previewPlaceholderLabel.numberOfLines = 1
        previewPlaceholderLabel.textAlignment = .center
        previewLoadingIndicator.hidesWhenStopped = true

        configureButton(generateButton, title: "Сгенерировать надпись", backgroundColor: .systemBlue)

        var refreshConfiguration = UIButton.Configuration.filled()
        refreshConfiguration.image = UIImage(systemName: "arrow.clockwise")
        refreshConfiguration.cornerStyle = .capsule
        refreshConfiguration.baseBackgroundColor = .systemBlue
        refreshConfiguration.baseForegroundColor = .white
        refreshConfiguration.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12)
        refreshPreviewButton.configuration = refreshConfiguration
        refreshPreviewButton.layer.shadowColor = UIColor.black.withAlphaComponent(0.18).cgColor
        refreshPreviewButton.layer.shadowOpacity = 1
        refreshPreviewButton.layer.shadowRadius = 10
        refreshPreviewButton.layer.shadowOffset = CGSize(width: 0, height: 4)

        previewCard.addSubview(previewImageView)
        previewCard.addSubview(previewPlaceholderLabel)
        previewCard.addSubview(previewLoadingIndicator)
        previewCard.addSubview(generateButton)
        previewCard.addSubview(refreshPreviewButton)

        previewImageView.translatesAutoresizingMaskIntoConstraints = false
        previewPlaceholderLabel.translatesAutoresizingMaskIntoConstraints = false
        previewLoadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        generateButton.translatesAutoresizingMaskIntoConstraints = false
        refreshPreviewButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            previewImageView.topAnchor.constraint(equalTo: previewCard.topAnchor),
            previewImageView.leadingAnchor.constraint(equalTo: previewCard.leadingAnchor),
            previewImageView.trailingAnchor.constraint(equalTo: previewCard.trailingAnchor),
            previewImageView.bottomAnchor.constraint(equalTo: previewCard.bottomAnchor),
            previewCard.heightAnchor.constraint(equalToConstant: 310),

            previewPlaceholderLabel.centerXAnchor.constraint(equalTo: previewCard.centerXAnchor),
            previewPlaceholderLabel.topAnchor.constraint(equalTo: previewCard.topAnchor, constant: 16),
            previewPlaceholderLabel.leadingAnchor.constraint(greaterThanOrEqualTo: previewCard.leadingAnchor, constant: 18),
            previewPlaceholderLabel.trailingAnchor.constraint(lessThanOrEqualTo: previewCard.trailingAnchor, constant: -18),
            previewPlaceholderLabel.heightAnchor.constraint(equalToConstant: 34),

            previewLoadingIndicator.centerXAnchor.constraint(equalTo: previewCard.centerXAnchor),
            previewLoadingIndicator.centerYAnchor.constraint(equalTo: previewCard.centerYAnchor),

            generateButton.centerXAnchor.constraint(equalTo: previewCard.centerXAnchor),
            generateButton.bottomAnchor.constraint(equalTo: previewCard.bottomAnchor, constant: -18),
            generateButton.leadingAnchor.constraint(equalTo: previewCard.leadingAnchor, constant: 18),
            generateButton.trailingAnchor.constraint(equalTo: previewCard.trailingAnchor, constant: -18),

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
            designScrollView.heightAnchor.constraint(equalToConstant: 244)
        ])

        rebuildDesignOptions()
    }

    private func rebuildDesignOptions() {
        for view in designStackView.arrangedSubviews {
            designStackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        optionViews.removeAll()

        for (index, design) in designs.enumerated() {
            let optionView = CakeDesignOptionView(design: design)
            optionView.tag = index
            optionView.addTarget(self, action: #selector(designTapped(_:)), for: .touchUpInside)
            optionViews.append(optionView)
            designStackView.addArrangedSubview(optionView)
            optionView.widthAnchor.constraint(equalToConstant: 214).isActive = true
        }
    }

    private func loadDesignsFromBackend() {
        designsTask?.cancel()
        designsTask = Task { [weak self] in
            do {
                let loadedDesigns: [CakeDesign] = try await APIClient.shared.request(
                    "/cake-designs",
                    method: "GET"
                )
                guard !Task.isCancelled, !loadedDesigns.isEmpty else { return }

                await MainActor.run {
                    self?.applyLoadedDesigns(loadedDesigns)
                }
            } catch {
                print("🎂 Cake designs backend load failed:", error.localizedDescription)
            }
        }
    }

    private func applyLoadedDesigns(_ loadedDesigns: [CakeDesign]) {
        let previousID = selectedDesign.id
        designs = loadedDesigns
        selectedDesignIndex = designs.firstIndex(where: { $0.id == previousID }) ?? 0
        preferredWeightIndex = 0
        resetGeneratedPreview()
        rebuildDesignOptions()
        reloadWeightControl()
        refreshUI(animated: true)
    }

    private func setupDesignInfoCard() {
        designInfoCard.backgroundColor = .secondarySystemGroupedBackground
        designInfoCard.layer.cornerRadius = 18
        designInfoCard.layer.cornerCurve = .continuous

        fillingLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        fillingLabel.numberOfLines = 0

        accentLabel.font = .systemFont(ofSize: 14, weight: .regular)
        accentLabel.textColor = .secondaryLabel
        accentLabel.numberOfLines = 0

        compositionLabel.font = .systemFont(ofSize: 14, weight: .regular)
        compositionLabel.textColor = .secondaryLabel
        compositionLabel.numberOfLines = 0

        storageLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        storageLabel.numberOfLines = 0

        recommendationLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        recommendationLabel.textColor = .systemBlue
        recommendationLabel.numberOfLines = 0

        kcalLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        kcalLabel.numberOfLines = 2

        priceLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        priceLabel.numberOfLines = 2

        let statsStack = UIStackView(arrangedSubviews: [kcalLabel, priceLabel])
        statsStack.axis = .horizontal
        statsStack.distribution = .fillEqually
        statsStack.spacing = 10

        let stack = UIStackView(arrangedSubviews: [fillingLabel, accentLabel, compositionLabel, storageLabel, recommendationLabel, statsStack])
        stack.axis = .vertical
        stack.spacing = 9

        designInfoCard.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: designInfoCard.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: designInfoCard.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: designInfoCard.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: designInfoCard.bottomAnchor, constant: -16)
        ])
    }

    private func setupInputFields() {
        inscriptionTitleLabel.text = "Надпись на торте"
        inscriptionTitleLabel.font = .systemFont(ofSize: 18, weight: .semibold)

        inscriptionField.borderStyle = .none
        inscriptionField.placeholder = "Введите надпись"
        inscriptionField.font = .systemFont(ofSize: 16, weight: .medium)
        inscriptionField.returnKeyType = .done
        inscriptionField.backgroundColor = .secondarySystemGroupedBackground
        inscriptionField.layer.cornerRadius = 16
        inscriptionField.layer.cornerCurve = .continuous
        inscriptionField.layer.borderWidth = 1
        inscriptionField.layer.borderColor = UIColor.systemGray5.cgColor
        inscriptionField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 1))
        inscriptionField.leftViewMode = .always
        inscriptionField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 1))
        inscriptionField.rightViewMode = .always
        inscriptionField.heightAnchor.constraint(equalToConstant: 54).isActive = true

        wishesTitleLabel.text = "Дополнительные пожелания к надписи"
        wishesTitleLabel.font = .systemFont(ofSize: 18, weight: .semibold)

        wishesTextView.font = .systemFont(ofSize: 16)
        wishesTextView.backgroundColor = .secondarySystemGroupedBackground
        wishesTextView.layer.cornerRadius = 16
        wishesTextView.layer.cornerCurve = .continuous
        wishesTextView.layer.borderWidth = 1
        wishesTextView.layer.borderColor = UIColor.systemGray5.cgColor
        wishesTextView.textContainerInset = UIEdgeInsets(top: 14, left: 12, bottom: 14, right: 12)

        wishesPlaceholderLabel.text = "Опишите цвет надписи, стиль, расположение или другие детали текста"
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

        configureButton(orderButton, title: "Сначала сгенерируйте надпись", backgroundColor: .systemGray3)

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

        galleryCard.configure(items: selectedDesign.galleryItems)

        fillingLabel.text = "Начинка: \(selectedDesign.filling)"
        accentLabel.text = "Акцент: \(selectedDesign.accent)"
        compositionLabel.text = "Состав: \(selectedDesign.composition)"
        storageLabel.text = "Хранение: \(selectedDesign.storage)"
        recommendationLabel.text = selectedDesign.recommendedText
        kcalLabel.text = "\(selectedDesign.kcalPer100g) ккал / 100 г"
        priceLabel.text = "\(selectedDesign.price(for: selectedWeight.grams)) ₽"

        updatePreviewImage(animated: animated)
        updateWishesPlaceholder()
        updateOrderButtonState()
        updatePreviewControls()
    }

    private func updatePreviewImage(animated: Bool) {
        previewImageView.backgroundColor = .secondarySystemBackground
        if isPreviewGenerated {
            previewImageView.image = generatedPreviewImage
        } else {
            loadPreviewBaseImage(for: selectedDesign)
        }

        guard animated else { return }
        UIView.animate(withDuration: 0.18, animations: {
            self.previewCard.transform = CGAffineTransform(scaleX: 0.98, y: 0.98)
        }, completion: { _ in
            UIView.animate(withDuration: 0.18) {
                self.previewCard.transform = .identity
            }
        })
    }

    private func showDessertGallery(startIndex: Int) {
        let items = selectedDesign.galleryItems
        guard !items.isEmpty else { return }

        let safeIndex = min(max(startIndex, 0), items.count - 1)
        let viewController = DessertGalleryFullscreenViewController(
            items: items,
            initialIndex: safeIndex,
            dessertName: selectedDesign.name
        )
        viewController.modalPresentationStyle = .fullScreen
        present(viewController, animated: true)
    }

    private func loadPreviewBaseImage(for design: CakeDesign) {
        if selectedPreviewDesignID == design.id, selectedPreviewBaseImage != nil {
            previewImageView.image = selectedPreviewBaseImage
            return
        }

        previewImageTask?.cancel()
        selectedPreviewDesignID = design.id
        selectedPreviewBaseImage = UIImage(named: design.imageName)
        previewImageView.image = selectedPreviewBaseImage

        guard let urlString = design.imageURLString,
              let url = URL(string: urlString) else {
            return
        }

        if let cached = CakeImageCache.shared.image(forKey: urlString) {
            selectedPreviewBaseImage = cached
            previewImageView.image = cached
            return
        }

        previewImageTask = URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let self,
                  let data,
                  let image = UIImage(data: data) else { return }

            CakeImageCache.shared.set(image, forKey: urlString)
            DispatchQueue.main.async {
                guard self.selectedDesign.id == design.id,
                      !self.isPreviewGenerated else { return }
                self.selectedPreviewBaseImage = image
                self.previewImageView.image = image
            }
        }
        previewImageTask?.resume()
    }

    private func updatePreviewControls() {
        previewPlaceholderLabel.isHidden = isPreviewGenerated || isGeneratingPreview
        generateButton.isHidden = isPreviewGenerated || isGeneratingPreview
        refreshPreviewButton.isHidden = isGeneratingPreview || !(isPreviewGenerated && isPreviewOutdated)
        previewImageView.alpha = isGeneratingPreview ? 0.72 : 1

        generateButton.isEnabled = !isGeneratingPreview
        refreshPreviewButton.isEnabled = !isGeneratingPreview

        if isGeneratingPreview {
            previewLoadingIndicator.startAnimating()
        } else {
            previewLoadingIndicator.stopAnimating()
        }
    }

    private func makeCurrentPreviewImage() -> UIImage? {
        let baseImage = selectedPreviewBaseImage ?? previewImageView.image ?? UIImage(named: selectedDesign.imageName)
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
                baseImage.drawAspectFill(in: rect)
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
        Хранение: \(selectedDesign.storage)
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

    private func resetGeneratedPreview() {
        isPreviewGenerated = false
        isPreviewOutdated = false
        generatedPreviewImage = nil
        selectedPreviewBaseImage = nil
        selectedPreviewDesignID = nil
    }

    private func updateOrderButtonState() {
        orderButton.isEnabled = isPreviewGenerated && !isPreviewOutdated && !isGeneratingPreview
        let price = selectedDesign.price(for: selectedWeight.grams)
        var configuration = orderButton.configuration
        configuration?.title = (isPreviewGenerated && !isPreviewOutdated && !isGeneratingPreview)
            ? "В корзину за \(price) ₽"
            : "Сначала сгенерируйте надпись"
        configuration?.baseBackgroundColor = (isPreviewGenerated && !isPreviewOutdated && !isGeneratingPreview) ? .systemBlue : .systemGray3
        configuration?.baseForegroundColor = .white
        orderButton.configuration = configuration
        orderButton.alpha = (isPreviewGenerated && !isPreviewOutdated && !isGeneratingPreview) ? 1 : 0.85
    }

    private func trimmed(_ text: String?) -> String {
        (text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func presentGenerationError(_ error: Error) {
        let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        let alert = UIAlertController(
            title: "Не удалось сгенерировать фото",
            message: "\(message)\n\nПоказан локальный превью-вариант.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Ок", style: .default))
        present(alert, animated: true)
    }

    private func presentCartError(_ error: Error) {
        let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        let alert = UIAlertController(title: "Не удалось добавить в корзину", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ок", style: .default))
        present(alert, animated: true)
    }

    private func setupKeyboardDismiss() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(endEditingTapped))
        tap.cancelsTouchesInView = false
        tap.delegate = self
        view.addGestureRecognizer(tap)
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

        let keyboardFrame = view.convert(keyboardValue.cgRectValue, from: nil)
        let coveredHeight = max(0, view.bounds.maxY - keyboardFrame.minY - view.safeAreaInsets.bottom)
        let options = UIView.AnimationOptions(rawValue: curveValue << 16)

        UIView.animate(withDuration: duration, delay: 0, options: options) {
            self.scrollView.contentInset.bottom = coveredHeight + 16
            self.scrollView.verticalScrollIndicatorInsets.bottom = coveredHeight + 16
            self.view.layoutIfNeeded()
        } completion: { _ in
            self.scrollActiveInputIntoView()
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

    private func scrollActiveInputIntoView() {
        guard let activeInputView else { return }

        let inputFrame = activeInputView.convert(activeInputView.bounds, to: scrollView)
        let paddedFrame = inputFrame.insetBy(dx: 0, dy: -24)
        scrollView.scrollRectToVisible(paddedFrame, animated: true)
    }

    @objc private func endEditingTapped() {
        view.endEditing(true)
    }

    @objc private func designTapped(_ sender: UIControl) {
        guard sender.tag != selectedDesignIndex else { return }
        selectedDesignIndex = sender.tag
        reloadWeightControl()
        resetGeneratedPreview()
        persistDraft()
        refreshUI(animated: true)
    }

    @objc private func weightChanged() {
        preferredWeightIndex = weightControl.selectedSegmentIndex
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
        generationTask?.cancel()

        let inscription = trimmed(inscriptionField.text)
        let wishes = trimmed(wishesTextView.text)
        let weightTitle = selectedWeight.title
        let baseImage = selectedPreviewBaseImage
            ?? previewImageView.image
            ?? UIImage(named: selectedDesign.imageName)

        isGeneratingPreview = true
        updatePreviewControls()
        updateOrderButtonState()

        generationTask = Task { [weak self] in
            guard let self else { return }

            do {
                let image = try await self.imageEditService.generateEditedCakeImage(
                    baseImage: baseImage,
                    design: self.selectedDesign,
                    generationPhotoTitle: "Основное фото",
                    inscription: inscription,
                    wishes: wishes,
                    weightTitle: weightTitle
                )
                guard !Task.isCancelled else { return }

                await MainActor.run {
                    self.isPreviewGenerated = true
                    self.isPreviewOutdated = false
                    self.generatedPreviewImage = image
                    self.persistDraft()
                    self.isGeneratingPreview = false
                    self.refreshUI(animated: true)
                }
            } catch {
                guard !Task.isCancelled else { return }

                await MainActor.run {
                    self.isPreviewGenerated = true
                    self.isPreviewOutdated = false
                    self.generatedPreviewImage = self.makeCurrentPreviewImage()
                    self.persistDraft()
                    self.isGeneratingPreview = false
                    self.refreshUI(animated: true)
                    self.presentGenerationError(error)
                }
            }
        }
    }

    @objc private func orderTapped() {
        view.endEditing(true)
        persistDraft()

        let inscription = trimmed(inscriptionField.text)
        let wishes = trimmed(wishesTextView.text)
        let customCake = CustomCakeOrderDTO(
            designId: selectedDesign.id,
            designName: selectedDesign.name,
            weightTitle: selectedWeight.title,
            weightGrams: selectedWeight.grams,
            inscription: inscription.isEmpty ? nil : inscription,
            wishes: wishes.isEmpty ? nil : wishes,
            filling: selectedDesign.filling,
            accent: selectedDesign.accent,
            composition: selectedDesign.composition,
            previewImageBase64: Self.checkoutPreviewBase64(from: generatedPreviewImage ?? previewImageView.image)
        )

        orderButton.isEnabled = false

        Task { [weak self] in
            guard let self else { return }

            do {
                _ = try await CartService.shared.addCustomCake(customCake, qty: 1)

                await MainActor.run {
                    self.orderButton.isEnabled = true
                    let alert = UIAlertController(
                        title: "Добавлено в корзину",
                        message: nil,
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "Продолжить", style: .cancel))
                    alert.addAction(UIAlertAction(title: "В корзину", style: .default) { [weak self] _ in
                        self?.tabBarController?.selectedIndex = 3
                    })
                    self.present(alert, animated: true)
                }
            } catch {
                await MainActor.run {
                    self.orderButton.isEnabled = true
                    self.presentCartError(error)
                }
            }
        }
    }

    private static func checkoutPreviewBase64(from image: UIImage?) -> String? {
        guard let image else { return nil }
        return image.jpegData(compressionQuality: 0.72)?.base64EncodedString()
    }
}

extension CakeDesignerViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        var view = touch.view

        while let currentView = view {
            if currentView is UIControl || currentView is UITextView || currentView is UITextField {
                return false
            }

            view = currentView.superview
        }

        return true
    }
}

extension CakeDesignerViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        activeInputView = textField
        scrollActiveInputIntoView()
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        if activeInputView === textField {
            activeInputView = nil
        }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

extension CakeDesignerViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        activeInputView = textView
        scrollActiveInputIntoView()
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        if activeInputView === textView {
            activeInputView = nil
        }
    }

    func textViewDidChange(_ textView: UITextView) {
        invalidateGeneratedPreview()
        persistDraft()
        refreshUI(animated: false)
        scrollActiveInputIntoView()
    }
}

private enum GeminiImageEditError: LocalizedError {
    case invalidImageData
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .invalidImageData:
            return "Не удалось подготовить изображение для отправки"
        case .invalidResponse:
            return "Некорректный ответ сервера генерации"
        }
    }
}

private struct CakePreviewGenerationRequest: Encodable {
    let prompt: String
    let imageBase64: String
    let imageMimeType: String
}

private struct CakePreviewGenerationResponse: Decodable {
    let imageBase64: String

    enum CodingKeys: String, CodingKey {
        case imageBase64 = "image_base64"
    }
}

private final class GeminiImageEditService {
    static let shared = GeminiImageEditService()
    private init() {}

    func generateEditedCakeImage(
        baseImage: UIImage?,
        design: CakeDesign,
        generationPhotoTitle: String,
        inscription: String,
        wishes: String,
        weightTitle: String
    ) async throws -> UIImage {
        guard let baseImage else {
            throw GeminiImageEditError.invalidImageData
        }

        let requestImage = Self.imageForRequest(from: baseImage, maxPixelLength: 1024)
        guard let imageData = Self.normalizedPNGData(for: requestImage) else {
            throw GeminiImageEditError.invalidImageData
        }

        let prompt = Self.makePrompt(
            design: design,
            generationPhotoTitle: generationPhotoTitle,
            inscription: inscription,
            wishes: wishes,
            weightTitle: weightTitle
        )

        let response: CakePreviewGenerationResponse = try await APIClient.shared.request(
            "/custom-cake/preview",
            method: "POST",
            body: CakePreviewGenerationRequest(
                prompt: prompt,
                imageBase64: imageData.base64EncodedString(),
                imageMimeType: "image/png"
            ),
            authorized: true
        )

        guard let outData = Data(base64Encoded: response.imageBase64, options: [.ignoreUnknownCharacters]),
              let image = UIImage(data: outData) else {
            throw GeminiImageEditError.invalidResponse
        }

        return image
    }

    private static func makePrompt(
        design: CakeDesign,
        generationPhotoTitle: String,
        inscription: String,
        wishes: String,
        weightTitle: String
    ) -> String {
        let inscriptionText = inscription.isEmpty ? "Без надписи" : inscription
        var lines = [
            "Photorealistically edit this exact reference photo of the custom cake design «\(design.name)».",
            "Reference photo role: \(generationPhotoTitle). Cake filling: \(design.filling). Decor/accent: \(design.accent).",
            "Replace ONLY the existing visible cake inscription with the exact Cyrillic text: «\(inscriptionText)».",
            "The new text must look like real icing piped with a pastry bag directly on the cake surface, with natural thickness, shadows, perspective, and slight surface curvature.",
            "Match the original inscription style and scale. Keep letters neat, readable, and physically plausible for icing.",
            "Preserve all pixels outside the inscription area as much as possible: same cake shape, berries, pearls, cream texture, decorations, colors, box/plate, background, lighting, camera angle, and framing.",
            "Do not add objects. Do not crop. Do not redraw berries or decorations. Do not change the composition or the cake design. Do not make the text look like a flat digital overlay."
        ]

        if !wishes.isEmpty {
            lines.append("Follow these inscription-only wishes exactly, especially requested colors for specific words: \(wishes).")
        } else {
            lines.append("If no inscription color is specified, use the original inscription color from the reference photo.")
        }
        if !design.composition.isEmpty {
            lines.append("Composition context: \(design.composition).")
        }
        lines.append("Weight context: \(weightTitle).")
        return lines.joined(separator: " ")
    }

    private static func normalizedPNGData(for image: UIImage, targetSize: CGSize? = nil) -> Data? {
        let size = targetSize ?? image.size
        let format = UIGraphicsImageRendererFormat.default()
        format.opaque = false
        format.scale = 1

        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let rendered = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        return rendered.pngData()
    }

    private static func imageForRequest(from image: UIImage, maxPixelLength: CGFloat) -> UIImage {
        let size = image.size
        let longestSide = max(size.width, size.height)
        guard longestSide > maxPixelLength else {
            return image
        }

        let scale = maxPixelLength / longestSide
        let targetSize = CGSize(width: size.width * scale, height: size.height * scale)
        let format = UIGraphicsImageRendererFormat.default()
        format.opaque = false
        format.scale = 1

        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }

    private static func generateAutoMaskPNGData(for image: UIImage) -> Data? {
        let size = image.size
        guard size.width > 1, size.height > 1 else { return nil }

        var editableRects = detectTextRects(in: image)

        if editableRects.isEmpty {
            // Fallback area where inscription is usually located.
            editableRects = [
                CGRect(
                    x: size.width * 0.30,
                    y: size.height * 0.30,
                    width: size.width * 0.40,
                    height: size.height * 0.20
                )
            ]
        }

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: size, format: format)

        let masked = renderer.image { renderContext in
            UIColor.white.setFill()
            UIBezierPath(rect: CGRect(origin: .zero, size: size)).fill()

            let cg = renderContext.cgContext
            cg.setBlendMode(.clear)

            for rect in editableRects {
                let inset = -max(8, min(size.width, size.height) * 0.015)
                let expanded = rect.insetBy(dx: inset, dy: inset)
                    .intersection(CGRect(origin: .zero, size: size))
                let radius = max(8, min(expanded.width, expanded.height) * 0.18)
                UIBezierPath(roundedRect: expanded, cornerRadius: radius).fill()
            }
        }

        return masked.pngData()
    }

    private static func detectTextRects(in image: UIImage) -> [CGRect] {
        guard let cgImage = image.cgImage else { return [] }
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.minimumTextHeight = 0.02

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
        } catch {
            return []
        }

        guard let observations = request.results, !observations.isEmpty else {
            return []
        }

        let size = image.size
        return observations.compactMap { observation in
            let box = observation.boundingBox
            let rect = CGRect(
                x: box.origin.x * size.width,
                y: (1 - box.origin.y - box.height) * size.height,
                width: box.width * size.width,
                height: box.height * size.height
            )

            guard rect.width > size.width * 0.03, rect.height > size.height * 0.015 else {
                return nil
            }
            return rect
        }
    }

    private static func makeMultipartBody(
        boundary: String,
        fields: [(name: String, value: String)],
        files: [(name: String, filename: String, mimeType: String, data: Data)]
    ) -> Data {
        var body = Data()
        let boundaryPrefix = "--\(boundary)\r\n"

        for field in fields {
            body.appendUTF8(boundaryPrefix)
            body.appendUTF8("Content-Disposition: form-data; name=\"\(field.name)\"\r\n\r\n")
            body.appendUTF8("\(field.value)\r\n")
        }

        for file in files {
            body.appendUTF8(boundaryPrefix)
            body.appendUTF8(
                "Content-Disposition: form-data; name=\"\(file.name)\"; filename=\"\(file.filename)\"\r\n"
            )
            body.appendUTF8("Content-Type: \(file.mimeType)\r\n\r\n")
            body.append(file.data)
            body.appendUTF8("\r\n")
        }

        body.appendUTF8("--\(boundary)--\r\n")
        return body
    }
}

private extension Data {
    mutating func appendUTF8(_ string: String) {
        append(Data(string.utf8))
    }
}

private extension UIImage {
    func drawAspectFill(in rect: CGRect) {
        let imageRatio = size.width / size.height
        let rectRatio = rect.width / rect.height

        let drawSize: CGSize
        if imageRatio > rectRatio {
            drawSize = CGSize(width: rect.height * imageRatio, height: rect.height)
        } else {
            drawSize = CGSize(width: rect.width, height: rect.width / imageRatio)
        }

        let drawRect = CGRect(
            x: rect.midX - drawSize.width / 2,
            y: rect.midY - drawSize.height / 2,
            width: drawSize.width,
            height: drawSize.height
        )
        draw(in: drawRect)
    }
}

private final class CakeImageCache {
    static let shared = CakeImageCache()
    private let cache = NSCache<NSString, UIImage>()

    private init() {}

    func image(forKey key: String) -> UIImage? {
        cache.object(forKey: key as NSString)
    }

    func set(_ image: UIImage, forKey key: String) {
        cache.setObject(image, forKey: key as NSString)
    }
}

private final class DessertGalleryView: UIView {
    var onItemTap: ((Int) -> Void)?

    private let stackView = UIStackView()
    private var tileViews: [DessertGalleryTileView] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .secondarySystemGroupedBackground
        layer.cornerRadius = 22
        layer.cornerCurve = .continuous

        stackView.axis = .horizontal
        stackView.spacing = 10
        stackView.distribution = .fillEqually

        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
            heightAnchor.constraint(equalToConstant: 156)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(items: [CakeDesignGalleryItem]) {
        if tileViews.count != items.count {
            tileViews.forEach { tile in
                stackView.removeArrangedSubview(tile)
                tile.removeFromSuperview()
            }
            tileViews = items.enumerated().map { index, _ in
                let tile = DessertGalleryTileView()
                tile.tag = index
                tile.addTarget(self, action: #selector(tileTapped(_:)), for: .touchUpInside)
                return tile
            }
            tileViews.forEach { stackView.addArrangedSubview($0) }
        }

        for (index, item) in items.enumerated() where tileViews.indices.contains(index) {
            tileViews[index].tag = index
            tileViews[index].configure(with: item)
        }
    }

    @objc private func tileTapped(_ sender: DessertGalleryTileView) {
        onItemTap?(sender.tag)
    }
}

private final class DessertGalleryTileView: UIControl {
    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    private let fallbackIconView = UIImageView(image: UIImage(systemName: "photo.on.rectangle.angled"))
    private let zoomIconView = UIImageView(image: UIImage(systemName: "arrow.up.left.and.arrow.down.right"))
    private var imageTask: URLSessionDataTask?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .systemBackground
        layer.cornerRadius = 16
        layer.cornerCurve = .continuous
        clipsToBounds = true

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .systemGray6
        imageView.isUserInteractionEnabled = false

        fallbackIconView.tintColor = .systemGray3
        fallbackIconView.contentMode = .scaleAspectFit
        fallbackIconView.isUserInteractionEnabled = false

        zoomIconView.tintColor = .white
        zoomIconView.contentMode = .center
        zoomIconView.backgroundColor = UIColor.black.withAlphaComponent(0.36)
        zoomIconView.layer.cornerRadius = 14
        zoomIconView.clipsToBounds = true
        zoomIconView.isUserInteractionEnabled = false

        titleLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        titleLabel.textColor = .label
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 2
        titleLabel.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.92)
        titleLabel.isUserInteractionEnabled = false

        addSubview(imageView)
        addSubview(fallbackIconView)
        addSubview(zoomIconView)
        addSubview(titleLabel)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        fallbackIconView.translatesAutoresizingMaskIntoConstraints = false
        zoomIconView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            fallbackIconView.centerXAnchor.constraint(equalTo: centerXAnchor),
            fallbackIconView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -8),
            fallbackIconView.widthAnchor.constraint(equalToConstant: 32),
            fallbackIconView.heightAnchor.constraint(equalToConstant: 32),
            zoomIconView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            zoomIconView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            zoomIconView.widthAnchor.constraint(equalToConstant: 28),
            zoomIconView.heightAnchor.constraint(equalToConstant: 28),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
            titleLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 34)
        ])
    }

    deinit { imageTask?.cancel() }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.12) {
                self.transform = self.isHighlighted ? CGAffineTransform(scaleX: 0.96, y: 0.96) : .identity
                self.alpha = self.isHighlighted ? 0.82 : 1
            }
        }
    }

    func configure(with item: CakeDesignGalleryItem) {
        imageTask?.cancel()
        titleLabel.text = item.title
        imageView.image = UIImage(named: item.imageName)
        fallbackIconView.isHidden = imageView.image != nil

        guard let urlString = item.imageURLString, let url = URL(string: urlString) else { return }
        if let cached = CakeImageCache.shared.image(forKey: urlString) {
            imageView.image = cached
            fallbackIconView.isHidden = true
            return
        }
        imageTask = URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data, let image = UIImage(data: data) else { return }
            CakeImageCache.shared.set(image, forKey: urlString)
            DispatchQueue.main.async {
                self?.imageView.image = image
                self?.fallbackIconView.isHidden = true
            }
        }
        imageTask?.resume()
    }

}

private final class DessertGalleryFullscreenViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    private let items: [CakeDesignGalleryItem]
    private let initialIndex: Int
    private let dessertName: String
    private let titleLabel = UILabel()
    private let counterLabel = UILabel()
    private let closeButton = UIButton(type: .system)
    private let collectionView: UICollectionView
    private var didScrollToInitialIndex = false

    init(items: [CakeDesignGalleryItem], initialIndex: Int, dessertName: String) {
        self.items = items
        self.initialIndex = initialIndex
        self.dessertName = dessertName
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        self.collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        collectionView.backgroundColor = .black
        collectionView.isPagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.register(DessertGalleryFullscreenCell.self, forCellWithReuseIdentifier: DessertGalleryFullscreenCell.reuseID)

        titleLabel.text = dessertName
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 1

        counterLabel.textColor = UIColor.white.withAlphaComponent(0.78)
        counterLabel.font = .systemFont(ofSize: 13, weight: .medium)
        counterLabel.textAlignment = .center

        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = .white
        closeButton.backgroundColor = UIColor.white.withAlphaComponent(0.16)
        closeButton.layer.cornerRadius = 18
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

        view.addSubview(collectionView)
        view.addSubview(titleLabel)
        view.addSubview(counterLabel)
        view.addSubview(closeButton)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        counterLabel.translatesAutoresizingMaskIntoConstraints = false
        closeButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 72),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -72),
            counterLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 3),
            counterLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -18),
            closeButton.widthAnchor.constraint(equalToConstant: 36),
            closeButton.heightAnchor.constraint(equalToConstant: 36)
        ])

        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(closeTapped))
        swipeDown.direction = .down
        view.addGestureRecognizer(swipeDown)
        updateCounter(for: initialIndex)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard !didScrollToInitialIndex, collectionView.bounds.width > 0 else { return }
        didScrollToInitialIndex = true
        collectionView.scrollToItem(at: IndexPath(item: initialIndex, section: 0), at: .centeredHorizontally, animated: false)
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { items.count }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DessertGalleryFullscreenCell.reuseID, for: indexPath) as! DessertGalleryFullscreenCell
        cell.configure(with: items[indexPath.item])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        collectionView.bounds.size
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) { updateCounterForCurrentPage() }
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) { updateCounterForCurrentPage() }

    private func updateCounterForCurrentPage() {
        guard collectionView.bounds.width > 0 else { return }
        let index = Int(round(collectionView.contentOffset.x / collectionView.bounds.width))
        updateCounter(for: min(max(index, 0), items.count - 1))
    }

    private func updateCounter(for index: Int) {
        guard items.indices.contains(index) else { return }
        counterLabel.text = "\(items[index].title) • \(index + 1) из \(items.count)"
    }

    @objc private func closeTapped() { dismiss(animated: true) }
}

private final class DessertGalleryFullscreenCell: UICollectionViewCell, UIScrollViewDelegate {
    static let reuseID = "DessertGalleryFullscreenCell"
    private let scrollView = UIScrollView()
    private let imageView = UIImageView()
    private let fallbackIconView = UIImageView(image: UIImage(systemName: "photo"))
    private var imageTask: URLSessionDataTask?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black
        scrollView.delegate = self
        scrollView.minimumZoomScale = 1
        scrollView.maximumZoomScale = 3
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.contentInsetAdjustmentBehavior = .never
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        fallbackIconView.tintColor = UIColor.white.withAlphaComponent(0.35)
        fallbackIconView.contentMode = .scaleAspectFit
        contentView.addSubview(scrollView)
        scrollView.addSubview(imageView)
        contentView.addSubview(fallbackIconView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        imageView.translatesAutoresizingMaskIntoConstraints = false
        fallbackIconView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: contentView.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            imageView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            imageView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            imageView.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor),
            fallbackIconView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            fallbackIconView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            fallbackIconView.widthAnchor.constraint(equalToConstant: 54),
            fallbackIconView.heightAnchor.constraint(equalToConstant: 54)
        ])
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(doubleTapped(_:)))
        doubleTap.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTap)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    deinit { imageTask?.cancel() }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageTask?.cancel()
        imageTask = nil
        imageView.image = nil
        fallbackIconView.isHidden = false
        scrollView.setZoomScale(1, animated: false)
    }

    func configure(with item: CakeDesignGalleryItem) {
        imageTask?.cancel()
        scrollView.setZoomScale(1, animated: false)
        imageView.image = UIImage(named: item.imageName)
        fallbackIconView.isHidden = imageView.image != nil
        guard let urlString = item.imageURLString, let url = URL(string: urlString) else { return }
        if let cached = CakeImageCache.shared.image(forKey: urlString) {
            imageView.image = cached
            fallbackIconView.isHidden = true
            return
        }
        imageTask = URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data, let image = UIImage(data: data) else { return }
            CakeImageCache.shared.set(image, forKey: urlString)
            DispatchQueue.main.async {
                self?.imageView.image = image
                self?.fallbackIconView.isHidden = true
            }
        }
        imageTask?.resume()
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? { imageView }

    @objc private func doubleTapped(_ gesture: UITapGestureRecognizer) {
        if scrollView.zoomScale > 1 {
            scrollView.setZoomScale(1, animated: true)
        } else {
            let point = gesture.location(in: imageView)
            scrollView.zoom(to: CGRect(x: point.x - 60, y: point.y - 60, width: 120, height: 120), animated: true)
        }
    }
}

private final class CakeDesignOptionView: UIControl {
    private let cardView = UIView()
    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let statsLabel = UILabel()
    private var imageTask: URLSessionDataTask?

    init(design: CakeDesign) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        cardView.backgroundColor = .systemBackground
        cardView.layer.cornerRadius = 18
        cardView.layer.cornerCurve = .continuous
        cardView.layer.borderWidth = 1
        cardView.layer.borderColor = UIColor.systemGray4.cgColor
        cardView.isUserInteractionEnabled = false

        imageView.image = UIImage(named: design.imageName)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 14
        imageView.layer.cornerCurve = .continuous

        titleLabel.text = design.name
        titleLabel.font = .systemFont(ofSize: 17, weight: .bold)
        titleLabel.numberOfLines = 2

        subtitleLabel.text = design.subtitle
        subtitleLabel.font = .systemFont(ofSize: 13, weight: .regular)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 2

        if let smallestWeight = design.availableWeights.first {
            statsLabel.text = "от \(design.price(for: smallestWeight.grams)) рублей"
        } else {
            statsLabel.text = "\(design.kcalPer100g) ккал"
        }
        statsLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        statsLabel.textColor = .systemBlue
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
            imageView.heightAnchor.constraint(equalToConstant: 128)
        ])

        loadRemoteImageIfNeeded(for: design)
    }

    deinit {
        imageTask?.cancel()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setSelected(_ selected: Bool, animated: Bool) {
        let updates = {
            self.cardView.layer.borderColor = (selected ? UIColor.systemBlue : UIColor.systemGray4).cgColor
            self.cardView.layer.borderWidth = selected ? 2 : 1
            self.cardView.backgroundColor = selected ? UIColor.systemBlue.withAlphaComponent(0.10) : .systemBackground
            self.cardView.layer.shadowColor = selected ? UIColor.systemBlue.withAlphaComponent(0.22).cgColor : UIColor.clear.cgColor
            self.cardView.layer.shadowOpacity = selected ? 1 : 0
            self.cardView.layer.shadowRadius = selected ? 10 : 0
            self.cardView.layer.shadowOffset = CGSize(width: 0, height: 4)
        }

        if animated {
            UIView.animate(withDuration: 0.2, animations: updates)
        } else {
            updates()
        }
    }

    private func loadRemoteImageIfNeeded(for design: CakeDesign) {
        guard let urlString = design.imageURLString,
              let url = URL(string: urlString) else {
            return
        }

        if let cached = CakeImageCache.shared.image(forKey: urlString) {
            imageView.image = cached
            return
        }

        imageTask = URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data,
                  let image = UIImage(data: data) else { return }

            CakeImageCache.shared.set(image, forKey: urlString)
            DispatchQueue.main.async {
                self?.imageView.image = image
            }
        }
        imageTask?.resume()
    }
}
