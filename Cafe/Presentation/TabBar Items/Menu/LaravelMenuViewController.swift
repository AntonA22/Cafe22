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
    let isAvailable: Bool
    var isFavorite: Bool
    let calories: Int?
    var qty: Int

    init(
        id: Int,
        name: String,
        price: Int,
        imageName: String,
        imageURLString: String? = nil,
        category: String? = nil,
        isAvailable: Bool = true,
        isFavorite: Bool = false,
        calories: Int? = nil,
        qty: Int = 0
    ) {
        self.id = id
        self.name = name
        self.price = price
        self.imageName = imageName
        self.imageURLString = imageURLString
        self.category = category
        self.isAvailable = isAvailable
        self.isFavorite = isFavorite
        self.calories = calories
        self.qty = qty
    }
}

class LaravelMenuViewController: UIViewController {
    private enum FilterOption: CaseIterable, Equatable {
        case all
        case inCartOnly

        var title: String {
            switch self {
            case .all:
                return "Все позиции"
            case .inCartOnly:
                return "Только в корзине"
            }
        }

        var buttonTitle: String {
            switch self {
            case .all:
                return "Фильтр"
            case .inCartOnly:
                return "В корзине"
            }
        }
    }

    private struct PriceRangeFilter: Equatable {
        let minimumPrice: Int?
        let maximumPrice: Int?

        var buttonTitle: String {
            switch (minimumPrice, maximumPrice) {
            case let (min?, max?):
                return "\(min)-\(max) ₽"
            case let (min?, nil):
                return "от \(min) ₽"
            case let (nil, max?):
                return "до \(max) ₽"
            case (nil, nil):
                return "Фильтр"
            }
        }
    }

    private enum CalorieFilterOption: CaseIterable, Equatable {
        case all
        case upTo200
        case from200To400
        case over400

        var title: String {
            switch self {
            case .all:
                return "Все по калорийности"
            case .upTo200:
                return "До 200 ккал"
            case .from200To400:
                return "200-400 ккал"
            case .over400:
                return "400+ ккал"
            }
        }

        var buttonTitle: String {
            switch self {
            case .all:
                return "Калории"
            case .upTo200:
                return "До 200 ккал"
            case .from200To400:
                return "200-400 ккал"
            case .over400:
                return "400+ ккал"
            }
        }
    }

    private enum SortOption: CaseIterable, Equatable {
        case `default`
        case nameAscending
        case priceAscending
        case priceDescending
        case newestFirst
        case caloriesAscending
        case caloriesDescending

        var title: String {
            switch self {
            case .default:
                return "По умолчанию"
            case .nameAscending:
                return "По названию"
            case .priceAscending:
                return "Сначала дешевле"
            case .priceDescending:
                return "Сначала дороже"
            case .newestFirst:
                return "Сначала новинки"
            case .caloriesAscending:
                return "Меньше калорий"
            case .caloriesDescending:
                return "Больше калорий"
            }
        }

        var buttonTitle: String {
            switch self {
            case .default:
                return "Сортировка"
            case .nameAscending:
                return "Название"
            case .priceAscending:
                return "Дешевле"
            case .priceDescending:
                return "Дороже"
            case .newestFirst:
                return "Новинки"
            case .caloriesAscending:
                return "Ккал вниз"
            case .caloriesDescending:
                return "Ккал вверх"
            }
        }
    }
    
    private var collectionView: UICollectionView!
    
    private let sectionInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
    private let itemSpacing: CGFloat = 12
    private let lineSpacing: CGFloat = 12
    private let searchTextField = UITextField()
    private let searchButton = UIButton()
    private let controlsStackView = UIStackView()
    private let filterButton = UIButton(type: .system)
    private let sortButton = UIButton(type: .system)
    private let categoryScrollView = UIScrollView()
    private let categoryStackView = UIStackView()
    private var categoryButtons: [UIButton] = []
    private var selectedCategory: String?
    private var selectedFilter: FilterOption = .all
    private var selectedSort: SortOption = .default
    private var selectedPriceRange: PriceRangeFilter?
    private var selectedCalorieFilter: CalorieFilterOption = .all
    private var allItems: [MenuItem] = []
    private var inFlightProductIDs = Set<Int>()
    private var isShowingFavoriteDataset = false
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
    
