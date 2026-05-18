import UIKit
import SnapKit

// MARK: - PaddingLabel (пилюля с внутренними отступами)

final class PaddingLabel: UILabel {
    var insets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: insets))
    }

    override var intrinsicContentSize: CGSize {
        let s = super.intrinsicContentSize
        return CGSize(width: s.width + insets.left + insets.right,
                      height: s.height + insets.top + insets.bottom)
    }
}

final class OrderCell: UITableViewCell {

    private let cardView = UIView()
    private let topStack = UIStackView()
    private let idLabel = UILabel()
    private let dateLabel = UILabel()
    private let addressStack = UIStackView()
    private let addressIconView = UIImageView(image: UIImage(systemName: "mappin.circle.fill"))
    private let addressLabel = UILabel()
    private let bottomStack = UIStackView()
    private let itemsChip = PaddingLabel()
    private let totalLabel = UILabel()

    private let statusLabel = PaddingLabel()
    private let detailsButton = UIButton(type: .system)

    var onDetailsTap: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none
        setupCard()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupCard() {
        contentView.preservesSuperviewLayoutMargins = false
        cardView.backgroundColor = .secondarySystemGroupedBackground
        cardView.layer.cornerRadius = 20
        cardView.layer.cornerCurve = .continuous
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.06
        cardView.layer.shadowRadius = 12
        cardView.layer.shadowOffset = CGSize(width: 0, height: 6)
        contentView.addSubview(cardView)

        cardView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(8)
            $0.left.right.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview().offset(-8)
        }

        topStack.axis = .horizontal
        topStack.alignment = .firstBaseline
        topStack.distribution = .fill
        topStack.spacing = 10

        idLabel.textColor = .label
        idLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        idLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        dateLabel.textColor = .secondaryLabel
        dateLabel.font = .systemFont(ofSize: 13, weight: .medium)
        dateLabel.textAlignment = .right
        dateLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        addressStack.axis = .horizontal
        addressStack.alignment = .top
        addressStack.spacing = 7

        addressIconView.tintColor = .secondaryLabel
        addressIconView.contentMode = .scaleAspectFit

        addressLabel.textColor = .label
        addressLabel.font = .systemFont(ofSize: 15, weight: .medium)
        addressLabel.numberOfLines = 2

        bottomStack.axis = .horizontal
        bottomStack.alignment = .center
        bottomStack.distribution = .fill
        bottomStack.spacing = 8

