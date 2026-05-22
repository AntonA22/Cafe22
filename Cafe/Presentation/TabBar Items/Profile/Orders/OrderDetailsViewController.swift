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
    private static let imageCache = NSCache<NSString, UIImage>()

    private let dessertImageView = UIImageView()
    private let titleLabel = UILabel()
    private let qtyLabel = UILabel()
    private let priceLabel = UILabel()
    private let detailsCard = UIStackView()
    private var imageWidthConstraint: NSLayoutConstraint?
    private var imageHeightConstraint: NSLayoutConstraint?
    private var imageTask: URLSessionDataTask?
    private var currentImageKey: String?

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
        imageWidthConstraint = dessertImageView.widthAnchor.constraint(equalToConstant: 72)
        imageHeightConstraint = dessertImageView.heightAnchor.constraint(equalToConstant: 56)
        imageWidthConstraint?.isActive = true
        imageHeightConstraint?.isActive = true

        // Title
        titleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 0

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
        priceLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        detailsCard.axis = .vertical
        detailsCard.spacing = 6
        detailsCard.alignment = .fill
        detailsCard.layoutMargins = UIEdgeInsets(top: 10, left: 12, bottom: 10, right: 12)
        detailsCard.isLayoutMarginsRelativeArrangement = true
        detailsCard.backgroundColor = .secondarySystemGroupedBackground
        detailsCard.layer.cornerRadius = 12
        detailsCard.layer.borderWidth = 1
        detailsCard.layer.borderColor = UIColor.separator.withAlphaComponent(0.35).cgColor
        detailsCard.isHidden = true

        // Main
        let topStack = UIStackView(arrangedSubviews: [dessertImageView, leftStack, priceLabel])
        topStack.axis = .horizontal
        topStack.alignment = .top
        topStack.spacing = 12

        let mainStack = UIStackView(arrangedSubviews: [topStack, detailsCard])
        mainStack.axis = .vertical
        mainStack.spacing = 10

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
        let isCustomCake = item.dessert?.category == "custom_cake"
        let title = item.dessert?.name ?? "Товар"
        titleLabel.text = title
        titleLabel.numberOfLines = isCustomCake ? 0 : 2
        qtyLabel.text = "× \(item.qty)"
        priceLabel.text = formatPrice(item.sum)
        configureDetails(for: item)
        imageWidthConstraint?.constant = isCustomCake ? 92 : 72
        imageHeightConstraint?.constant = isCustomCake ? 92 : 56
        setImage(from: item.dessert?.photos)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageTask?.cancel()
        imageTask = nil
        currentImageKey = nil
        dessertImageView.image = UIImage(named: "eclair")
        detailsCard.arrangedSubviews.forEach { view in
            detailsCard.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        detailsCard.isHidden = true
    }

    private func setImage(from photos: [String]?) {
        imageTask?.cancel()
        imageTask = nil
        dessertImageView.image = UIImage(named: "eclair")

        guard let firstPhoto = normalizedRemoteImageURLString(photos?.first),
              !firstPhoto.isEmpty else {
            currentImageKey = nil
            print("🖼️ Order image fallback: empty photo URL")
            return
        }

        if let dataImage = decodeDataImage(firstPhoto) {
            dessertImageView.image = dataImage
            currentImageKey = nil
            return
        }

        if let cached = Self.imageCache.object(forKey: firstPhoto as NSString) {
            dessertImageView.image = cached
            currentImageKey = firstPhoto
            return
        }

        if let localImage = UIImage(named: firstPhoto) {
            dessertImageView.image = localImage
            currentImageKey = nil
            return
        }

        guard
            let url = URL(string: firstPhoto),
            let scheme = url.scheme?.lowercased(),
            scheme == "http" || scheme == "https"
        else {
            currentImageKey = nil
            print("🖼️ Order image invalid URL: \(firstPhoto)")
            return
        }

        currentImageKey = firstPhoto

        imageTask = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self else { return }
            guard self.currentImageKey == firstPhoto else { return }

            if let error {
                print("🖼️ Order image request failed: \(firstPhoto), error=\(error.localizedDescription)")
                return
            }

            if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                let responseText = data.flatMap { String(data: $0, encoding: .utf8) } ?? ""
                print("🖼️ Order image bad status: \(firstPhoto), status=\(httpResponse.statusCode), body=\(responseText)")
                return
            }

            guard let data, let image = UIImage(data: data) else {
                print("🖼️ Order image decode failed: \(firstPhoto), bytes=\(data?.count ?? 0)")
                return
            }

            Self.imageCache.setObject(image, forKey: firstPhoto as NSString)

            DispatchQueue.main.async {
                guard self.currentImageKey == firstPhoto else { return }
                self.dessertImageView.image = image
            }
        }
        imageTask?.resume()
    }

    private func normalizedRemoteImageURLString(_ rawValue: String?) -> String? {
        guard var value = rawValue?.trimmingCharacters(in: .whitespacesAndNewlines),
              !value.isEmpty else { return nil }

        value = value.replacingOccurrences(of: "\\/", with: "/")

        if URL(string: value) != nil {
            return value
        }

        return value.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)
    }

    private func decodeDataImage(_ value: String) -> UIImage? {
        guard value.hasPrefix("data:image/"),
              let commaIndex = value.firstIndex(of: ",") else {
            return nil
        }

        let base64 = String(value[value.index(after: commaIndex)...])
        guard let data = Data(base64Encoded: base64, options: [.ignoreUnknownCharacters]) else {
            return nil
        }
        return UIImage(data: data)
    }

    private func configureDetails(for item: OrderItemDTO) {
        guard item.dessert?.category == "custom_cake" else {
            detailsCard.isHidden = true
            return
        }

        let details = customCakeDetails(for: item)
        detailsCard.arrangedSubviews.forEach { view in
            detailsCard.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        guard !details.isEmpty else {
            detailsCard.isHidden = true
            return
        }

        let header = UILabel()
        header.text = "Индивидуально для этого торта"
        header.font = .systemFont(ofSize: 13, weight: .semibold)
        header.textColor = .label
        detailsCard.addArrangedSubview(header)

        details.forEach { detail in
            detailsCard.addArrangedSubview(makeDetailRow(title: detail.title, value: detail.value))
        }

        detailsCard.isHidden = false
    }

    private func customCakeDetails(for item: OrderItemDTO) -> [(title: String, value: String)] {
        let description = item.dessert?.description?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let lines = description
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        return [
            ("Надпись", value(after: "Надпись:", in: lines)),
            ("Пожелания", value(after: "Пожелания:", in: lines)),
            ("Вес", value(after: "Вес:", in: lines))
        ].compactMap { title, value in
            guard let value, !value.isEmpty else { return nil }
            return (title, value)
        }
    }

    private func value(after prefix: String, in lines: [String]) -> String? {
        guard let line = lines.first(where: { $0.hasPrefix(prefix) }) else {
            return nil
        }

        return line
            .dropFirst(prefix.count)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func makeDetailRow(title: String, value: String) -> UIView {
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 12, weight: .medium)
        titleLabel.textColor = .secondaryLabel
        titleLabel.setContentHuggingPriority(.required, for: .horizontal)
        titleLabel.widthAnchor.constraint(equalToConstant: 78).isActive = true

        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = .systemFont(ofSize: 13, weight: .regular)
        valueLabel.textColor = .label
        valueLabel.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
        stack.axis = .horizontal
        stack.alignment = .firstBaseline
        stack.spacing = 8
        return stack
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

    private var order: OrderDTO
    var onOrderUpdated: ((OrderDTO) -> Void)?

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
    private let subtotalPriceLabel = UILabel()
    private let deliveryFeeLabel = UILabel()
    private let bonusPointsLabel = UILabel()
    private let earnedBonusLabel = UILabel()
    private let totalPriceLabel = UILabel()
    private let cancelButtonContainer = UIView()
    private let cancelButton = UIButton(type: .system)

    init(order: OrderDTO) {
        self.order = order
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        useRussianBackButtonTitle()
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
        itemsTableView.estimatedRowHeight = 150

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

        [itemsCountLabel, subtotalPriceLabel, deliveryFeeLabel, bonusPointsLabel, earnedBonusLabel].forEach {
            $0.font = .systemFont(ofSize: 15, weight: .regular)
            $0.textColor = .secondaryLabel
        }

        totalPriceLabel.font = .systemFont(ofSize: 18, weight: .bold)
        totalPriceLabel.textColor = .label

        let summaryStack = UIStackView(arrangedSubviews: [
            summaryTitle,
            itemsCountLabel,
            subtotalPriceLabel,
            deliveryFeeLabel,
            bonusPointsLabel,
            earnedBonusLabel,
            totalPriceLabel
        ])
        summaryStack.axis = .vertical
        summaryStack.spacing = 8
        summaryCard.addSubview(summaryStack)
        summaryStack.snp.makeConstraints { $0.edges.equalToSuperview().inset(14) }

        configureCancelButton()
        cancelButtonContainer.addSubview(cancelButton)
        stack.addArrangedSubview(cancelButtonContainer)
        cancelButtonContainer.snp.makeConstraints { $0.height.equalTo(40) }
        cancelButton.snp.makeConstraints {
            $0.top.left.bottom.equalToSuperview()
            $0.width.equalTo(170)
        }
    }

    private func fill() {
        // Header
        headerTitle.text = formattedOrderNumber(order)
        dateLabel.text = formatOrderDate(order.createdAt)

        statusBadge.text = order.statusTitle
        let (bg, fg) = statusColors(order.status)
        statusBadge.backgroundColor = bg
        statusBadge.textColor = fg

        // Address
        if order.isPickup {
            addressTitle.text = "Самовывоз"
            addressValue.text = cafePickupAddress
        } else if let dto = order.address {
            addressTitle.text = "Адрес доставки"
            let address = Address(dto: dto)
            addressValue.text = makeReadableAddress(address)
        } else {
            addressTitle.text = "Адрес доставки"
            addressValue.text = "Адрес не указан"
        }

        // Items
        items = order.items ?? []
        itemsTableView.reloadData()

        let tableHeight = items.isEmpty
            ? 76
            : items.reduce(CGFloat(0)) { $0 + estimatedItemRowHeight(for: $1) }
        itemsTableHeight?.update(offset: tableHeight)
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.itemsTableView.layoutIfNeeded()
            self.itemsTableHeight?.update(offset: max(self.itemsTableView.contentSize.height, tableHeight))
        }

        // Summary
        itemsCountLabel.text = "Товары: \(order.itemsCount) шт"
        subtotalPriceLabel.text = "Стоимость товаров: \(formatPrice(order.subtotalPrice ?? order.totalPrice))"
        deliveryFeeLabel.text = order.isPickup
            ? "Самовывоз: \(formatPrice(0))"
            : "Доставка: \(formatPrice(order.deliveryFee ?? 0))"
        bonusPointsLabel.text = "Списано бонусов: \(order.bonusPointsSpent)"
        let rewardBase = max(0, (order.subtotalPrice ?? order.totalPrice) - order.bonusPointsSpent)
        earnedBonusLabel.text = order.bonusPointsEarned > 0
            ? "Начислено бонусов: \(order.bonusPointsEarned)"
            : "Будет начислено после \(order.isPickup ? "выдачи" : "доставки"): \(Int(floor(Double(rewardBase) * 0.05)))"
        totalPriceLabel.text = "Оплачено: \(formatPrice(order.totalPrice))"
        updateCancelButton()
    }

    private func configureCancelButton() {
        cancelButton.setTitle("Отменить заказ", for: .normal)
        cancelButton.setTitleColor(.systemRed, for: .normal)
        cancelButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .bold)
        cancelButton.backgroundColor = UIColor.systemRed.withAlphaComponent(0.12)
        cancelButton.layer.cornerRadius = 12
        cancelButton.layer.cornerCurve = .continuous
        cancelButton.contentHorizontalAlignment = .center
        cancelButton.addTarget(self, action: #selector(cancelOrderTapped), for: .touchUpInside)
    }

    private func updateCancelButton() {
        let isHidden = order.status != "new"
        cancelButtonContainer.isHidden = isHidden
        cancelButton.isHidden = isHidden
    }

    @objc private func cancelOrderTapped() {
        let alert = UIAlertController(
            title: "Отменить заказ?",
            message: "Заказ перейдёт в статус «Отменён». Это действие нельзя будет отменить.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Не отменять", style: .cancel))
        alert.addAction(UIAlertAction(title: "Отменить", style: .destructive) { [weak self] _ in
            self?.cancelOrder()
        })
        present(alert, animated: true)
    }

    private func cancelOrder() {
        cancelButton.isEnabled = false

        Task {
            do {
                let updated = try await OrdersService.shared.cancelOrder(id: order.id)

                await MainActor.run {
                    self.order = updated
                    self.onOrderUpdated?(updated)
                    self.fill()
                    self.cancelButton.isEnabled = true
                }
            } catch {
                await MainActor.run {
                    self.cancelButton.isEnabled = true
                    self.presentError(error)
                }
            }
        }
    }

    private func presentError(_ error: Error) {
        let alert = UIAlertController(
            title: "Не удалось отменить заказ",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Ок", style: .default))
        present(alert, animated: true)
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
        case "cancelled", "canceled":
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

    private func estimatedItemRowHeight(for item: OrderItemDTO) -> CGFloat {
        item.dessert?.category == "custom_cake" ? 150 : 76
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
