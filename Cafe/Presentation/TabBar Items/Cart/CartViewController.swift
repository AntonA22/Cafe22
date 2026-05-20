//
//  CartViewController.swift
//  Cafe
//
//  Created by Антон Абалуев on 07.01.2026.
//

import UIKit

final class CartViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let footerView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 120))
    private let totalLabel = UILabel()
    private let checkoutButton = UIButton(type: .system)
    private var items: [CartItemDTO] = [] {
        didSet { updateUI() }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        useRussianBackButtonTitle()
        view.backgroundColor = .systemBackground

        setupNavBar()
        setupTableView()
        setupFooter()
        Task { await loadCart() }
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(cartDidChange(_:)),
                                               name: .cartDidChange,
                                               object: nil)

    }
    
//    @objc private func cartDidChange(_ notification: Notification) {
//        guard let cart = notification.object as? CartDTO else { return }
//        self.items = cart.items
//    }
    
    @objc private func cartDidChange(_ notification: Notification) {
        if let cart = notification.object as? CartDTO {
            Task { @MainActor in
                self.applyCart(cart)
            }
            return
        }
        Task { await loadCart() }
    }
    
    // MARK: - NavBar

    func setupNavBar() {
        title = "Корзина"
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Товаров: 0", style: .plain, target: nil, action: nil)
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Очистить", style: .plain, target: self, action: #selector(clearCartTapped))
        navigationItem.rightBarButtonItem?.tintColor = .systemRed
    }

    func updateNavBar() {
        let itemsCount = items.reduce(0) { $0 + $1.qty }
        navigationItem.leftBarButtonItem?.title = "Товаров: \(itemsCount)"
    }

    // MARK: - TableView

    func setupTableView() {
        tableView.register(CartItemCell.self, forCellReuseIdentifier: CartItemCell.reuseId)
        tableView.dataSource = self
        tableView.delegate = self
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    // MARK: - Footer

    func setupFooter() {
        footerView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 120)
        totalLabel.tag = 100
        totalLabel.font = .systemFont(ofSize: 18, weight: .bold)
        totalLabel.textAlignment = .center

        checkoutButton.setTitle("Оформить заказ", for: .normal)
        checkoutButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        checkoutButton.addTarget(self, action: #selector(checkout), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [totalLabel, checkoutButton])
        stack.axis = .vertical
        stack.spacing = 16
        footerView.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: footerView.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: footerView.centerYAnchor)
        ])

        tableView.tableFooterView = UIView(frame: .zero)
    }

    func updateFooter() {
        guard !items.isEmpty else {
            tableView.tableFooterView = UIView(frame: .zero)
            return
        }

        if tableView.tableFooterView !== footerView {
            footerView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 120)
            tableView.tableFooterView = footerView
        }

        let total = items.reduce(0) { $0 + $1.sum }
        totalLabel.text = "Итого: \(total) ₽"
        checkoutButton.isEnabled = true
        checkoutButton.alpha = 1.0
    }

    // MARK: - Actions

    @objc func checkout() {
        guard !items.isEmpty else {
            let alert = UIAlertController(
                title: "Корзина пуста",
                message: "Добавьте товары, чтобы оформить заказ.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "Ок", style: .default))
            present(alert, animated: true)
            return
        }

        let vc = MakeOrderViewController(cartItems: items)
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc func clearCartTapped() {
        Task {
            do {
                let cart = try await CartService.shared.clearCart()
                self.applyCart(cart)
            } catch {
                print("Ошибка очистки корзины:", error)
            }
        }
    }

    // MARK: - Load Cart

    private func loadCart() async {
        do {
            let cart = try await CartService.shared.getCart()
            applyCart(cart)
        } catch {
            print("Ошибка загрузки корзины:", error)
        }
    }

    @MainActor
    private func applyCart(_ cart: CartDTO) {
        items = cart.items.sorted { $0.id < $1.id }
    }

    // MARK: - Update Item Quantity

    private func updateItem(_ item: CartItemDTO, delta: Int) {
        Task {
            do {
                let newQty = item.qty + delta
                let cart: CartDTO
                if item.isCustomCake, let itemId = item.customCakeCartItemId {
                    if newQty <= 0 {
                        cart = try await CartService.shared.removeCustomCake(itemId: itemId)
                    } else {
                        cart = try await CartService.shared.setCustomCakeQty(itemId: itemId, qty: newQty)
                    }
                } else if let dessertId = item.dessertId {
                    if newQty <= 0 {
                        cart = try await CartService.shared.removeItem(dessertId: dessertId)
                    } else {
                        cart = try await CartService.shared.setQty(dessertId: dessertId, qty: newQty)
                    }
                } else {
                    return
                }
                self.applyCart(cart)
            } catch {
                print("Ошибка обновления позиции:", error)
            }
        }
    }

    private func updateUI() {
        updateNavBar()
        updateFooter()
        tableView.reloadData()

        if items.isEmpty {
            let label = UILabel()
            label.text = "Корзина пуста"
            label.font = .systemFont(ofSize: 18, weight: .medium)
            label.textAlignment = .center
            label.textColor = .secondaryLabel
            tableView.backgroundView = label
        } else {
            tableView.backgroundView = nil
        }
    }
}

// MARK: - TableView DataSource & Delegate

extension CartViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { items.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CartItemCell.reuseId, for: indexPath) as! CartItemCell
        cell.configure(with: items[indexPath.row])
        cell.delegate = self
        return cell
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle,
                   forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            updateItem(items[indexPath.row], delta: -items[indexPath.row].qty)
        }
    }
}

// MARK: - CartItemCellDelegate

extension CartViewController: CartItemCellDelegate {

    func didTapPlus(on item: CartItemDTO) { updateItem(item, delta: 1) }
    func didTapMinus(on item: CartItemDTO) { updateItem(item, delta: -1) }
    func didTapDessert(on item: CartItemDTO) {
        guard !item.isCustomCake, let dessertId = item.dessertId else { return }

        let detailVC = ProductDetailViewController()
        detailVC.productId = dessertId

        if let sheet = detailVC.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.selectedDetentIdentifier = .large
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 16
        }

        present(detailVC, animated: true)
    }
}
