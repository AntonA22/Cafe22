import UIKit

final class AboutCafeViewController: UIViewController {

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let stackView = UIStackView()

    private let galleryImages = [
        "aboutCafeInterior",
        "aboutCafeCoffee",
        "aboutCafeDessert",
        "aboutCafeCake",
        "aboutCafeAtmosphere"
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "О нас"
        view.backgroundColor = .systemGroupedBackground
        useRussianBackButtonTitle()

        setupScrollView()
        setupContent()
    }

    private func setupScrollView() {
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        scrollView.addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 20

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -28)
        ])
    }

    private func setupContent() {
        stackView.addArrangedSubview(makeHeroView())
        stackView.addArrangedSubview(makeStatsView())
        stackView.addArrangedSubview(makeTextSection(
            title: "Кофейня-кондитерская, где начинается вкусный день",
            body: "ЗАРЯДКА КОФЕ — место, куда возвращаются за настроением, теплом и ощущением маленького праздника. Уже 7 лет мы создаем для гостей не просто напитки и десерты, а атмосферу: аромат свежесваренного кофе, авторские торты, уютные разговоры и минуты, которые хочется запомнить."
        ))
        stackView.addArrangedSubview(makeGalleryView())
        stackView.addArrangedSubview(makeTextSection(
            title: "Кофе, который заряжает",
            body: "Для нас кофе — это начало утра, пауза в насыщенном дне и маленький ритуал для себя. Бариста раскрывают вкус каждого зерна, готовят классику и придумывают авторские напитки с вниманием к балансу, аромату и характеру."
        ))
        stackView.addArrangedSubview(makeTextSection(
            title: "Авторские десерты и торты",
            body: "Кондитеры ЗАРЯДКА КОФЕ создают десерты по индивидуальным рецептам: нежные текстуры, продуманные вкусы и красивая подача. Для праздников, дней рождения и важных дат мы готовим торты с индивидуальной надписью и праздничной упаковкой."
        ))
        stackView.addArrangedSubview(makeTextSection(
            title: "Индивидуальный подход",
            body: "Хотите необычный кофейный напиток, торт с особенной надписью или сладкий подарок? Мы поможем подобрать решение под ваш вкус, повод и настроение."
        ))
        stackView.addArrangedSubview(makeContactsView())
        stackView.addArrangedSubview(makeAddressView())
        stackView.addArrangedSubview(makeButtonsView())
    }

    private func makeHeroView() -> UIView {
        let container = UIView()
        container.backgroundColor = .secondarySystemGroupedBackground
        container.layer.cornerRadius = 22
        container.clipsToBounds = true

        let imageView = UIImageView(image: UIImage(named: "aboutCafeHero"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        container.addSubview(imageView)

        let gradientOverlay = GradientOverlayView()
        gradientOverlay.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(gradientOverlay)

        let logoView = UIImageView(image: UIImage(named: "zaryadkaLogo"))
        logoView.translatesAutoresizingMaskIntoConstraints = false
        logoView.contentMode = .scaleAspectFit

        let logoContainer = UIView()
        logoContainer.translatesAutoresizingMaskIntoConstraints = false
        logoContainer.backgroundColor = UIColor.white.withAlphaComponent(0.94)
        logoContainer.layer.cornerRadius = 30
        logoContainer.clipsToBounds = true
        logoContainer.addSubview(logoView)

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "ЗАРЯДКА КОФЕ"
        titleLabel.font = .systemFont(ofSize: 30, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.numberOfLines = 0

        let subtitleLabel = UILabel()
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.text = "Кофе вдохновляет, десерты радуют, а каждый день становится немного теплее."
        subtitleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.92)
        subtitleLabel.numberOfLines = 0

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.translatesAutoresizingMaskIntoConstraints = false
        textStack.axis = .vertical
        textStack.spacing = 8
        container.addSubview(textStack)
        container.addSubview(logoContainer)

        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(equalToConstant: 320),

            imageView.topAnchor.constraint(equalTo: container.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: container.bottomAnchor),

            gradientOverlay.topAnchor.constraint(equalTo: container.topAnchor),
            gradientOverlay.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            gradientOverlay.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            gradientOverlay.bottomAnchor.constraint(equalTo: container.bottomAnchor),

            logoContainer.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
            logoContainer.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            logoContainer.widthAnchor.constraint(equalToConstant: 60),
            logoContainer.heightAnchor.constraint(equalToConstant: 60),

            logoView.topAnchor.constraint(equalTo: logoContainer.topAnchor, constant: 6),
            logoView.leadingAnchor.constraint(equalTo: logoContainer.leadingAnchor, constant: 6),
            logoView.trailingAnchor.constraint(equalTo: logoContainer.trailingAnchor, constant: -6),
            logoView.bottomAnchor.constraint(equalTo: logoContainer.bottomAnchor, constant: -6),

            textStack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            textStack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),
            textStack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -20)
        ])

        return container
    }

    private func makeStatsView() -> UIView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 10
        stack.distribution = .fillEqually

        stack.addArrangedSubview(makeStatCard(value: "7 лет", title: "вкуса и доверия"))
        stack.addArrangedSubview(makeStatCard(value: "25", title: "человек в команде"))
        stack.addArrangedSubview(makeStatCard(value: "08-20", title: "каждый день"))

        return stack
    }

    private func makeStatCard(value: String, title: String) -> UIView {
        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = .systemFont(ofSize: 22, weight: .bold)
        valueLabel.textColor = UIColor(red: 0.34, green: 0.18, blue: 0.10, alpha: 1)
        valueLabel.textAlignment = .center

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 12, weight: .medium)
        titleLabel.textColor = .secondaryLabel
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 2

        let stack = UIStackView(arrangedSubviews: [valueLabel, titleLabel])
        stack.axis = .vertical
        stack.spacing = 6
        stack.alignment = .center

        let card = makeCard()
        card.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            card.heightAnchor.constraint(greaterThanOrEqualToConstant: 96),
            stack.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 8),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -8)
        ])

        return card
    }

    private func makeTextSection(title: String, body: String) -> UIView {
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 22, weight: .bold)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 0

        let bodyLabel = UILabel()
        bodyLabel.text = body
        bodyLabel.font = .systemFont(ofSize: 16, weight: .regular)
        bodyLabel.textColor = .secondaryLabel
        bodyLabel.numberOfLines = 0
        bodyLabel.setLineSpacing(4)

        let stack = UIStackView(arrangedSubviews: [titleLabel, bodyLabel])
        stack.axis = .vertical
        stack.spacing = 10

        let card = makeCard()
        card.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 18),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 18),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -18),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -18)
        ])

        return card
    }

    private func makeGalleryView() -> UIView {
        let titleLabel = UILabel()
        titleLabel.text = "Атмосфера ЗАРЯДКИ"
        titleLabel.font = .systemFont(ofSize: 22, weight: .bold)

        let scroll = UIScrollView()
        scroll.showsHorizontalScrollIndicator = false
        scroll.alwaysBounceHorizontal = true

        let imageStack = UIStackView()
        imageStack.axis = .horizontal
        imageStack.spacing = 12
        scroll.addSubview(imageStack)
        imageStack.translatesAutoresizingMaskIntoConstraints = false

        galleryImages.forEach { imageName in
            let imageView = UIImageView(image: UIImage(named: imageName))
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            imageView.layer.cornerRadius = 18
            imageView.backgroundColor = .tertiarySystemGroupedBackground
            imageStack.addArrangedSubview(imageView)
            imageView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                imageView.widthAnchor.constraint(equalToConstant: 170),
                imageView.heightAnchor.constraint(equalToConstant: 220)
            ])
        }

        NSLayoutConstraint.activate([
            imageStack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor),
            imageStack.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor),
            imageStack.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor),
            imageStack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor),
            imageStack.heightAnchor.constraint(equalTo: scroll.frameLayoutGuide.heightAnchor),
            scroll.heightAnchor.constraint(equalToConstant: 220)
        ])

        let stack = UIStackView(arrangedSubviews: [titleLabel, scroll])
        stack.axis = .vertical
        stack.spacing = 12
        return stack
    }

    private func makeAddressView() -> UIView {
        let icon = UIImageView(image: UIImage(systemName: "mappin.and.ellipse"))
        icon.tintColor = UIColor(red: 0.55, green: 0.27, blue: 0.12, alpha: 1)
        icon.contentMode = .scaleAspectFit

        let titleLabel = UILabel()
        titleLabel.text = "Флагманская кофейня"
        titleLabel.font = .systemFont(ofSize: 20, weight: .bold)

        let addressLabel = UILabel()
        addressLabel.text = "Проспект Мира, 95с1\nЕжедневно с 08:00 до 20:00"
        addressLabel.font = .systemFont(ofSize: 15, weight: .regular)
        addressLabel.textColor = .secondaryLabel
        addressLabel.numberOfLines = 0

        let labelsStack = UIStackView(arrangedSubviews: [titleLabel, addressLabel])
        labelsStack.axis = .vertical
        labelsStack.spacing = 10

        let row = UIStackView(arrangedSubviews: [icon, labelsStack])
        row.axis = .horizontal
        row.alignment = .top
        row.spacing = 12

        let card = makeCard()
        card.addSubview(row)
        row.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            icon.widthAnchor.constraint(equalToConstant: 28),
            icon.heightAnchor.constraint(equalToConstant: 28),

            row.topAnchor.constraint(equalTo: card.topAnchor, constant: 18),
            row.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 18),
            row.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -18),
            row.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -18)
        ])

        return card
    }

    private func makeContactsView() -> UIView {
        let icon = UIImageView(image: UIImage(systemName: "phone.bubble.left.fill"))
        icon.tintColor = UIColor(red: 0.55, green: 0.27, blue: 0.12, alpha: 1)
        icon.contentMode = .scaleAspectFit

        let titleLabel = UILabel()
        titleLabel.text = "Контакты"
        titleLabel.font = .systemFont(ofSize: 20, weight: .bold)

        let contactsLabel = UILabel()
        contactsLabel.text = "Для заказов, вопросов и обратной связи:\n+7 962 962 00 45\na66110222@gmail.com"
        contactsLabel.font = .systemFont(ofSize: 15, weight: .regular)
        contactsLabel.textColor = .secondaryLabel
        contactsLabel.numberOfLines = 0

        let labelsStack = UIStackView(arrangedSubviews: [titleLabel, contactsLabel])
        labelsStack.axis = .vertical
        labelsStack.spacing = 10

        let row = UIStackView(arrangedSubviews: [icon, labelsStack])
        row.axis = .horizontal
        row.alignment = .top
        row.spacing = 12

        let card = makeCard()
        card.addSubview(row)
        row.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            icon.widthAnchor.constraint(equalToConstant: 28),
            icon.heightAnchor.constraint(equalToConstant: 28),

            row.topAnchor.constraint(equalTo: card.topAnchor, constant: 18),
            row.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 18),
            row.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -18),
            row.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -18)
        ])

        return card
    }

    private func makeButtonsView() -> UIView {
        let cakeButton = makeActionButton(title: "Заказать торт с надписью", backgroundColor: .systemBlue, textColor: .white)
        cakeButton.addTarget(self, action: #selector(openCakeDesigner), for: .touchUpInside)

        let menuButton = makeActionButton(title: "Посмотреть меню", backgroundColor: .systemBlue, textColor: .white)
        menuButton.addTarget(self, action: #selector(openMenu), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [cakeButton, menuButton])
        stack.axis = .vertical
        stack.spacing = 12

        NSLayoutConstraint.activate([
            cakeButton.heightAnchor.constraint(equalToConstant: 52),
            menuButton.heightAnchor.constraint(equalToConstant: 52)
        ])

        return stack
    }

    private func makeActionButton(title: String, backgroundColor: UIColor, textColor: UIColor) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        button.setTitleColor(textColor, for: .normal)
        button.backgroundColor = backgroundColor
        button.layer.cornerRadius = 16
        return button
    }

    private func makeCard() -> UIView {
        let view = UIView()
        view.backgroundColor = .secondarySystemGroupedBackground
        view.layer.cornerRadius = 18
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.05
        view.layer.shadowRadius = 10
        view.layer.shadowOffset = CGSize(width: 0, height: 4)
        return view
    }

    @objc private func openCakeDesigner() {
        tabBarController?.selectedIndex = 1
        navigationController?.popToRootViewController(animated: false)
    }

    @objc private func openMenu() {
        tabBarController?.selectedIndex = 0
        navigationController?.popToRootViewController(animated: false)
    }
}

private final class GradientOverlayView: UIView {
    override class var layerClass: AnyClass {
        CAGradientLayer.self
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupGradient()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupGradient()
    }

    private func setupGradient() {
        guard let gradientLayer = layer as? CAGradientLayer else { return }

        gradientLayer.colors = [
            UIColor.black.withAlphaComponent(0.04).cgColor,
            UIColor.black.withAlphaComponent(0.10).cgColor,
            UIColor.black.withAlphaComponent(0.58).cgColor
        ]
        gradientLayer.locations = [0.0, 0.55, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
    }
}

private extension UILabel {
    func setLineSpacing(_ spacing: CGFloat) {
        guard let text = text else { return }

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = spacing
        paragraphStyle.lineBreakMode = .byWordWrapping

        attributedText = NSAttributedString(
            string: text,
            attributes: [
                .paragraphStyle: paragraphStyle,
                .font: font as Any,
                .foregroundColor: textColor as Any
            ]
        )
    }
}
