//
//  ProductDetailViewController.swift
//  Cafe22
//
//  Created by Антон Абалуев on 27.11.2025.
//

import UIKit
import Kingfisher

class ProductDetailViewController: UIViewController, UIScrollViewDelegate {

    var productId: Int?
    
    private var isImagesBuilt = false
    private var product: Product?
    private var isCartActionInFlight = false {
        didSet { updateCartUI() }
    }
    private var quantity: Int = 0 {
        didSet { updateCartUI() }
    }
    private var isFavorite = false {
        didSet { updateFavoriteUI() }
    }
    private var isFavoriteActionInFlight = false {
        didSet { updateFavoriteUI() }
    }

    // UI
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private let imageScrollView = UIScrollView()
    private let favoriteButton = UIButton(type: .system)
    private let pageControl = UIPageControl()

    private let nameLabel = UILabel()
    private let priceLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let compositionTitleLabel = UILabel()
    private let compositionLabel = UILabel()
    private let nutritionStack = UIStackView()

    private var images: [UIImage] = []
    private var imageViews: [UIImageView] = []
    private var imageLoadGeneration = UUID()
    private var currentIndex: Int = 0
    
    private let bottomBar = UIView()
    private let priceBottomLabel = UILabel()
    private let addToCartButton = UIButton(type: .system)
    private let qtyBackgroundView = UIView()
    private let qtyContainer = UIStackView()
    private let minusButton = UIButton(type: .system)
    private let qtyLabel = UILabel()
    private let plusButton = UIButton(type: .system)
    private var addToCartTopConstraint: NSLayoutConstraint?
    private var addToCartCenterYConstraint: NSLayoutConstraint?
    private var addToCartLeadingConstraint: NSLayoutConstraint?
    private var addToCartTrailingConstraint: NSLayoutConstraint?
    private var addToCartWidthConstraint: NSLayoutConstraint?

