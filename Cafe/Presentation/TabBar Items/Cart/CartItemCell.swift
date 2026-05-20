//
//  CartItemCell.swift
//  Cafe
//
//  Created by Антон Абалуев on 30.01.2026.
//

import UIKit
import Foundation

protocol CartItemCellDelegate: AnyObject {
    func didTapPlus(on item: CartItemDTO)
    func didTapMinus(on item: CartItemDTO)
    func didTapDessert(on item: CartItemDTO)
}

final class CartItemCell: UITableViewCell {

    static let reuseId = "CartItemCell"
    private static let imageCache = NSCache<NSString, UIImage>()

    weak var delegate: CartItemCellDelegate?
    private var item: CartItemDTO?
    private var imageTask: URLSessionDataTask?
    private var currentImageKey: String?

    private let dessertImageView = UIImageView()
    private let titleLabel = UILabel()
    private let priceLabel = UILabel()
    private let qtyLabel = UILabel()
    private let minusButton = UIButton(type: .system)
    private let plusButton = UIButton(type: .system)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        // MARK: Image
        dessertImageView.image = UIImage(named: "eclair")
        dessertImageView.contentMode = .scaleAspectFill
        dessertImageView.clipsToBounds = true
        dessertImageView.layer.cornerRadius = 10
        dessertImageView.isUserInteractionEnabled = true
        dessertImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dessertTapped)))

        NSLayoutConstraint.activate([
            dessertImageView.widthAnchor.constraint(equalToConstant: 80),
            dessertImageView.heightAnchor.constraint(equalToConstant: 56)
        ])

        // MARK: Title
        titleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        titleLabel.numberOfLines = 2
        titleLabel.isUserInteractionEnabled = true
        titleLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dessertTapped)))

        // MARK: Price
        priceLabel.font = .systemFont(ofSize: 17, weight: .bold)
        priceLabel.textAlignment = .right

        // MARK: Qty controls
        qtyLabel.font = .systemFont(ofSize: 15, weight: .medium)
        qtyLabel.textAlignment = .center
        qtyLabel.widthAnchor.constraint(equalToConstant: 24).isActive = true

        minusButton.setTitle("−", for: .normal)
        plusButton.setTitle("+", for: .normal)

        minusButton.titleLabel?.font = .systemFont(ofSize: 18)
        plusButton.titleLabel?.font = .systemFont(ofSize: 18)

        minusButton.addTarget(self, action: #selector(minusTapped), for: .touchUpInside)
        plusButton.addTarget(self, action: #selector(plusTapped), for: .touchUpInside)

        let qtyStack = UIStackView(arrangedSubviews: [
            minusButton,
            qtyLabel,
            plusButton
        ])
        qtyStack.spacing = 12
        qtyStack.alignment = .center

        // MARK: Left content
        let leftStack = UIStackView(arrangedSubviews: [
            titleLabel,
            qtyStack
        ])
        leftStack.axis = .vertical
        leftStack.spacing = 8
        leftStack.alignment = .leading

        // MARK: Right content
        let rightStack = UIStackView(arrangedSubviews: [
            UIView(), // spacer
            priceLabel
        ])
        rightStack.axis = .vertical
        rightStack.alignment = .trailing

        // MARK: Main stack
        let mainStack = UIStackView(arrangedSubviews: [
            dessertImageView,
            leftStack,
            rightStack
        ])
        mainStack.spacing = 12
        mainStack.alignment = .center

        contentView.addSubview(mainStack)
        mainStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            mainStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            mainStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            mainStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with item: CartItemDTO) {
        self.item = item
        titleLabel.text = item.dessert.name
        qtyLabel.text = "\(item.qty)"
        priceLabel.text = "\(item.sum) ₽"
        setImage(from: item.dessert.photos)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageTask?.cancel()
        imageTask = nil
        currentImageKey = nil
        dessertImageView.image = UIImage(named: "eclair")
    }

    private func setImage(from photos: [String]?) {
        imageTask?.cancel()
        imageTask = nil
        dessertImageView.image = UIImage(named: "eclair")

        let firstPhoto = photos?.first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !firstPhoto.isEmpty else {
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

        if firstPhoto.hasPrefix("data:image"),
           let commaIndex = firstPhoto.firstIndex(of: ",") {
            let base64 = String(firstPhoto[firstPhoto.index(after: commaIndex)...])
            if let data = Data(base64Encoded: base64, options: [.ignoreUnknownCharacters]),
               let image = UIImage(data: data) {
                dessertImageView.image = image
                currentImageKey = nil
                return
            }
        }

        guard
            let url = URL(string: firstPhoto),
            let scheme = url.scheme?.lowercased(),
            scheme == "http" || scheme == "https"
        else {
            currentImageKey = nil
            return
        }

        currentImageKey = firstPhoto

        imageTask = URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let self else { return }
            guard self.currentImageKey == firstPhoto else { return }
            guard let data, let image = UIImage(data: data) else { return }

            Self.imageCache.setObject(image, forKey: firstPhoto as NSString)

            DispatchQueue.main.async {
                guard self.currentImageKey == firstPhoto else { return }
                self.dessertImageView.image = image
            }
        }
        imageTask?.resume()
    }

    @objc private func minusTapped() {
        guard let item else { return }
        delegate?.didTapMinus(on: item)
    }

    @objc private func plusTapped() {
        guard let item else { return }
        delegate?.didTapPlus(on: item)
    }

    @objc private func dessertTapped() {
        guard let item else { return }
        delegate?.didTapDessert(on: item)
    }
}