        itemsChip.font = .systemFont(ofSize: 13, weight: .semibold)
        itemsChip.textColor = .secondaryLabel
        itemsChip.backgroundColor = .systemGray6
        itemsChip.layer.cornerRadius = 14
        itemsChip.layer.masksToBounds = true
        itemsChip.insets = UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10)

        totalLabel.textColor = .label
        totalLabel.font = .systemFont(ofSize: 16, weight: .bold)
        totalLabel.adjustsFontSizeToFitWidth = true
        totalLabel.minimumScaleFactor = 0.82
        totalLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)

        statusLabel.font = .systemFont(ofSize: 13, weight: .bold)
        statusLabel.textAlignment = .center
        statusLabel.layer.cornerRadius = 15
        statusLabel.layer.masksToBounds = true
        statusLabel.insets = UIEdgeInsets(top: 6, left: 9, bottom: 6, right: 9)
        statusLabel.adjustsFontSizeToFitWidth = true
        statusLabel.minimumScaleFactor = 0.85
        statusLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)

        detailsButton.setTitle("Подробнее", for: .normal)
        detailsButton.setTitleColor(.white, for: .normal)
        detailsButton.titleLabel?.font = .systemFont(ofSize: 13, weight: .bold)
        detailsButton.backgroundColor = .label
        detailsButton.layer.cornerRadius = 15
        detailsButton.layer.cornerCurve = .continuous
        detailsButton.contentEdgeInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
        detailsButton.setContentHuggingPriority(.required, for: .horizontal)
        detailsButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        detailsButton.addTarget(self, action: #selector(detailsTapped), for: .touchUpInside)

        topStack.addArrangedSubview(idLabel)
        topStack.addArrangedSubview(dateLabel)

        addressStack.addArrangedSubview(addressIconView)
        addressStack.addArrangedSubview(addressLabel)

        bottomStack.addArrangedSubview(itemsChip)
        bottomStack.addArrangedSubview(totalLabel)
        bottomStack.addArrangedSubview(UIView())
        bottomStack.addArrangedSubview(statusLabel)
        bottomStack.addArrangedSubview(detailsButton)

        [topStack, addressStack, bottomStack]
            .forEach { cardView.addSubview($0) }

        topStack.snp.makeConstraints {
            $0.top.equalToSuperview().offset(16)
            $0.left.right.equalToSuperview().inset(16)
        }

        addressIconView.snp.makeConstraints {
            $0.width.height.equalTo(17)
        }

        addressStack.snp.makeConstraints {
            $0.top.equalTo(topStack.snp.bottom).offset(10)
            $0.left.right.equalToSuperview().inset(16)
        }

        bottomStack.snp.makeConstraints {
            $0.top.equalTo(addressStack.snp.bottom).offset(14)
            $0.left.right.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview().offset(-16)
        }

        detailsButton.snp.makeConstraints {
            $0.height.equalTo(30)
            $0.width.greaterThanOrEqualTo(104)
        }
    }

    @objc private func detailsTapped() {
        onDetailsTap?()
    }

    func configure(with order: OrderDTO) {
        idLabel.text = formattedOrderNumber(order)

        if let dateString = order.createdAt,
           let date = Self.inputFormatter.date(from: dateString) {
            dateLabel.text = Self.outputFormatter.string(from: date)
        } else {
            dateLabel.text = "—"
        }

        if order.isPickup {
            addressIconView.image = UIImage(systemName: "bag.fill")
            addressLabel.text = "Самовывоз: \(cafePickupAddress)"
        } else {
            addressIconView.image = UIImage(systemName: "mappin.circle.fill")
            addressLabel.text = Self.readableAddress(order.address)
        }

        itemsChip.text = "\(order.itemsCount) \(Self.itemsWord(order.itemsCount))"
        totalLabel.text = "\(order.totalPrice) ₽"

        statusLabel.text = order.statusTitle
        let (bg, fg) = statusColors(order.status)
        statusLabel.backgroundColor = bg
        statusLabel.textColor = fg
    }

    private static let inputFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    private static let outputFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter
    }()

    private static func itemsWord(_ count: Int) -> String {
        let mod10 = count % 10
        let mod100 = count % 100

        if mod10 == 1 && mod100 != 11 {
            return "товар"
        }

        if (2...4).contains(mod10) && !(12...14).contains(mod100) {
            return "товара"
        }

        return "товаров"
    }

    private static func readableAddress(_ address: AddressDTO?) -> String {
        guard let address else { return "Адрес не указан" }

        var parts = [address.baseAddress.trimmingCharacters(in: .whitespacesAndNewlines)]

        if let entrance = clean(address.entrance) { parts.append("подъезд \(entrance)") }
        if let floor = clean(address.floor) { parts.append("этаж \(floor)") }
        if let flat = clean(address.flat) { parts.append("кв. \(flat)") }

        let fullAddress = parts
            .filter { !$0.isEmpty }
            .joined(separator: ", ")

        if !fullAddress.isEmpty { return fullAddress }

        let title = address.title.trimmingCharacters(in: .whitespacesAndNewlines)
        return title.isEmpty ? "Адрес не указан" : title
    }

    private static func clean(_ value: String?) -> String? {
        let text = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return text.isEmpty ? nil : text
    }

    private func statusColors(_ status: String) -> (UIColor, UIColor) {
        switch status {
        case "delivered":
            return (.systemGreen.withAlphaComponent(0.16), .systemGreen)
        case "pending", "processing", "new":
            return (.systemOrange.withAlphaComponent(0.16), .systemOrange)
        case "shipped":
            return (.systemBlue.withAlphaComponent(0.16), .systemBlue)
        case "cancelled", "canceled":
            return (.systemRed.withAlphaComponent(0.16), .systemRed)
        default:
            return (.systemGray.withAlphaComponent(0.15), .secondaryLabel)
        }
    }
}
