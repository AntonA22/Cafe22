import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    
    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        let window = UIWindow(windowScene: windowScene)
        Task {
            var startVC : UIViewController;
            
            if (AuthService.shared.currentToken() != nil ) {
                
                let user = try  await AuthService.shared.fetchMe()
              //  сделать правильно
                if(user == nil ) {
                    startVC = AuthViewController()
                }
                //добавить, а что если ничего не получили
                else {
                    startVC = MainTabBarController(user: user);
                }
                
            }
            else { startVC = AuthViewController() }
                
           let nav = UINavigationController(rootViewController: startVC)
                
            
            nav.navigationBar.isHidden = true // если хочешь скрыть верхнюю полоску
            window.rootViewController = nav
            window.overrideUserInterfaceStyle = .light // белая тема по умолчанию
            window.makeKeyAndVisible()
            self.window = window
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {}
    func sceneDidBecomeActive(_ scene: UIScene) {}
    func sceneWillResignActive(_ scene: UIScene) {}
    func sceneWillEnterForeground(_ scene: UIScene) {}
    func sceneDidEnterBackground(_ scene: UIScene) {}
}
