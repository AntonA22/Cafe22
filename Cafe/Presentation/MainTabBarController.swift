import UIKit

final class MainTabBarController: UITabBarController {

    private let user: UserDTO

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

        // Торты
        let cakeVC = CakeDesignerViewController()
        cakeVC.title = "Торты"
        cakeVC.useRussianBackButtonTitle()
        let cakeNav = UINavigationController(rootViewController: cakeVC)
        cakeNav.tabBarItem = UITabBarItem(
            title: "Торты",
            image: UIImage(systemName: "birthday.cake") ?? UIImage(systemName: "fork.knife.circle"),
            selectedImage: UIImage(systemName: "birthday.cake.fill") ?? UIImage(systemName: "fork.knife.circle.fill")
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

        viewControllers = [menuNav, cakeNav, cartNav, profileNav]
        selectedIndex = 0
    }
    private func setupAppearance() {
        if #available(iOS 15.0, *) {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            tabBar.standardAppearance = appearance
            tabBar.scrollEdgeAppearance = appearance
        }
    }
}
