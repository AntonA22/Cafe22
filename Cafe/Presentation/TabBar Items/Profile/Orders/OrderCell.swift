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
    private let idLabel = UILabel()
    private let dateLabel = UILabel()
    private let addressLabel = UILabel()
    private let weightLabel = UILabel()
    private let totalLabel = UILabel()

    // было UILabel -> делаем пилюлю
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
        cardView.backgroundColor = UIColor.systemGray6
        cardView.layer.cornerRadius = 12
        contentView.addSubview(cardView)

        cardView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(8)
            $0.left.right.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview().offset(-8)
            $0.height.equalTo(140)
        }

        idLabel.textColor = .label
        addressLabel.textColor = .label
        totalLabel.textColor = .label

        idLabel.font = .systemFont(ofSize: 16, weight: .medium)

        dateLabel.textColor = .secondaryLabel
        dateLabel.font = .systemFont(ofSize: 14)

        addressLabel.numberOfLines = 2

        weightLabel.textColor = .secondaryLabel

        // ✅ Статус как “пилюля”, как в деталях
        statusLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        statusLabel.textAlignment = .center
        statusLabel.layer.cornerRadius = 12
        statusLabel.layer.masksToBounds = true
        statusLabel.insets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)

        detailsButton.setTitle("Детали", for: .normal)
        detailsButton.setTitleColor(.black, for: .normal)
        detailsButton.layer.borderWidth = 1
        detailsButton.layer.borderColor = UIColor.black.cgColor
        detailsButton.layer.cornerRadius = 16
        detailsButton.addTarget(self, action: #selector(detailsTapped), for: .touchUpInside)

        [idLabel, dateLabel, addressLabel, weightLabel, totalLabel, statusLabel, detailsButton]
            .forEach { cardView.addSubview($0) }

        idLabel.snp.makeConstraints {
            $0.top.left.equalToSuperview().offset(12)
        }

        dateLabel.snp.makeConstraints {
            $0.top.right.equalToSuperview().inset(12)
        }

        addressLabel.snp.makeConstraints {
            $0.top.equalTo(idLabel.snp.bottom).offset(8)
            $0.left.equalToSuperview().offset(12)
            $0.right.equalToSuperview().offset(-12)
        }

        weightLabel.snp.makeConstraints {
            $0.bottom.equalToSuperview().offset(-12)
            $0.left.equalToSuperview().offset(12)
        }

        totalLabel.snp.makeConstraints {
            $0.bottom.equalToSuperview().offset(-12)
            $0.centerX.equalToSuperview()
        }

        // ✅ расположение то же: снизу справа
        statusLabel.snp.makeConstraints {
            $0.bottom.equalToSuperview().offset(-12)
            $0.right.equalToSuperview().offset(-12)
            $0.height.greaterThanOrEqualTo(24)
        }

        detailsButton.snp.makeConstraints {
            $0.bottom.equalTo(weightLabel.snp.top).offset(-8)
            $0.left.equalToSuperview().offset(12)
            $0.width.equalTo(100)
            $0.height.equalTo(32)
        }
    }

    @objc private func detailsTapped() {
        onDetailsTap?()
    }

    func configure(with order: OrderDTO) {
        idLabel.text = "#\(order.id.prefix(6))..."

        if let dateString = order.createdAt,
           let date = Self.inputFormatter.date(from: dateString) {
            dateLabel.text = Self.outputFormatter.string(from: date)
        } else {
            dateLabel.text = "—"
        }

        let addressText = order.address?.title ?? "Адрес не указан"
        addressLabel.text = "Адрес доставки: \(addressText)"

        weightLabel.text = "Товары: \(order.itemsCount) шт"
        totalLabel.text = "Сумма: \(order.totalPrice) ₽"

        // ✅ разноцветная “пилюля”
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

    // ✅ такие же цвета, как на детальном
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
}
