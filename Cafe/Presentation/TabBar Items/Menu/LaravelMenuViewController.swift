import UIKit
import Supabase
import Foundation

struct MenuItem {
    let id: Int
    let name: String
    let price: Int
    let imageName: String
    let imageURLString: String?
    let category: String?
    var qty: Int

    init(
        id: Int,
        name: String,
        price: Int,
        imageName: String,
        imageURLString: String? = nil,
        category: String? = nil,
        qty: Int = 0
    ) {
        self.id = id
        self.name = name
        self.price = price
        self.imageName = imageName
        self.imageURLString = imageURLString
        self.category = category
        self.qty = qty
    }
}

class LaravelMenuViewController: UIViewController {
    
    private var collectionView: UICollectionView!
    
    private let sectionInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
    private let itemSpacing: CGFloat = 12
    private let lineSpacing: CGFloat = 12
    private let searchTextField = UITextField()
    private let searchButton = UIButton()
    private let categoryScrollView = UIScrollView()
    private let categoryStackView = UIStackView()
    private var categoryButtons: [UIButton] = []
    private var selectedCategory: String?
    private var allItems: [MenuItem] = []
    private var inFlightProductIDs = Set<Int>()
    // Тут будут данные меню (пока мок)
    var items: [MenuItem] = [
       // MenuItem(name: "Капучино", price: 180, imageName: "cappuccino"),
       // MenuItem(name: "Латте", price: 190, imageName: "latte"),
//        MenuItem(name: "Эклер", price: 240, imageName: "eclair"),
//        MenuItem(name: "Чизкейк", price: 320, imageName: "cheesecake")
    ]
    private func setupHideKeyboardOnTap() {
           let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard(_:)))
           tapGesture.cancelsTouchesInView = false // важно: позволяет тапать сквозь gesture recognizer
           view.addGestureRecognizer(tapGesture)
       }
    
    @objc private func dismissKeyboard(_ gesture: UITapGestureRecognizer) {
        view.endEditing(true)
       }
    
    private func mapMenuItems(products: [Product], qtyById: [Int: Int]) -> [MenuItem] {
        var seenIDs = Set<Int>()
        return products.compactMap { product in
            guard seenIDs.insert(product.id).inserted else { return nil }
            return MenuItem(
                id: product.id,
                name: product.name,
                price: Int(product.price),
                imageName: "фото3",
                imageURLString: product.photos?.first,
                category: product.category,
                qty: qtyById[product.id] ?? 0
            )
        }
    }
    
    private func rebuildCategoryFilters() {
        for view in categoryStackView.arrangedSubviews {
            categoryStackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        categoryButtons.removeAll()

        var seen = Set<String>()
        let categories = allItems.compactMap { item -> String? in
            guard let raw = item.category?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !raw.isEmpty else { return nil }
            let key = raw.lowercased()
            guard seen.insert(key).inserted else { return nil }
            return raw
        }.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }

        if let selectedCategory,
           !categories.contains(where: { $0.caseInsensitiveCompare(selectedCategory) == .orderedSame }) {
            self.selectedCategory = nil
        }

        addCategoryButton(title: "Все", categoryKey: "__all__")
        for category in categories {
            addCategoryButton(title: category, categoryKey: category)
        }
        updateCategoryButtonsAppearance()
    }

    private func addCategoryButton(title: String, categoryKey: String) {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        button.contentEdgeInsets = UIEdgeInsets(top: 7, left: 12, bottom: 7, right: 12)
        button.layer.cornerRadius = 14
        button.layer.borderWidth = 1
        button.accessibilityIdentifier = categoryKey
        button.addTarget(self, action: #selector(categoryTapped(_:)), for: .touchUpInside)
        categoryStackView.addArrangedSubview(button)
        categoryButtons.append(button)
    }

    private func updateCategoryButtonsAppearance() {
        for button in categoryButtons {
            let categoryKey = button.accessibilityIdentifier ?? "__all__"
            let isSelected: Bool

            if categoryKey == "__all__" {
                isSelected = selectedCategory == nil
            } else {
                isSelected = categoryKey.caseInsensitiveCompare(selectedCategory ?? "") == .orderedSame
            }

            button.backgroundColor = isSelected ? .systemBlue : .systemGray6
            button.setTitleColor(isSelected ? .white : .label, for: .normal)
            button.layer.borderColor = (isSelected ? UIColor.systemBlue : UIColor.systemGray4).cgColor
        }
    }

    private func applyCurrentFilters() {
        if let selectedCategory {
            items = allItems.filter { ($0.category ?? "").caseInsensitiveCompare(selectedCategory) == .orderedSame }
        } else {
            items = allItems
        }
        updateCategoryButtonsAppearance()
        collectionView.reloadData()
    }
    
    private func applyCart(_ cart: CartDTO) {
        var qtyById: [Int: Int] = [:]
        for cartItem in cart.items {
            qtyById[cartItem.dessertId] = cartItem.qty
        }
        for i in 0..<allItems.count {
            allItems[i].qty = qtyById[allItems[i].id] ?? 0
        }
        applyCurrentFilters()
    }
    
    private func setProductLoading(_ productId: Int, isLoading: Bool) {
        if isLoading {
            inFlightProductIDs.insert(productId)
        } else {
            inFlightProductIDs.remove(productId)
        }
        let indexPaths = items.enumerated().compactMap { index, item -> IndexPath? in
            item.id == productId ? IndexPath(item: index, section: 0) : nil
        }
        guard !indexPaths.isEmpty else { return }
        collectionView.reloadItems(at: indexPaths)
    }
    
    private func performCartAction(
        for productId: Int,
        actionName: String,
        action: @escaping () async throws -> CartDTO
    ) {
        guard !inFlightProductIDs.contains(productId) else { return }
        setProductLoading(productId, isLoading: true)
        
        Task { [weak self] in
            guard let self else { return }
            do {
                let cart = try await action()
                await MainActor.run {
                    self.applyCart(cart)
                }
            } catch {
                print("\(actionName) error:", error.localizedDescription)
            }
            await MainActor.run {
                self.setProductLoading(productId, isLoading: false)
            }
        }
    }
    
    private func handleAddTapped(productId: Int) {
        performCartAction(for: productId, actionName: "addToCart") {
            try await CartService.shared.addItem(dessertId: productId, qty: 1)
        }
    }
    
    private func handlePlusTapped(productId: Int) {
        let currentQty = allItems.first(where: { $0.id == productId })?.qty ?? 0
        let targetQty = currentQty + 1
        performCartAction(for: productId, actionName: "plusTapped") {
            try await CartService.shared.setQty(dessertId: productId, qty: targetQty)
        }
    }
    
    private func handleMinusTapped(productId: Int) {
        let currentQty = allItems.first(where: { $0.id == productId })?.qty ?? 0
        let targetQty = currentQty - 1
        
        guard targetQty >= 0 else { return }
        
        if targetQty == 0 {
            performCartAction(for: productId, actionName: "minusTapped") {
                try await CartService.shared.removeItem(dessertId: productId)
            }
        } else {
            performCartAction(for: productId, actionName: "minusTapped") {
                try await CartService.shared.setQty(dessertId: productId, qty: targetQty)
            }
        }
    }
    
    private func loadData() {
        Task {
            do {
                async let productsTask = ProductsService.shared.fetchProducts()
                async let cartTask = CartService.shared.getCart()

                let products = try await productsTask
                let cartResponse = try await cartTask

                // qtyById: dessert_id -> qty
                var qtyById: [Int: Int] = [:]
                for cartItem in cartResponse.items {
                    qtyById[cartItem.dessertId] = cartItem.qty
                }

                let mapped = self.mapMenuItems(products: products, qtyById: qtyById)

                await MainActor.run {
                    self.allItems = mapped
                    self.rebuildCategoryFilters()
                    self.applyCurrentFilters()
                }

            } catch {
                print("Load menu/cart error:", error.localizedDescription)
            }
        }
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Меню"
        view.backgroundColor = .white
        
        // Устанавливаем иконку для Tab Bar
        let forkSpoonImage = UIImage(systemName: "fork.knife") // SF Symbol "fork.knife"
        tabBarItem = UITabBarItem(title: "Меню", image: forkSpoonImage, selectedImage: forkSpoonImage)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(cartDidChange(_:)),
                                               name: .cartDidChange,
                                               object: nil)
        setupHideKeyboardOnTap()
        setupCollection()
        loadData()
        
    }
    
    @objc private func cartDidChange(_ notification: Notification) {
        if let cart = notification.object as? CartDTO {
            applyCart(cart)
            return
        }
        
        Task { [weak self] in
            guard let self else { return }
            do {
                let cart = try await CartService.shared.getCart()
                await MainActor.run {
                    self.applyCart(cart)
                }
            } catch {
                print("cartDidChange reload error:", error.localizedDescription)
            }
        }
    }

    @objc private func categoryTapped(_ sender: UIButton) {
        let categoryKey = sender.accessibilityIdentifier ?? "__all__"
        selectedCategory = (categoryKey == "__all__") ? nil : categoryKey
        applyCurrentFilters()
    }

    @objc private func searchButtonTapped() {
        view.endEditing(true)
        let query = (searchTextField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !query.isEmpty else {
            loadData()
            return
        }
        
        Task {
            do {
                async let productsTask = ProductsService.shared.searchProducts(body: SearchDTO(query: query))
                async let cartTask = CartService.shared.getCart()

                let products = try await productsTask
                let cart = try await cartTask

                var qtyById: [Int: Int] = [:]
                for cartItem in cart.items {
                    qtyById[cartItem.dessertId] = cartItem.qty
                }
                let mapped = self.mapMenuItems(products: products, qtyById: qtyById)

                await MainActor.run {
                    self.allItems = mapped
                    self.rebuildCategoryFilters()
                    self.applyCurrentFilters()
                }

            } catch {
                print("Ошибка поиска: \(error)")
            }
        }
    }
    private func setupCollection() {
    // Настраиваем текстовое поле
    searchTextField.placeholder = "Введите запрос..."
    searchTextField.borderStyle = .roundedRect
    searchTextField.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(searchTextField)
    
    // Настраиваем кнопку
    searchButton.setTitle("Поиск", for: .normal)
    searchButton.backgroundColor = .systemBlue
    searchButton.setTitleColor(.white, for: .normal)
    searchButton.layer.cornerRadius = 10
    searchButton.addTarget(self, action: #selector(searchButtonTapped), for: .touchUpInside)
    searchButton.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(searchButton)
    
    categoryScrollView.showsHorizontalScrollIndicator = false
    categoryScrollView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(categoryScrollView)
    
    categoryStackView.axis = .horizontal
    categoryStackView.alignment = .center
    categoryStackView.spacing = 8
    categoryStackView.translatesAutoresizingMaskIntoConstraints = false
    categoryScrollView.addSubview(categoryStackView)

    // CollectionView
    let layout = UICollectionViewFlowLayout()
    layout.minimumInteritemSpacing = itemSpacing
    layout.minimumLineSpacing = lineSpacing
    layout.sectionInset = sectionInsets

    collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
    collectionView.backgroundColor = .white
    collectionView.dataSource = self
    collectionView.delegate = self

    collectionView.register(LaravelMenuCell.self, forCellWithReuseIdentifier: "LaravelMenuCell")

    view.addSubview(collectionView)
    collectionView.translatesAutoresizingMaskIntoConstraints = false

    // 🔥 ИСПРАВЛЕННЫЕ КОНСТРЕЙНТЫ
    NSLayoutConstraint.activate([
        // Поле поиска + кнопка в одной строке
        searchTextField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
        searchTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
        searchTextField.trailingAnchor.constraint(equalTo: searchButton.leadingAnchor, constant: -12),
        searchTextField.heightAnchor.constraint(equalToConstant: 44),
        
        searchButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
        searchButton.centerYAnchor.constraint(equalTo: searchTextField.centerYAnchor),
        searchButton.widthAnchor.constraint(equalToConstant: 96),
        searchButton.heightAnchor.constraint(equalToConstant: 44),
        
        categoryScrollView.topAnchor.constraint(equalTo: searchTextField.bottomAnchor, constant: 12),
        categoryScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
        categoryScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        categoryScrollView.heightAnchor.constraint(equalToConstant: 36),
        
        categoryStackView.leadingAnchor.constraint(equalTo: categoryScrollView.contentLayoutGuide.leadingAnchor, constant: 20),
        categoryStackView.trailingAnchor.constraint(equalTo: categoryScrollView.contentLayoutGuide.trailingAnchor, constant: -20),
        categoryStackView.topAnchor.constraint(equalTo: categoryScrollView.contentLayoutGuide.topAnchor),
        categoryStackView.bottomAnchor.constraint(equalTo: categoryScrollView.contentLayoutGuide.bottomAnchor),
        categoryStackView.heightAnchor.constraint(equalTo: categoryScrollView.frameLayoutGuide.heightAnchor),
        
        // CollectionView - ПОД строкой поиска
        collectionView.topAnchor.constraint(equalTo: categoryScrollView.bottomAnchor, constant: 16),
        collectionView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
        collectionView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
        collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
    ])
    rebuildCategoryFilters()
}
}

extension LaravelMenuViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {

        let columns: CGFloat = 2

        let width = collectionView.bounds.width
        let insets = sectionInsets.left + sectionInsets.right
        let totalSpacing = (columns - 1) * itemSpacing
        let itemWidth = floor((width - insets - totalSpacing) / columns)

        // высоту подгони под себя (чуть выше, чтобы текст+кнопки не давили картинку)
        let itemHeight = itemWidth * 1.1

        return CGSize(width: itemWidth, height: itemHeight)
    }
}

extension LaravelMenuViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        return items.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "LaravelMenuCell", for: indexPath) as! LaravelMenuCell
        let item = items[indexPath.row]
        cell.configure(item: item, isLoading: inFlightProductIDs.contains(item.id))
        cell.onAddTapped = { [weak self] productId in
            self?.handleAddTapped(productId: productId)
        }
        cell.onPlusTapped = { [weak self] productId in
            self?.handlePlusTapped(productId: productId)
        }
        cell.onMinusTapped = { [weak self] productId in
            self?.handleMinusTapped(productId: productId)
        }
        cell.parentViewController = self // если self — это UICollectionViewController / UIViewController
        return cell
    }
}