    override func viewDidLoad() {
        super.viewDidLoad()
        useRussianBackButtonTitle()

        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 16
        view.clipsToBounds = true

        setupUI()
        
        // точки должны листать картинки!
        pageControl.addTarget(self, action: #selector(pageControlTapped), for: .valueChanged)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(cartDidChange(_:)),
                                               name: .cartDidChange,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(favoritesDidChange(_:)),
                                               name: .favoritesDidChange,
                                               object: nil)

        loadProduct()
        loadCart()
        loadFavoriteState()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        view.bringSubviewToFront(favoriteButton)
        print("DETAIL SCREEN OPENED, productId =", productId as Any)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: UI SETUP
    private func setupUI() {

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leftAnchor.constraint(equalTo: view.leftAnchor),
            scrollView.rightAnchor.constraint(equalTo: view.rightAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leftAnchor.constraint(equalTo: scrollView.leftAnchor),
            contentView.rightAnchor.constraint(equalTo: scrollView.rightAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])

        // ------------------------
        // Карусель фото
        // ------------------------
        imageScrollView.translatesAutoresizingMaskIntoConstraints = false
        imageScrollView.isPagingEnabled = true
        imageScrollView.showsHorizontalScrollIndicator = false
        imageScrollView.delegate = self
        contentView.addSubview(imageScrollView)

        NSLayoutConstraint.activate([
            imageScrollView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageScrollView.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            imageScrollView.rightAnchor.constraint(equalTo: contentView.rightAnchor),
            imageScrollView.heightAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.6)
        ])

        favoriteButton.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.92)
        favoriteButton.tintColor = .systemRed
        favoriteButton.layer.cornerRadius = 22
        favoriteButton.layer.shadowColor = UIColor.black.cgColor
        favoriteButton.layer.shadowOpacity = 0.12
        favoriteButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        favoriteButton.layer.shadowRadius = 5
        favoriteButton.addTarget(self, action: #selector(favoriteTapped), for: .touchUpInside)
        favoriteButton.addTarget(self, action: #selector(favoriteTouchDown), for: .touchDown)
        favoriteButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(favoriteButton)

        NSLayoutConstraint.activate([
            favoriteButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 14),
            favoriteButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            favoriteButton.widthAnchor.constraint(equalToConstant: 44),
            favoriteButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        /// точки для картинок
        pageControl.hidesForSinglePage = false
        pageControl.pageIndicatorTintColor = .lightGray
        pageControl.currentPageIndicatorTintColor = .black

        pageControl.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(pageControl)
        NSLayoutConstraint.activate([
            pageControl.topAnchor.constraint(equalTo: imageScrollView.bottomAnchor, constant: 8),
            pageControl.centerXAnchor.constraint(equalTo: contentView.centerXAnchor)
        ])

        // ------------------------
        // Название
        // ------------------------
        nameLabel.font = .systemFont(ofSize: 26, weight: .bold)
        nameLabel.numberOfLines = 2
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(nameLabel)
        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: pageControl.bottomAnchor, constant: 16),
            nameLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 16),
            nameLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -16)
        ])

        // ------------------------
        // Цена
        // ------------------------
        priceLabel.font = .systemFont(ofSize: 22, weight: .semibold)
        priceLabel.textColor = .systemGreen
        priceLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(priceLabel)
        NSLayoutConstraint.activate([
            priceLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),
            priceLabel.leftAnchor.constraint(equalTo: nameLabel.leftAnchor)
        ])

        // ------------------------
        // Описание
        // ------------------------
        descriptionLabel.font = .systemFont(ofSize: 17)
        descriptionLabel.numberOfLines = 0
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(descriptionLabel)
        NSLayoutConstraint.activate([
            descriptionLabel.topAnchor.constraint(equalTo: priceLabel.bottomAnchor, constant: 20),
            descriptionLabel.leftAnchor.constraint(equalTo: nameLabel.leftAnchor),
            descriptionLabel.rightAnchor.constraint(equalTo: nameLabel.rightAnchor)
        ])

        // ------------------------
        // Состав
        // ------------------------
        compositionTitleLabel.text = "Состав"
        compositionTitleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        compositionTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(compositionTitleLabel)

        compositionLabel.font = .systemFont(ofSize: 16)
        compositionLabel.textColor = .secondaryLabel
        compositionLabel.numberOfLines = 0
        compositionLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(compositionLabel)

        NSLayoutConstraint.activate([
            compositionTitleLabel.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 16),
            compositionTitleLabel.leftAnchor.constraint(equalTo: nameLabel.leftAnchor),
            compositionTitleLabel.rightAnchor.constraint(equalTo: nameLabel.rightAnchor),

            compositionLabel.topAnchor.constraint(equalTo: compositionTitleLabel.bottomAnchor, constant: 6),
            compositionLabel.leftAnchor.constraint(equalTo: nameLabel.leftAnchor),
            compositionLabel.rightAnchor.constraint(equalTo: nameLabel.rightAnchor)
        ])

        // ------------------------
        // Таблица нутриентов
        // ------------------------
        nutritionStack.axis = .horizontal
        nutritionStack.distribution = .fillEqually
        nutritionStack.spacing = 10
        nutritionStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(nutritionStack)
        NSLayoutConstraint.activate([
            nutritionStack.topAnchor.constraint(equalTo: compositionLabel.bottomAnchor, constant: 20),
            nutritionStack.leftAnchor.constraint(equalTo: nameLabel.leftAnchor),
            nutritionStack.rightAnchor.constraint(equalTo: nameLabel.rightAnchor),
            nutritionStack.heightAnchor.constraint(equalToConstant: 70),
            nutritionStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
        // ------------------------
        // Нижняя панель покупки
        // ------------------------
        bottomBar.translatesAutoresizingMaskIntoConstraints = false
        bottomBar.backgroundColor = .systemBackground
        bottomBar.layer.shadowColor = UIColor.black.cgColor
        bottomBar.layer.shadowOpacity = 0.1
        bottomBar.layer.shadowOffset = CGSize(width: 0, height: -2)
        bottomBar.layer.shadowRadius = 6

        view.addSubview(bottomBar)

        NSLayoutConstraint.activate([
            bottomBar.leftAnchor.constraint(equalTo: view.leftAnchor),
            bottomBar.rightAnchor.constraint(equalTo: view.rightAnchor),
            bottomBar.bottomAnchor.constraint(equalTo: view.bottomAnchor), // до самого низа
            bottomBar.heightAnchor.constraint(equalToConstant: 100)
        ])

        // PRICE LABEL
        priceBottomLabel.font = .systemFont(ofSize: 22, weight: .bold)
        priceBottomLabel.textColor = .label
        priceBottomLabel.translatesAutoresizingMaskIntoConstraints = false

        bottomBar.addSubview(priceBottomLabel)

        // ADD TO CART BUTTON
        addToCartButton.setTitle("В корзину", for: .normal)
        addToCartButton.setTitleColor(.white, for: .normal)
        addToCartButton.backgroundColor = .systemBlue
        addToCartButton.layer.cornerRadius = 12
        addToCartButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        addToCartButton.translatesAutoresizingMaskIntoConstraints = false
        addToCartButton.addTarget(self, action: #selector(addToCartTapped), for: .touchUpInside)

        bottomBar.addSubview(addToCartButton)

        qtyBackgroundView.backgroundColor = .systemGray6
        qtyBackgroundView.layer.cornerRadius = 12
        qtyBackgroundView.layer.borderWidth = 1
        qtyBackgroundView.layer.borderColor = UIColor.systemGray4.cgColor
        qtyBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        qtyBackgroundView.isHidden = true
        bottomBar.addSubview(qtyBackgroundView)

        qtyContainer.axis = .horizontal
        qtyContainer.alignment = .center
        qtyContainer.distribution = .equalCentering
        qtyContainer.spacing = 16
        qtyContainer.translatesAutoresizingMaskIntoConstraints = false
        qtyBackgroundView.addSubview(qtyContainer)

        minusButton.setImage(UIImage(systemName: "minus.circle.fill"), for: .normal)
        minusButton.tintColor = .systemBlue
        minusButton.addTarget(self, action: #selector(minusTapped), for: .touchUpInside)

        plusButton.setImage(UIImage(systemName: "plus.circle.fill"), for: .normal)
        plusButton.tintColor = .systemBlue
        plusButton.addTarget(self, action: #selector(plusTapped), for: .touchUpInside)

        qtyLabel.font = .systemFont(ofSize: 18, weight: .bold)
        qtyLabel.textAlignment = .center
        qtyLabel.setContentHuggingPriority(.required, for: .horizontal)

        qtyContainer.addArrangedSubview(minusButton)
        qtyContainer.addArrangedSubview(qtyLabel)
        qtyContainer.addArrangedSubview(plusButton)

        addToCartTopConstraint = addToCartButton.topAnchor.constraint(equalTo: bottomBar.topAnchor, constant: 8)
        addToCartCenterYConstraint = addToCartButton.centerYAnchor.constraint(equalTo: bottomBar.centerYAnchor)
        addToCartLeadingConstraint = addToCartButton.leadingAnchor.constraint(equalTo: bottomBar.leadingAnchor, constant: 16)
        addToCartTrailingConstraint = addToCartButton.trailingAnchor.constraint(equalTo: bottomBar.trailingAnchor, constant: -16)
        addToCartWidthConstraint = addToCartButton.widthAnchor.constraint(equalToConstant: 140)

        NSLayoutConstraint.activate([
            // PRICE LABEL — сверху слева
            priceBottomLabel.topAnchor.constraint(equalTo: bottomBar.topAnchor, constant: 12),
            priceBottomLabel.leftAnchor.constraint(equalTo: bottomBar.leftAnchor, constant: 16),

            // ADD TO CART BUTTON — сверху справа
            addToCartButton.heightAnchor.constraint(equalToConstant: 48),

            qtyBackgroundView.topAnchor.constraint(equalTo: addToCartButton.topAnchor),
            qtyBackgroundView.leadingAnchor.constraint(equalTo: addToCartButton.leadingAnchor),
            qtyBackgroundView.trailingAnchor.constraint(equalTo: addToCartButton.trailingAnchor),
            qtyBackgroundView.bottomAnchor.constraint(equalTo: addToCartButton.bottomAnchor),

            qtyContainer.topAnchor.constraint(equalTo: qtyBackgroundView.topAnchor, constant: 8),
            qtyContainer.leadingAnchor.constraint(equalTo: qtyBackgroundView.leadingAnchor, constant: 12),
            qtyContainer.trailingAnchor.constraint(equalTo: qtyBackgroundView.trailingAnchor, constant: -12),
            qtyContainer.bottomAnchor.constraint(equalTo: qtyBackgroundView.bottomAnchor, constant: -8),

            // ScrollView — выше bottomBar
            scrollView.bottomAnchor.constraint(equalTo: bottomBar.topAnchor)
        ])

        addToCartCenterYConstraint?.isActive = true
        addToCartLeadingConstraint?.isActive = true
        addToCartTrailingConstraint?.isActive = true

        updateFavoriteUI()
        updateCartUI()
    }

    // MARK: UPDATE UI
    private func updateUI(with product: Product) {
        self.product = product
        if product.isFavorite == true {
            isFavorite = true
        }

        nameLabel.text = product.name
        priceLabel.text = "\(Int(product.price)) ₽"
        descriptionLabel.text = product.description ?? "Нет описания"
        let trimmedComposition = product.composition?.trimmingCharacters(in: .whitespacesAndNewlines)
        compositionLabel.text = (trimmedComposition?.isEmpty == false) ? trimmedComposition : "Состав не указан"

        setupNutrition(product)

        loadImages(from: product.photos)
        updateCartUI()
    }

    private func setupNutrition(_ product: Product) {

        nutritionStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let weightText: String
        let unit = product.category == "Авторские напитки" ? "мл" : "г"
        weightText = "\(product.weight ?? 0) \(unit)"

        let items: [(String, String)] = [
            ("Ккал", "\(product.calories ?? 0)"),
            ("Белки", "\(product.proteins ?? 0) г"),
            ("Жиры", "\(product.fats ?? 0) г"),
            ("Углеводы", "\(product.carbohydrates ?? 0) г"),
            ("Вес", weightText)
        ]

        for (title, value) in items {
            let container = UIView()

            let t = UILabel()
            t.text = title
            t.font = .systemFont(ofSize: 13)
            t.textAlignment = .center

            let v = UILabel()
            v.text = value
            v.font = .systemFont(ofSize: 17, weight: .bold)
            v.textAlignment = .center

            let stack = UIStackView(arrangedSubviews: [t, v])
            stack.axis = .vertical
            stack.alignment = .center
            stack.spacing = 3
            stack.translatesAutoresizingMaskIntoConstraints = false

            container.addSubview(stack)
            NSLayoutConstraint.activate([
                stack.topAnchor.constraint(equalTo: container.topAnchor),
                stack.bottomAnchor.constraint(equalTo: container.bottomAnchor),
                stack.leftAnchor.constraint(equalTo: container.leftAnchor),
                stack.rightAnchor.constraint(equalTo: container.rightAnchor)
            ])

            nutritionStack.addArrangedSubview(container)
        }
    }

    private func loadImages(from urls: [String]?) {
        let imageNames = (urls?.isEmpty == false ? urls! : ["eclair"])
        let placeholder = UIImage(named: "eclair") ?? UIImage(systemName: "photo") ?? UIImage()
        let generation = UUID()

        imageLoadGeneration = generation
        currentIndex = 0
        images = Array(repeating: placeholder, count: imageNames.count)
        pageControl.numberOfPages = imageNames.count
        pageControl.currentPage = 0
        isImagesBuilt = false
        view.setNeedsLayout()

        for (index, item) in imageNames.enumerated() {
            if let urlString = normalizedRemoteImageURLString(item),
               let url = URL(string: urlString),
               let scheme = url.scheme?.lowercased(),
               scheme == "http" || scheme == "https" {
                let processor = DownsamplingImageProcessor(size: CGSize(width: 1100, height: 760))
                KingfisherManager.shared.retrieveImage(
                    with: url,
                    options: [
                        .processor(processor),
                        .scaleFactor(UIScreen.main.scale),
                        .cacheOriginalImage
                    ]
                ) { [weak self] result in
                    guard let self,
                          case .success(let value) = result else { return }

                    DispatchQueue.main.async {
                        guard self.imageLoadGeneration == generation,
                              index < self.images.count else { return }
                        self.images[index] = value.image
                        self.updateImageView(at: index)
                    }
                }
            } else if let img = UIImage(named: item), index < images.count {
                images[index] = img
            }
        }
    }

    private func normalizedRemoteImageURLString(_ rawValue: String?) -> String? {
        guard var value = rawValue?.trimmingCharacters(in: .whitespacesAndNewlines),
              !value.isEmpty else { return nil }

        value = value.replacingOccurrences(of: "\\/", with: "/")

        if URL(string: value) != nil {
            return value
        }

        return value.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if !isImagesBuilt, !images.isEmpty {
            setupImagesScroll()
            isImagesBuilt = true
        }
    }
    
    @objc func pageControlTapped(_ sender: UIPageControl) {
        currentIndex = sender.currentPage
        scrollToIndex(currentIndex)
    }

    private func setupImagesScroll() {
        imageScrollView.subviews.forEach { $0.removeFromSuperview() }
        imageViews.removeAll()

        let width = imageScrollView.frame.width
        let height = imageScrollView.frame.height
        guard width > 0, height > 0 else { return }

        imageScrollView.contentSize = CGSize(width: width * CGFloat(images.count), height: height)

        for (index, img) in images.enumerated() {
            let imageView = UIImageView(image: img)
            imageView.frame = CGRect(x: width * CGFloat(index), y: 0, width: width, height: height)
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            imageScrollView.addSubview(imageView)
            imageViews.append(imageView)
        }

        pageControl.numberOfPages = images.count
        currentIndex = min(currentIndex, max(images.count - 1, 0))
        pageControl.currentPage = currentIndex
        let xOffset = CGFloat(currentIndex) * width
        imageScrollView.setContentOffset(CGPoint(x: xOffset, y: 0), animated: false)
    }

    private func updateImageView(at index: Int) {
        guard index < images.count else { return }

        if index < imageViews.count {
            imageViews[index].image = images[index]
        } else {
            isImagesBuilt = false
            view.setNeedsLayout()
        }
    }
    
    @IBAction func buttonLeft(_ sender: UIButton) {
        if currentIndex > 0 {
            currentIndex -= 1
            scrollToIndex(currentIndex)
        }
    }

    @IBAction func buttonRight(_ sender: UIButton) {
        if currentIndex < images.count - 1 {
            currentIndex += 1
            scrollToIndex(currentIndex)
        }
    }
    
    private func scrollToIndex(_ index: Int) {
        let xOffset = CGFloat(index) * imageScrollView.frame.width
        imageScrollView.setContentOffset(CGPoint(x: xOffset, y: 0), animated: true)
        pageControl.currentPage = index
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let page = Int(scrollView.contentOffset.x / scrollView.frame.width)
        currentIndex = page
        pageControl.currentPage = page
    }
    
    // MARK: UIScrollViewDelegate
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let page = Int(round(scrollView.contentOffset.x / scrollView.frame.size.width))
        pageControl.currentPage = page
    }

    @objc private func addToCartTapped() {
        guard let productId, !isCartActionInFlight else { return }
        guard product?.available ?? true else {
            presentAvailabilityAlert()
            return
        }
        performCartAction {
            try await CartService.shared.addItem(dessertId: productId, qty: 1)
        }
    }

    @objc private func plusTapped() {
        guard let productId, !isCartActionInFlight else { return }
        guard product?.available ?? true else {
            presentAvailabilityAlert()
            return
        }
        let targetQty = quantity + 1
        performCartAction {
            try await CartService.shared.setQty(dessertId: productId, qty: targetQty)
        }
    }

    @objc private func minusTapped() {
        guard let productId, !isCartActionInFlight, quantity > 0 else { return }
        let targetQty = quantity - 1

        if targetQty == 0 {
            performCartAction {
                try await CartService.shared.removeItem(dessertId: productId)
            }
        } else {
            performCartAction {
                try await CartService.shared.setQty(dessertId: productId, qty: targetQty)
            }
        }
    }

    @objc private func cartDidChange(_ notification: Notification) {
        if let cart = notification.object as? CartDTO {
            applyCart(cart)
            return
        }
        loadCart()
    }

    @objc private func favoritesDidChange(_ notification: Notification) {
        guard !isFavoriteActionInFlight else { return }
        loadFavoriteState()
    }

    @objc private func favoriteTouchDown() {
        print("FAVORITE TOUCH DOWN")
    }

    @objc private func favoriteTapped() {
        print("FAVORITE TOUCH UP INSIDE. productId =", productId as Any, "old isFavorite =", isFavorite)

        guard let productId else {
            print("FAVORITE ERROR: productId is nil")
            return
        }

        guard !isFavoriteActionInFlight else {
            print("FAVORITE IGNORED: request already in flight")
            return
        }

        let previousValue = isFavorite
        let targetValue = !previousValue

        isFavorite = targetValue
        favoriteButton.transform = CGAffineTransform(scaleX: 1.18, y: 1.18)
        UIView.animate(withDuration: 0.15) {
            self.favoriteButton.transform = .identity
        }

        isFavoriteActionInFlight = true

        Task { [weak self] in
            guard let self else { return }
            do {
                if targetValue {
                    try await FavoritesService.shared.addFavorite(dessertId: productId)
                } else {
                    try await FavoritesService.shared.removeFavorite(dessertId: productId)
                }

                await MainActor.run {
                    self.isFavorite = targetValue
                    self.isFavoriteActionInFlight = false
                    NotificationCenter.default.post(name: .favoritesDidChange, object: nil)
                    print("FAVORITE SUCCESS. new isFavorite =", targetValue)
                }
            } catch {
                await MainActor.run {
                    self.isFavorite = previousValue
                    self.isFavoriteActionInFlight = false
                    print("FAVORITE SERVER ERROR:", error.localizedDescription)
                }
            }
        }
    }

    // MARK: API
    private func loadProduct() {
        guard let id = productId else { return }

        Task {
            do {
                let product = try await ProductDetailService.shared.fetchProduct(id: id)

                await MainActor.run {
                    self.updateUI(with: product)
                }

            } catch {
                print("Product detail error:", error.localizedDescription)
                // тут можно показать алерт
            }
        }
    }

    private func loadCart() {
        guard productId != nil else { return }

        Task { [weak self] in
            guard let self else { return }
            do {
                let cart = try await CartService.shared.getCart()
                await MainActor.run {
                    self.applyCart(cart)
                }
            } catch {
                print("Product detail cart error:", error.localizedDescription)
            }
        }
    }

    private func loadFavoriteState() {
        guard let productId else { return }

        Task { [weak self] in
            guard let self else { return }
            do {
                let favoriteIDs = try await FavoritesService.shared.fetchFavoriteIDs()
                await MainActor.run {
                    guard !self.isFavoriteActionInFlight else { return }
                    self.isFavorite = favoriteIDs.contains(productId)
                }
            } catch {
                print("Product detail favorite state error:", error.localizedDescription)
            }
        }
    }

    private func performCartAction(_ action: @escaping () async throws -> CartDTO) {
        isCartActionInFlight = true

        Task { [weak self] in
            guard let self else { return }
            do {
                let cart = try await action()
                await MainActor.run {
                    self.applyCart(cart)
                }
            } catch {
                print("Product detail cart action error:", error.localizedDescription)
            }
            await MainActor.run {
                self.isCartActionInFlight = false
            }
        }
    }

    private func applyCart(_ cart: CartDTO) {
        guard let productId else { return }
        quantity = cart.items.first(where: { $0.dessertId == productId })?.qty ?? 0
    }

    private func updateCartUI() {
        let isAvailable = product?.available ?? true
        let inCart = quantity > 0
        addToCartButton.isHidden = inCart
        qtyBackgroundView.isHidden = !inCart
        priceBottomLabel.isHidden = !inCart && isAvailable
        qtyLabel.text = "\(max(quantity, 1))"
        priceBottomLabel.text = "\(displayPrice()) ₽"

        addToCartTopConstraint?.isActive = inCart
        addToCartCenterYConstraint?.isActive = !inCart
        addToCartLeadingConstraint?.isActive = !inCart
        addToCartTrailingConstraint?.isActive = true
        addToCartWidthConstraint?.isActive = inCart

        if isAvailable {
            addToCartButton.setTitle("В корзину", for: .normal)
            addToCartButton.backgroundColor = .systemBlue
        } else {
            addToCartButton.setTitle("Недоступно", for: .normal)
            addToCartButton.backgroundColor = .systemGray3
        }

        setControlsEnabled(!isCartActionInFlight && isAvailable)
        minusButton.isEnabled = !isCartActionInFlight && quantity > 0
    }

    private func displayPrice() -> Int {
        guard let product else { return 0 }
        return Int(product.price) * max(quantity, 1)
    }

    private func setControlsEnabled(_ enabled: Bool) {
        addToCartButton.isEnabled = enabled
        plusButton.isEnabled = enabled
        minusButton.isEnabled = enabled
    }

    private func updateFavoriteUI() {
        let imageName = isFavorite ? "heart.fill" : "heart"
        favoriteButton.setImage(UIImage(systemName: imageName), for: .normal)
        favoriteButton.isEnabled = !isFavoriteActionInFlight
        favoriteButton.alpha = isFavoriteActionInFlight ? 0.65 : 1
        favoriteButton.accessibilityLabel = isFavorite ? "Удалить из избранного" : "Добавить в избранное"
        view.bringSubviewToFront(favoriteButton)
    }

    private func presentAvailabilityAlert() {
        let alert = UIAlertController(
            title: "Товар недоступен",
            message: "Эту позицию временно нельзя добавить в заказ.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Ок", style: .default))
        present(alert, animated: true)
    }
}
