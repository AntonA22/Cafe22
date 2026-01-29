//
//  CartViewController.swift
//  Cafe
//
//  Created by Антон Абалуев on 07.01.2026.
//

//import UIKit
//
//final class CartViewController: UIViewController {
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        view.backgroundColor = .systemBackground
//        title = "Корзина"
//
//        let label = UILabel()
//        label.text = "Корзина\nв разработке 🛒"
//        label.numberOfLines = 0
//        label.textAlignment = .center
//        label.font = .systemFont(ofSize: 20, weight: .medium)
//        label.textColor = .secondaryLabel
//
//        view.addSubview(label)
//        label.translatesAutoresizingMaskIntoConstraints = false
//
//        NSLayoutConstraint.activate([
//            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
//        ])
//    }
//}

//
//  CartViewController.swift
//  Cafe
//
//  Created by Антон Абалуев on 07.01.2026.
//

import UIKit
final class CartViewController: UIViewController {


    
    private let searchTextField = UITextField()
    private let searchButton = UIButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Корзина"
        
        setupUI()
        setupConstraints()
    }
    
    private func setupUI() {
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




    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Поле поиска
            searchTextField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            searchTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            searchTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            searchTextField.heightAnchor.constraint(equalToConstant: 44),
            
            // Кнопка поиска
            searchButton.topAnchor.constraint(equalTo: searchTextField.bottomAnchor, constant: 20),
            searchButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            searchButton.widthAnchor.constraint(equalToConstant: 120),
            searchButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    @objc private func searchButtonTapped() {
        guard let query = searchTextField.text, !query.isEmpty else {
            print("Введите запрос для поиска")
            return
        }
        
        Task {
            do {
                let products = try await ProductsService.shared.searchProducts(body: SearchDTO(query: query))
                print("Найдено товаров: \(products.count)")
                print(products)

                //добавляем products в массив
                //обновляем список товаров


            } catch {
                print("Ошибка поиска: \(error)")
            }
        }
    }
}

