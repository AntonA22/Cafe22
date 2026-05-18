//
//  OrdersViewController.swift
//  Cafe
//
//  Created by Антон Абалуев on 11.02.2026.
//

import UIKit
import SnapKit


final class OrdersViewController: UIViewController {

    private let titleLabel = UILabel()
    private let segmentControl = UISegmentedControl(items: ["Актуальные", "Завершенные"])
    private let tableView = UITableView()

    private var actualOrders: [OrderDTO] = []
    private var completedOrders: [OrderDTO] = []

    private var showingActual = true

    override func viewDidLoad() {
        super.viewDidLoad()
        useRussianBackButtonTitle()
        view.backgroundColor = UIColor(red: 231/255, green: 235/255, blue: 241/255, alpha: 1)

        setupUI()
        setupTable()
        loadOrders()
    }

    // MARK: - UI

    private func setupUI() {
        titleLabel.text = "Мои заказы"
        titleLabel.font = .boldSystemFont(ofSize: 30)
        view.addSubview(titleLabel)

        titleLabel.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(16)
            $0.left.equalToSuperview().offset(16)
        }

        segmentControl.selectedSegmentIndex = 0
        segmentControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)

        view.addSubview(segmentControl)

        segmentControl.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(12)
            $0.left.right.equalToSuperview().inset(16)
        }

        view.addSubview(tableView)

        tableView.snp.makeConstraints {
            $0.top.equalTo(segmentControl.snp.bottom).offset(12)
            $0.left.right.bottom.equalToSuperview()
        }
    }

    private func setupTable() {
        tableView.register(OrderCell.self, forCellReuseIdentifier: "OrderCell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 188
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
    }

    @objc private func segmentChanged() {
        showingActual = segmentControl.selectedSegmentIndex == 0
        tableView.reloadData()
    }

    // MARK: - Загрузка с бэка

    private func loadOrders() {
        Task {
            do {
                let orders = try await OrdersService.shared.getOrders()

                // Разделяем по статусу
                self.actualOrders = orders.filter {
                    $0.status == "new"
                    || $0.status == "processing"
                    || $0.status == "shipped"
                }

                self.completedOrders = orders.filter {
                    $0.status == "delivered"
                    || $0.status == "cancelled"
                    || $0.status == "canceled"
                }

                await MainActor.run {
                    self.tableView.reloadData()
                }

            } catch {
                print("Ошибка загрузки заказов:", error)
            }
        }
    }
}


extension OrdersViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return showingActual ? actualOrders.count : completedOrders.count
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(
            withIdentifier: "OrderCell",
            for: indexPath
        ) as! OrderCell

        let order = showingActual
            ? actualOrders[indexPath.row]
            : completedOrders[indexPath.row]
        
        cell.onDetailsTap = { [weak self] in
            guard let self else { return }
            self.openDetails(for: order)
        }

        cell.configure(with: order)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let order = showingActual
            ? actualOrders[indexPath.row]
            : completedOrders[indexPath.row]
        
        tableView.deselectRow(at: indexPath, animated: true)
        openDetails(for: order)
    }

    private func openDetails(for order: OrderDTO) {
        let vc = OrderDetailsViewController(order: order)
        vc.onOrderUpdated = { [weak self] updated in
            self?.replaceOrder(updated)
        }

        if let nav = navigationController {
            nav.pushViewController(vc, animated: true)
        } else {
            let nav = UINavigationController(rootViewController: vc)
            present(nav, animated: true)
        }
    }

    private func replaceOrder(_ updated: OrderDTO) {
        actualOrders.removeAll { $0.id == updated.id }
        completedOrders.removeAll { $0.id == updated.id }

        if updated.status == "delivered" || updated.status == "cancelled" || updated.status == "canceled" {
            completedOrders.insert(updated, at: 0)
        } else {
            actualOrders.insert(updated, at: 0)
        }

        tableView.reloadData()
    }
}
