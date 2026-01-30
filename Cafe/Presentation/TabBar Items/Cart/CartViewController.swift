//
//  CartViewController.swift
//  Cafe
//
//  Created by Антон Абалуев on 07.01.2026.
//

import UIKit

final class CartViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    private var items: [CartItemDTO] = CartMock.cart.items {
        didSet { updateUI() }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        setupNavBar()
        setupTableView()
        setupFooter()
        updateUI()
    }
    
    func setupNavBar() {
        title = "Корзина"

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Товаров: \(items.count)",
            style: .plain,
            target: nil,
            action: nil
        )

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Очистить",
            style: .plain,
            target: self,
            action: #selector(clearCart)
        )

        navigationItem.rightBarButtonItem?.tintColor = .systemRed
    }

    func updateNavBar() {
        navigationItem.leftBarButtonItem?.title = "Товаров: \(items.count)"
    }

    @objc func clearCart() {
        items.removeAll()
    }
    
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
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

extension CartViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(
            withIdentifier: CartItemCell.reuseId,
            for: indexPath
        ) as! CartItemCell

        cell.configure(with: items[indexPath.row])
        cell.delegate = self
        return cell
    }

    func tableView(_ tableView: UITableView,
                   commit editingStyle: UITableViewCell.EditingStyle,
                   forRowAt indexPath: IndexPath) {

        if editingStyle == .delete {
            items.remove(at: indexPath.row)
        }
    }
    
    func setupFooter() {
        let footer = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 120))

        let totalLabel = UILabel()
        totalLabel.tag = 100
        totalLabel.font = .systemFont(ofSize: 18, weight: .bold)
        totalLabel.textAlignment = .center

        let button = UIButton(type: .system)
        button.setTitle("Оформить заказ", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.addTarget(self, action: #selector(checkout), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [totalLabel, button])
        stack.axis = .vertical
        stack.spacing = 16

        footer.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: footer.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: footer.centerYAnchor)
        ])

        tableView.tableFooterView = footer
    }

    func updateFooter() {
        let total = items.reduce(0) { $0 + $1.sum }
        let label = tableView.tableFooterView?.viewWithTag(100) as? UILabel
        label?.text = "Итого: \(total) ₽"
    }

    @objc func checkout() {
        print("Оформляем заказ 🚀")
    }
    
    func updateUI() {
       updateNavBar()
       updateFooter()
       tableView.reloadData()

       if items.isEmpty {
           let label = UILabel()
           label.text = "Корзина пуста 🛒"
           label.textAlignment = .center
           label.textColor = .secondaryLabel
           tableView.backgroundView = label
       } else {
           tableView.backgroundView = nil
       }
   }
}

extension CartViewController: CartItemCellDelegate {

    func didTapPlus(on item: CartItemDTO) {
        update(item, delta: 1)
    }

    func didTapMinus(on item: CartItemDTO) {
        update(item, delta: -1)
    }

    private func update(_ item: CartItemDTO, delta: Int) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }

        var updated = items[index]
        let newQty = updated.qty + delta

        if newQty <= 0 {
            items.remove(at: index)
        } else {
            updated = CartItemDTO(
                id: updated.id,
                dessertId: updated.dessertId,
                qty: newQty,
                price: updated.price,
                sum: updated.price * newQty,
                dessert: updated.dessert
            )
            items[index] = updated
        }
    }
}
