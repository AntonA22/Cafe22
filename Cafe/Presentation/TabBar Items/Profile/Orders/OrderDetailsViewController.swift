//
//  OrderDetailsViewController.swift
//  Cafe
//
//  Created by Антон Абалуев on 15.02.2026.
//

import UIKit
import SnapKit

// MARK: - Cell

final class OrderItemCell: UITableViewCell {

    static let reuseId = "OrderItemCell"

    private let dessertImageView = UIImageView()
    private let titleLabel = UILabel()
    private let qtyLabel = UILabel()
    private let priceLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        // Image
        dessertImageView.contentMode = .scaleAspectFill
        dessertImageView.clipsToBounds = true
        dessertImageView.layer.cornerRadius = 10
        dessertImageView.backgroundColor = .systemGray5 // placeholder

        dessertImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            dessertImageView.widthAnchor.constraint(equalToConstant: 72),
            dessertImageView.heightAnchor.constraint(equalToConstant: 56)
        ])

        // Title
        titleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 2

        // Qty
        qtyLabel.font = .systemFont(ofSize: 14, weight: .regular)
        qtyLabel.textColor = .secondaryLabel

        let leftStack = UIStackView(arrangedSubviews: [titleLabel, qtyLabel])
        leftStack.axis = .vertical
        leftStack.spacing = 4
        leftStack.alignment = .leading

        // Price
        priceLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        priceLabel.textColor = .label
        priceLabel.textAlignment = .right

        // Main
        let mainStack = UIStackView(arrangedSubviews: [dessertImageView, leftStack, UIView(), priceLabel])
        mainStack.axis = .horizontal
        mainStack.alignment = .center
        mainStack.spacing = 12

        contentView.addSubview(mainStack)
        mainStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            mainStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
            mainStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 0),
            mainStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: 0)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(with item: OrderItemDTO) {
        let title = item.dessert?.name ?? "Товар"
        titleLabel.text = title
        qtyLabel.text = "× \(item.qty)"
        priceLabel.text = formatPrice(item.sum)

        // Пока ставим заглушку из Assets
        dessertImageView.image = UIImage(named: "eclair")
    }

    private func formatPrice(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " "
        return (formatter.string(from: NSNumber(value: value)) ?? "\(value)") + " ₽"
    }
}

// MARK: - VC

final class OrderDetailsViewController: UIViewController {

    private let order: OrderDTO

    // UI
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let stack = UIStackView()

    private let headerTitle = UILabel()
    private let dateLabel = UILabel()
    private let statusBadge = UILabel()

    private let addressTitle = UILabel()
    private let addressValue = UILabel()

    private let itemsTitle = UILabel()
    private let itemsTableView = UITableView()
    private var itemsTableHeight: Constraint?
    private var items: [OrderItemDTO] = []

    private let summaryTitle = UILabel()
    private let itemsCountLabel = UILabel()
    private let totalPriceLabel = UILabel()

    init(order: OrderDTO) {
        self.order = order
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        title = "Заказ"

        setupUI()
        fill()
    }

    private func setupUI() {
        // Scroll
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        scrollView.snp.makeConstraints { $0.edges.equalTo(view.safeAreaLayoutGuide) }
        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalToSuperview()
        }

        // Stack
        stack.axis = .vertical
        stack.spacing = 12
        contentView.addSubview(stack)

        stack.snp.makeConstraints {
            $0.top.equalToSuperview().offset(16)
            $0.left.right.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview().offset(-24)
        }

        // Header card
        let headerCard = makeCard()
        stack.addArrangedSubview(headerCard)
        headerCard.snp.makeConstraints { $0.height.greaterThanOrEqualTo(70) }

        headerTitle.font = .systemFont(ofSize: 18, weight: .bold)
        headerTitle.textColor = .label

        dateLabel.font = .systemFont(ofSize: 14, weight: .regular)
        dateLabel.textColor = .secondaryLabel

        statusBadge.font = .systemFont(ofSize: 13, weight: .semibold)
        statusBadge.textAlignment = .center
        statusBadge.layer.cornerRadius = 10
        statusBadge.layer.masksToBounds = true
        
        statusBadge.setContentHuggingPriority(.required, for: .horizontal)
        statusBadge.setContentCompressionResistancePriority(.required, for: .horizontal)
        statusBadge.textAlignment = .center

        let headerStack = UIStackView(arrangedSubviews: [headerTitle, dateLabel])
        headerStack.axis = .vertical
        headerStack.spacing = 4

        let topRow = UIStackView(arrangedSubviews: [headerStack, statusBadge])
        topRow.axis = .horizontal
        topRow.alignment = .top
        topRow.spacing = 12

        headerCard.addSubview(topRow)
        topRow.snp.makeConstraints { $0.edges.equalToSuperview().inset(14) }

        statusBadge.snp.makeConstraints {
            $0.width.greaterThanOrEqualTo(90)
            $0.height.equalTo(28)
        }

        // Address card
        let addressCard = makeCard()
        stack.addArrangedSubview(addressCard)

        addressTitle.text = "Адрес доставки"
        addressTitle.font = .systemFont(ofSize: 15, weight: .semibold)
        addressTitle.textColor = .label

        addressValue.font = .systemFont(ofSize: 15, weight: .regular)
        addressValue.textColor = .label
        addressValue.numberOfLines = 0

        let addressStack = UIStackView(arrangedSubviews: [addressTitle, addressValue])
        addressStack.axis = .vertical
        addressStack.spacing = 8
        addressCard.addSubview(addressStack)
        addressStack.snp.makeConstraints { $0.edges.equalToSuperview().inset(14) }

