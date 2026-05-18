import UIKit

final class MainTabBarController: UITabBarController {

    private let user: UserDTO
    private var cartTabBarItem: UITabBarItem?
    private let initialSelectedIndex = 2

    init(user: UserDTO) {
        self.user = user
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabs()
        setupAppearance()
        setupCartStateUpdates()
        loadCartState()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func setupTabs() {

        // Меню
        let menuVC = LaravelMenuViewController()
        menuVC.title = "Меню"
        menuVC.useRussianBackButtonTitle()
        let menuNav = UINavigationController(rootViewController: menuVC)
        menuNav.tabBarItem = UITabBarItem(
            title: "Меню",
            image: UIImage(systemName: "fork.knife"),
            selectedImage: UIImage(systemName: "fork.knife.fill")
        )

        // Торты с надписью
        let cakeVC = CakeDesignerViewController()
        cakeVC.navigationItem.title = "Торты с надписью"
        cakeVC.useRussianBackButtonTitle()
        let cakeNav = UINavigationController(rootViewController: cakeVC)
        cakeNav.tabBarItem = UITabBarItem(
            title: "Торты",
            image: UIImage(systemName: "birthday.cake") ?? UIImage(systemName: "fork.knife.circle"),
            selectedImage: UIImage(systemName: "birthday.cake.fill") ?? UIImage(systemName: "fork.knife.circle.fill")
        )

        // О нас
        let aboutCafeVC = AboutCafeViewController()
        aboutCafeVC.title = "О нас"
        aboutCafeVC.useRussianBackButtonTitle()
        let aboutCafeNav = UINavigationController(rootViewController: aboutCafeVC)
        aboutCafeNav.tabBarItem = UITabBarItem(
            title: "О нас",
            image: UIImage(systemName: "cup.and.saucer"),
            selectedImage: UIImage(systemName: "cup.and.saucer.fill")
        )

        // Корзина
        let cartVC = CartViewController()
        cartVC.useRussianBackButtonTitle()
        let cartNav = UINavigationController(rootViewController: cartVC)
        cartNav.tabBarItem = UITabBarItem(
            title: "Корзина",
            image: UIImage(systemName: "cart"),
            selectedImage: UIImage(systemName: "cart.fill")
        )
        cartTabBarItem = cartNav.tabBarItem

        // Профиль
        let profileVC = ProfileViewController(user: user)
        profileVC.title = "Профиль"
        profileVC.useRussianBackButtonTitle()
        let profileNav = UINavigationController(rootViewController: profileVC)
        profileNav.tabBarItem = UITabBarItem(
            title: "Профиль",
            image: UIImage(systemName: "person"),
            selectedImage: UIImage(systemName: "person.fill")
        )

        viewControllers = [menuNav, cakeNav, aboutCafeNav, cartNav, profileNav]
        selectedIndex = initialSelectedIndex
    }

    private func setupCartStateUpdates() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(cartDidChange(_:)),
            name: .cartDidChange,
            object: nil
        )
    }

    @objc private func cartDidChange(_ notification: Notification) {
        if let cart = notification.object as? CartDTO {
            updateCartTab(with: cart)
            return
        }

        loadCartState()
    }

    private func loadCartState() {
        Task { [weak self] in
            do {
                let cart = try await CartService.shared.getCart()
                await MainActor.run {
                    self?.updateCartTab(with: cart)
                }
            } catch {
                await MainActor.run {
                    self?.resetCartTab()
                }
            }
        }
    }

    private func updateCartTab(with cart: CartDTO) {
        let itemsCount = cart.items.reduce(0) { $0 + $1.qty }
        let total = cart.total > 0 ? cart.total : cart.items.reduce(0) { $0 + $1.sum }

        guard itemsCount > 0, total > 0 else {
            resetCartTab()
            return
        }

        cartTabBarItem?.image = UIImage(systemName: "cart")
        cartTabBarItem?.selectedImage = UIImage(systemName: "cart.fill")
        cartTabBarItem?.badgeValue = formatCartBadge(itemsCount)
        cartTabBarItem?.badgeColor = .systemRed
        cartTabBarItem?.setBadgeTextAttributes(
            [
                .foregroundColor: UIColor.white,
                .font: UIFont.systemFont(ofSize: 12, weight: .bold)
            ],
            for: .normal
        )
    }

    private func resetCartTab() {
        cartTabBarItem?.image = UIImage(systemName: "cart")
        cartTabBarItem?.selectedImage = UIImage(systemName: "cart.fill")
        cartTabBarItem?.badgeValue = nil
        cartTabBarItem?.badgeColor = nil
    }

    private func formatCartBadge(_ itemsCount: Int) -> String {
        itemsCount > 99 ? "99+" : "\(itemsCount)"
    }

    private func setupAppearance() {
        let normalTitleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11, weight: .regular),
            .kern: 0
        ]
        let selectedTitleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11, weight: .semibold),
            .kern: 0
        ]

        if #available(iOS 15.0, *) {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            [appearance.stackedLayoutAppearance, appearance.inlineLayoutAppearance, appearance.compactInlineLayoutAppearance].forEach {
                $0.normal.titleTextAttributes = normalTitleAttributes
                $0.selected.titleTextAttributes = selectedTitleAttributes
            }
            tabBar.standardAppearance = appearance
            tabBar.scrollEdgeAppearance = appearance
        } else {
            UITabBarItem.appearance().setTitleTextAttributes(normalTitleAttributes, for: .normal)
            UITabBarItem.appearance().setTitleTextAttributes(selectedTitleAttributes, for: .selected)
        }
    }
}