    private func mapMenuItems(
        products: [Product],
        qtyById: [Int: Int],
        favoriteIDs: Set<Int> = []
    ) -> [MenuItem] {
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
                isAvailable: product.available ?? true,
                isFavorite: product.isFavorite ?? favoriteIDs.contains(product.id),
                calories: product.calories,
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
        addCategoryButton(title: "Избранное", categoryKey: "__favorites__")
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
                isSelected = selectedCategory == nil && !isShowingFavoriteDataset
            } else if categoryKey == "__favorites__" {
                isSelected = isShowingFavoriteDataset
            } else {
                isSelected = !isShowingFavoriteDataset && categoryKey.caseInsensitiveCompare(selectedCategory ?? "") == .orderedSame
            }

            button.backgroundColor = isSelected ? .systemBlue : .systemGray6
            button.setTitleColor(isSelected ? .white : .label, for: .normal)
            button.layer.borderColor = (isSelected ? UIColor.systemBlue : UIColor.systemGray4).cgColor
        }
    }

    private func applyCurrentFilters() {
        var filteredItems = allItems

        if isShowingFavoriteDataset {
            filteredItems = filteredItems.filter { $0.isFavorite }
        }

        if let selectedCategory {
            filteredItems = filteredItems.filter {
                ($0.category ?? "").caseInsensitiveCompare(selectedCategory) == .orderedSame
            }
        }

        switch selectedFilter {
        case .all:
            break
        case .inCartOnly:
            filteredItems = filteredItems.filter { $0.qty > 0 }
        }

        if let selectedPriceRange {
            filteredItems = filteredItems.filter { item in
                let matchesMinimum = selectedPriceRange.minimumPrice.map { item.price >= $0 } ?? true
                let matchesMaximum = selectedPriceRange.maximumPrice.map { item.price <= $0 } ?? true
                return matchesMinimum && matchesMaximum
            }
        }

        switch selectedCalorieFilter {
        case .all:
            break
        case .upTo200:
            filteredItems = filteredItems.filter { ($0.calories ?? Int.max) <= 200 }
        case .from200To400:
            filteredItems = filteredItems.filter {
                guard let calories = $0.calories else { return false }
                return (200...400).contains(calories)
            }
        case .over400:
            filteredItems = filteredItems.filter { ($0.calories ?? Int.min) > 400 }
        }

        switch selectedSort {
        case .default:
            break
        case .nameAscending:
            filteredItems.sort {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
        case .priceAscending:
            filteredItems.sort { $0.price < $1.price }
        case .priceDescending:
            filteredItems.sort { $0.price > $1.price }
        case .newestFirst:
            filteredItems.sort { $0.id > $1.id }
        case .caloriesAscending:
            filteredItems.sort { ($0.calories ?? Int.max) < ($1.calories ?? Int.max) }
        case .caloriesDescending:
            filteredItems.sort { ($0.calories ?? Int.min) > ($1.calories ?? Int.min) }
        }

        items = filteredItems
        updateCategoryButtonsAppearance()
        updateMenuButtons()
        collectionView.reloadData()
    }
    
    private func applyCart(_ cart: CartDTO) {
        var qtyById: [Int: Int] = [:]
        for cartItem in cart.items {
            qtyById[cartItem.dessertId, default: 0] += cartItem.qty
        }
        for i in 0..<allItems.count {
            allItems[i].qty = qtyById[allItems[i].id] ?? 0
        }

        // Обновляем только ячейки, у которых изменилось количество
        var changedIndexPaths: [IndexPath] = []
        for i in 0..<items.count {
            let newQty = qtyById[items[i].id] ?? 0
            if items[i].qty != newQty {
                items[i].qty = newQty
                changedIndexPaths.append(IndexPath(item: i, section: 0))
            }
        }
        if !changedIndexPaths.isEmpty {
            collectionView.reloadItems(at: changedIndexPaths)
        }
    }

    private func applyFavoriteIDs(_ favoriteIDs: Set<Int>) {
        for i in 0..<allItems.count {
            allItems[i].isFavorite = favoriteIDs.contains(allItems[i].id)
        }
        for i in 0..<items.count {
            items[i].isFavorite = favoriteIDs.contains(items[i].id)
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
        guard allItems.first(where: { $0.id == productId })?.isAvailable != false else { return }
        performCartAction(for: productId, actionName: "addToCart") {
            try await CartService.shared.addItem(dessertId: productId, qty: 1)
        }
    }

    private func handlePlusTapped(productId: Int) {
        guard allItems.first(where: { $0.id == productId })?.isAvailable != false else { return }
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
        isShowingFavoriteDataset = false
        Task {
            do {
                async let productsTask = ProductsService.shared.fetchProducts()
                async let cartTask = try? CartService.shared.getCart()

                let products = try await productsTask
                let cartResponse = await cartTask
                let favoriteIDs = (try? await FavoritesService.shared.fetchFavoriteIDs()) ?? []

                // qtyById: dessert_id -> qty
                var qtyById: [Int: Int] = [:]
                for cartItem in cartResponse?.items ?? [] {
                    qtyById[cartItem.dessertId, default: 0] += cartItem.qty
                }

                let mapped = self.mapMenuItems(products: products, qtyById: qtyById, favoriteIDs: favoriteIDs)

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

    private func loadFavoriteProducts(query: String? = nil) {
        isShowingFavoriteDataset = true
        Task {
            do {
                async let productsTask: [Product] = {
                    if let query, !query.isEmpty {
                        return try await FavoritesService.shared.searchFavorites(query: query)
                    }
                    return try await FavoritesService.shared.fetchFavorites()
                }()
                async let cartTask = try? CartService.shared.getCart()

                let products = try await productsTask
                let cartResponse = await cartTask

                var qtyById: [Int: Int] = [:]
                for cartItem in cartResponse?.items ?? [] {
                    qtyById[cartItem.dessertId, default: 0] += cartItem.qty
                }

                let mapped = self.mapMenuItems(
                    products: products,
                    qtyById: qtyById,
                    favoriteIDs: Set(products.map(\.id))
                )

                await MainActor.run {
                    self.allItems = mapped
                    self.rebuildCategoryFilters()
                    self.applyCurrentFilters()
                }

            } catch {
                print("Load favorite products error:", error.localizedDescription)
            }
        }
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        useRussianBackButtonTitle()
        title = "Меню"
        view.backgroundColor = .white
        
        // Устанавливаем иконку для Tab Bar
        let forkSpoonImage = UIImage(systemName: "fork.knife") // SF Symbol "fork.knife"
        tabBarItem = UITabBarItem(title: "Меню", image: forkSpoonImage, selectedImage: forkSpoonImage)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(cartDidChange(_:)),
                                               name: .cartDidChange,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(favoritesDidChange(_:)),
                                               name: .favoritesDidChange,
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

    @objc private func favoritesDidChange(_ notification: Notification) {
        Task { [weak self] in
            guard let self else { return }
            do {
                let favoriteIDs = try await FavoritesService.shared.fetchFavoriteIDs()
                await MainActor.run {
                    self.applyFavoriteIDs(favoriteIDs)
                }
            } catch {
                print("favoritesDidChange reload error:", error.localizedDescription)
            }
        }
    }

    @objc private func categoryTapped(_ sender: UIButton) {
        let categoryKey = sender.accessibilityIdentifier ?? "__all__"
        if categoryKey == "__favorites__" {
            selectedCategory = nil
            loadFavoriteProducts()
            return
        }

        selectedCategory = (categoryKey == "__all__") ? nil : categoryKey
        if isShowingFavoriteDataset {
            loadData()
        } else {
            applyCurrentFilters()
        }
    }

    @objc private func searchButtonTapped() {
        view.endEditing(true)
        let query = (searchTextField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        
        if isShowingFavoriteDataset {
            loadFavoriteProducts(query: query.isEmpty ? nil : query)
            return
        }

        guard !query.isEmpty else {
            loadData()
            return
        }
        
        Task {
            do {
                async let productsTask = ProductsService.shared.searchProducts(body: SearchDTO(query: query))
                async let cartTask = try? CartService.shared.getCart()

                let products = try await productsTask
                let cart = await cartTask

                var qtyById: [Int: Int] = [:]
                for cartItem in cart?.items ?? [] {
                    qtyById[cartItem.dessertId, default: 0] += cartItem.qty
                }
                let favoriteIDs = (try? await FavoritesService.shared.fetchFavoriteIDs()) ?? []
                let mapped = self.mapMenuItems(products: products, qtyById: qtyById, favoriteIDs: favoriteIDs)

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

    private func updateMenuButtons() {
        configureMenuButton(
            filterButton,
            title: currentFilterButtonTitle(),
            imageName: "line.3.horizontal.decrease.circle",
            isActive: activeFiltersCount() > 0
        )
        configureMenuButton(
            sortButton,
            title: selectedSort.buttonTitle,
            imageName: "arrow.up.arrow.down.circle",
            isActive: selectedSort != .default
        )
        filterButton.menu = makeFilterMenu()
        sortButton.menu = makeSortMenu()
    }

    private func currentFilterButtonTitle() -> String {
        let activeCount = activeFiltersCount()

        if activeCount > 1 {
            return "\(activeCount) \(filtersWord(for: activeCount))"
        }
        if let selectedPriceRange {
            return selectedPriceRange.buttonTitle
        }
        if selectedCalorieFilter != .all {
            return selectedCalorieFilter.buttonTitle
        }
        return selectedFilter.buttonTitle
    }

    private func filtersWord(for count: Int) -> String {
        let remainder100 = count % 100
        let remainder10 = count % 10

        if (11...14).contains(remainder100) {
            return "фильтров"
        }
        switch remainder10 {
        case 1:
            return "фильтр"
        case 2, 3, 4:
            return "фильтра"
        default:
            return "фильтров"
        }
    }

    private func activeFiltersCount() -> Int {
        var count = 0
        if selectedFilter != .all { count += 1 }
        if selectedPriceRange != nil { count += 1 }
        if selectedCalorieFilter != .all { count += 1 }
        return count
    }

    private func handleFilterSelection(_ option: FilterOption) {
        selectedFilter = option

        switch option {
        case .all, .inCartOnly:
            if isShowingFavoriteDataset {
                loadData()
            } else {
                applyCurrentFilters()
            }
        }
    }

    private func configureMenuButton(
        _ button: UIButton,
        title: String,
        imageName: String,
        isActive: Bool
    ) {
        var configuration = UIButton.Configuration.plain()
        configuration.title = title
        configuration.image = UIImage(systemName: imageName)
        configuration.imagePlacement = .leading
        configuration.imagePadding = 6
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 7, leading: 10, bottom: 7, trailing: 10)
        button.configuration = configuration
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        button.layer.cornerRadius = 10
        button.layer.borderWidth = 1
        button.layer.borderColor = (isActive ? UIColor.systemBlue : UIColor.systemGray4).cgColor
        button.backgroundColor = isActive ? UIColor.systemBlue.withAlphaComponent(0.12) : .systemGray6
        button.tintColor = isActive ? .systemBlue : .label
    }

    private func makeFilterMenu() -> UIMenu {
        let quickFilterActions = FilterOption.allCases.map { option in
            UIAction(
                title: option.title,
                state: option == selectedFilter ? .on : .off
            ) { [weak self] _ in
                self?.handleFilterSelection(option)
            }
        }

        var children: [UIMenuElement] = [
            UIMenu(title: "", options: .displayInline, children: quickFilterActions),
            makeCalorieFilterMenu(),
            UIAction(title: selectedPriceRange == nil ? "Задать диапазон цен" : "Изменить диапазон цен") { [weak self] _ in
                self?.presentPriceRangeAlert()
            }
        ]

        if selectedPriceRange != nil {
            children.append(
                UIAction(title: "Сбросить диапазон цен", attributes: .destructive) { [weak self] _ in
                    self?.selectedPriceRange = nil
                    self?.applyCurrentFilters()
                }
            )
        }

        if activeFiltersCount() > 0 {
            children.append(
                UIAction(title: "Сбросить все фильтры", attributes: .destructive) { [weak self] _ in
                    guard let self else { return }
                    self.selectedFilter = .all
                    self.selectedPriceRange = nil
                    self.selectedCalorieFilter = .all
                    if self.isShowingFavoriteDataset {
                        self.loadData()
                    } else {
                        self.applyCurrentFilters()
                    }
                }
            )
        }

        return UIMenu(
            title: "Фильтрация",
            children: children
        )
    }

    private func makeCalorieFilterMenu() -> UIMenu {
        let actions = CalorieFilterOption.allCases.map { option in
            UIAction(
                title: option.title,
                state: option == selectedCalorieFilter ? .on : .off
            ) { [weak self] _ in
                self?.selectedCalorieFilter = option
                self?.applyCurrentFilters()
            }
        }

        return UIMenu(
            title: "Калорийность",
            options: .singleSelection,
            children: actions
        )
    }

    private func makeSortMenu() -> UIMenu {
        let actions = SortOption.allCases.map { option in
            UIAction(
                title: option.title,
                state: option == selectedSort ? .on : .off
            ) { [weak self] _ in
                self?.selectedSort = option
                self?.applyCurrentFilters()
            }
        }

        return UIMenu(
            title: "Сортировка",
            options: .singleSelection,
            children: actions
        )
    }

    private func presentPriceRangeAlert() {
        let alert = UIAlertController(
            title: "Диапазон цен",
            message: "Укажите минимальную и максимальную цену",
            preferredStyle: .alert
        )

        alert.addTextField { [selectedPriceRange] textField in
            textField.placeholder = "Цена от"
            textField.keyboardType = .numberPad
            textField.text = selectedPriceRange?.minimumPrice.map(String.init)
        }

        alert.addTextField { [selectedPriceRange] textField in
            textField.placeholder = "Цена до"
            textField.keyboardType = .numberPad
            textField.text = selectedPriceRange?.maximumPrice.map(String.init)
        }

        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        alert.addAction(UIAlertAction(title: "Сбросить", style: .destructive) { [weak self] _ in
            self?.selectedPriceRange = nil
            self?.applyCurrentFilters()
        })
        alert.addAction(UIAlertAction(title: "Применить", style: .default) { [weak self, weak alert] _ in
            guard let self, let alert else { return }

            let minimumText = alert.textFields?[0].text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let maximumText = alert.textFields?[1].text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

            var minimumPrice = Int(minimumText)
            var maximumPrice = Int(maximumText)

            if let min = minimumPrice, let max = maximumPrice, min > max {
                minimumPrice = max
                maximumPrice = min
            }

            if minimumPrice == nil, maximumPrice == nil {
                self.selectedPriceRange = nil
            } else {
                self.selectedPriceRange = PriceRangeFilter(
                    minimumPrice: minimumPrice,
                    maximumPrice: maximumPrice
                )
            }

            self.applyCurrentFilters()
        })

        present(alert, animated: true)
    }

    private func setupCollection() {
        searchTextField.placeholder = "Введите запрос..."
        searchTextField.borderStyle = .roundedRect
        searchTextField.delegate = self
        searchTextField.returnKeyType = .search
        searchTextField.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchTextField)
        
        searchButton.setTitle("Поиск", for: .normal)
        searchButton.backgroundColor = .systemBlue
        searchButton.setTitleColor(.white, for: .normal)
        searchButton.layer.cornerRadius = 10
        searchButton.addTarget(self, action: #selector(searchButtonTapped), for: .touchUpInside)
        searchButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchButton)

        controlsStackView.axis = .horizontal
        controlsStackView.spacing = 8
        controlsStackView.distribution = .fillEqually
        controlsStackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(controlsStackView)

        filterButton.showsMenuAsPrimaryAction = true
        controlsStackView.addArrangedSubview(filterButton)

        sortButton.showsMenuAsPrimaryAction = true
        controlsStackView.addArrangedSubview(sortButton)
        updateMenuButtons()
        
        categoryScrollView.showsHorizontalScrollIndicator = false
        categoryScrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(categoryScrollView)
        
        categoryStackView.axis = .horizontal
        categoryStackView.alignment = .center
        categoryStackView.spacing = 8
        categoryStackView.translatesAutoresizingMaskIntoConstraints = false
        categoryScrollView.addSubview(categoryStackView)

        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = itemSpacing
        layout.minimumLineSpacing = lineSpacing
        layout.sectionInset = sectionInsets

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .white
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(LaravelMenuCell.self, forCellWithReuseIdentifier: "LaravelMenuCell")
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            searchTextField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            searchTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            searchTextField.trailingAnchor.constraint(equalTo: searchButton.leadingAnchor, constant: -12),
            searchTextField.heightAnchor.constraint(equalToConstant: 44),
            
            searchButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            searchButton.centerYAnchor.constraint(equalTo: searchTextField.centerYAnchor),
            searchButton.widthAnchor.constraint(equalToConstant: 96),
            searchButton.heightAnchor.constraint(equalToConstant: 44),

            controlsStackView.topAnchor.constraint(equalTo: searchTextField.bottomAnchor, constant: 12),
            controlsStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            controlsStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            controlsStackView.heightAnchor.constraint(equalToConstant: 36),
            
            categoryScrollView.topAnchor.constraint(equalTo: controlsStackView.bottomAnchor, constant: 12),
            categoryScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            categoryScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            categoryScrollView.heightAnchor.constraint(equalToConstant: 36),
            
            categoryStackView.leadingAnchor.constraint(equalTo: categoryScrollView.contentLayoutGuide.leadingAnchor, constant: 20),
            categoryStackView.trailingAnchor.constraint(equalTo: categoryScrollView.contentLayoutGuide.trailingAnchor, constant: -20),
            categoryStackView.topAnchor.constraint(equalTo: categoryScrollView.contentLayoutGuide.topAnchor),
            categoryStackView.bottomAnchor.constraint(equalTo: categoryScrollView.contentLayoutGuide.bottomAnchor),
            categoryStackView.heightAnchor.constraint(equalTo: categoryScrollView.frameLayoutGuide.heightAnchor),
            
            collectionView.topAnchor.constraint(equalTo: categoryScrollView.bottomAnchor, constant: 16),
            collectionView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
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

        // фиксированная часть: отступ сверху + label (2 строки) + spacing + кнопка + отступ снизу
        let fixedHeight: CGFloat = 10 + 40 + 10 + 36 + 12
        let itemHeight = floor(itemWidth * 0.62) + fixedHeight

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

extension LaravelMenuViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        searchButtonTapped()
        return true
    }
}