        // Items card
        let itemsCard = makeCard()
        stack.addArrangedSubview(itemsCard)

        itemsTitle.text = "Товары"
        itemsTitle.font = .systemFont(ofSize: 15, weight: .semibold)
        itemsTitle.textColor = .label

        itemsTableView.register(OrderItemCell.self, forCellReuseIdentifier: OrderItemCell.reuseId)
        itemsTableView.dataSource = self
        itemsTableView.delegate = self
        itemsTableView.isScrollEnabled = false
        itemsTableView.separatorStyle = .none
        itemsTableView.backgroundColor = .clear
        itemsTableView.rowHeight = UITableView.automaticDimension
        itemsTableView.estimatedRowHeight = 76

        let itemsContainer = UIStackView(arrangedSubviews: [itemsTitle, itemsTableView])
        itemsContainer.axis = .vertical
        itemsContainer.spacing = 10
        itemsCard.addSubview(itemsContainer)
        itemsContainer.snp.makeConstraints { $0.edges.equalToSuperview().inset(14) }

        itemsTableView.snp.makeConstraints {
            self.itemsTableHeight = $0.height.equalTo(10).constraint
        }

        // Summary card
        let summaryCard = makeCard()
        stack.addArrangedSubview(summaryCard)

        summaryTitle.text = "Итого"
        summaryTitle.font = .systemFont(ofSize: 15, weight: .semibold)
        summaryTitle.textColor = .label

        itemsCountLabel.font = .systemFont(ofSize: 15, weight: .regular)
        itemsCountLabel.textColor = .secondaryLabel

        totalPriceLabel.font = .systemFont(ofSize: 18, weight: .bold)
        totalPriceLabel.textColor = .label

        let summaryStack = UIStackView(arrangedSubviews: [summaryTitle, itemsCountLabel, totalPriceLabel])
        summaryStack.axis = .vertical
        summaryStack.spacing = 8
        summaryCard.addSubview(summaryStack)
        summaryStack.snp.makeConstraints { $0.edges.equalToSuperview().inset(14) }
    }

    private func fill() {
        // Header
        headerTitle.text = "#\(order.id)"
        dateLabel.text = formatOrderDate(order.createdAt)

        statusBadge.text = order.status.capitalized
        let (bg, fg) = statusColors(order.status)
        statusBadge.backgroundColor = bg
        statusBadge.textColor = fg

        // Address
        if let dto = order.address {
            let address = Address(dto: dto)
            addressValue.text = makeReadableAddress(address)
        } else {
            addressValue.text = "Адрес не указан"
        }

        // Items
        items = order.items ?? []
        itemsTableView.reloadData()

        // высота таблицы: 1 строка-плейсхолдер, если пусто
        let rows = max(items.count, 1)
        let rowHeight: CGFloat = 76
        itemsTableHeight?.update(offset: rowHeight * CGFloat(rows))

        // Summary
        itemsCountLabel.text = "Товары: \(order.itemsCount) шт"
        totalPriceLabel.text = formatPrice(order.totalPrice)   // без "Итого:"
    }

    // MARK: - Helpers

    private func makeCard() -> UIView {
        let v = UIView()
        v.backgroundColor = .secondarySystemGroupedBackground
        v.layer.cornerRadius = 14
        return v
    }

    private func formatPrice(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " "
        return (formatter.string(from: NSNumber(value: value)) ?? "\(value)") + " ₽"
    }

    private func formatOrderDate(_ s: String?) -> String {
        guard let s else { return "—" }

        let inFmt = DateFormatter()
        inFmt.locale = Locale(identifier: "en_US_POSIX")
        inFmt.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ"

        let outFmt = DateFormatter()
        outFmt.locale = Locale(identifier: "ru_RU")
        outFmt.dateFormat = "d MMM yyyy, HH:mm"

        if let d = inFmt.date(from: s) {
            return outFmt.string(from: d)
        }
        return s
    }

    private func statusColors(_ status: String) -> (UIColor, UIColor) {
        switch status {
        case "delivered":
            return (.systemGreen.withAlphaComponent(0.15), .systemGreen)
        case "pending", "processing", "new":
            return (.systemOrange.withAlphaComponent(0.15), .systemOrange)
        case "shipped":
            return (.systemBlue.withAlphaComponent(0.15), .systemBlue)
        case "cancelled":
            return (.systemRed.withAlphaComponent(0.15), .systemRed)
        default:
            return (.systemGray.withAlphaComponent(0.15), .secondaryLabel)
        }
    }

    private func makeReadableAddress(_ address: Address?) -> String {
        guard let address else { return "Адрес не указан" }

        let subtitle = address.subtitle.trimmingCharacters(in: .whitespacesAndNewlines)
        if !subtitle.isEmpty { return subtitle }

        let title = address.title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !title.isEmpty { return title }

        return "Адрес не указан"
    }
}

// MARK: - Table

extension OrderDetailsViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        max(items.count, 1)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        if items.isEmpty {
            let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
            cell.selectionStyle = .none
            cell.backgroundColor = .clear
            cell.textLabel?.text = "Список товаров недоступен"
            cell.textLabel?.textColor = .secondaryLabel
            cell.textLabel?.font = .systemFont(ofSize: 14)
            return cell
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: OrderItemCell.reuseId, for: indexPath) as! OrderItemCell
        cell.configure(with: items[indexPath.row])
        return cell
    }
}
