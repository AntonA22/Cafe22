//
//  MakeOrderViewController.swift
//  Cafe
//
//  Created by Антон Абалуев on 06.02.2026.
//

import UIKit

final class MakeOrderViewController: UIViewController {

    // MARK: - Models

    enum Section: Int, CaseIterable {
        case delivery
        case payment
        case comment
        case summary
    }

    enum DeliveryMode: Int {
        case delivery = 0
        case pickup = 1
    }

    enum PaymentMode: Int, CaseIterable {
        case card
        case cash

        var title: String {
            switch self {
            case .card: return "Карта"
            case .cash: return "Наличные"
            }
        }

        var icon: UIImage? {
            switch self {
            case .card: return UIImage(systemName: "creditcard")
            case .cash: return UIImage(systemName: "banknote")
            }
        }
    }

    // MARK: - Input

    private let cartItems: [CartItemDTO]

    // MARK: - State

    private var deliveryMode: DeliveryMode = .delivery
    private var selectedAddressTitle: String? = "Дом"
    private var selectedAddressSubtitle: String? = "ул. Пушкина, 10 • подъезд 2"
    private var paymentMode: PaymentMode = .card
    private var leaveAtDoor: Bool = false
    private var commentText: String = ""
    private var phone: String = ""
    
    private var selectedAddressId: String?
    
    // MARK: - UI

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    // bottom bar
    private let bottomBar = UIView()
    private let totalLabel = UILabel()
    private let payButton = UIButton(type: .system)

    init(cartItems: [CartItemDTO]) {
        self.cartItems = cartItems
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Оформление заказа"

        setupTable()
        
        Task {
            await loadDefaultAddress()
        }
        
        setupBottomBar()
        refreshBottomBar()

        // 1) Сначала пробуем взять телефон из памяти (если ты где-то хранишь user)
        if let user = AuthService.shared.currentUser,
           let p = user.phone,
           !p.isEmpty {

            self.phone = p
            tableView.reloadRows(
                at: [IndexPath(row: 2, section: Section.delivery.rawValue)],
                with: .none
            )
            return
        }

        // 2) Если в памяти нет — дергаем /me
        Task {
            do {
                let me = try await AuthService.shared.fetchMe()

                if let p = me.phone, !p.isEmpty {
                    await MainActor.run {
                        self.phone = p
                        self.tableView.reloadRows(
                            at: [IndexPath(row: 2, section: Section.delivery.rawValue)],
                            with: .none
                        )
                    }
                }
            } catch {
                print("Не удалось загрузить профиль:", error)
            }
        }
    }

    private func loadDefaultAddress() async {
        do {
            let addresses = try await AddressService.shared.getAddresses()

            // ищем адрес по умолчанию
            if let def = addresses.first(where: { $0.isDefault }) {

                await MainActor.run {
                    self.selectedAddressTitle = def.title

                    self.selectedAddressId = def.id
                    
                    // собираем красивый сабтитл как у тебя в UI
                    var parts: [String] = [def.baseAddress]

                    if let e = def.entrance, !e.isEmpty {
                        parts.append("подъезд \(e)")
                    }
                    if let f = def.flat, !f.isEmpty {
                        parts.append("кв. \(f)")
                    }

                    self.selectedAddressSubtitle = parts.joined(separator: " • ")

                    // перезагружаем только строку с адресом
                    self.tableView.reloadRows(
                        at: [IndexPath(row: 1, section: Section.delivery.rawValue)],
                        with: .none
                    )
                }
            }
        } catch {
            print("Ошибка загрузки адресов:", error)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // чтобы контент не прятался под нижней панелью
        let inset = bottomBar.bounds.height + 12
        tableView.contentInset.bottom = inset
        tableView.verticalScrollIndicatorInsets.bottom = inset
    }

    // MARK: - Setup

    private func setupTable() {
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 56
        
        tableView.dataSource = self
        tableView.delegate = self

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.register(MakeOrderSwitchCell.self, forCellReuseIdentifier: MakeOrderSwitchCell.reuseId)
        tableView.register(MakeOrderRadioCell.self,  forCellReuseIdentifier: MakeOrderRadioCell.reuseId)
        tableView.register(MakeOrderValueCell.self,  forCellReuseIdentifier: MakeOrderValueCell.reuseId)
        tableView.register(MakeOrderCommentCell.self,forCellReuseIdentifier: MakeOrderCommentCell.reuseId)
        tableView.register(MakeOrderPhoneCell.self, forCellReuseIdentifier: MakeOrderPhoneCell.reuseId)

        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupBottomBar() {
//        bottomBar.backgroundColor = .secondarySystemBackground
//        bottomBar.layer.cornerRadius = 16
//        bottomBar.layer.masksToBounds = true
        
        bottomBar.backgroundColor = .clear

        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemChromeMaterial))
        blur.layer.cornerRadius = 18
        blur.clipsToBounds = true
        bottomBar.addSubview(blur)
        blur.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            blur.topAnchor.constraint(equalTo: bottomBar.topAnchor),
            blur.leadingAnchor.constraint(equalTo: bottomBar.leadingAnchor),
            blur.trailingAnchor.constraint(equalTo: bottomBar.trailingAnchor),
            blur.bottomAnchor.constraint(equalTo: bottomBar.bottomAnchor),
        ])

        totalLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        totalLabel.numberOfLines = 2

        payButton.setTitle("Оплатить", for: .normal)
        payButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .bold)
        payButton.contentEdgeInsets = UIEdgeInsets(top: 14, left: 18, bottom: 14, right: 18)
        payButton.layer.cornerRadius = 14
        payButton.backgroundColor = .systemBlue
        payButton.tintColor = .white
        payButton.addTarget(self, action: #selector(payTapped), for: .touchUpInside)

        let h = UIStackView(arrangedSubviews: [totalLabel, UIView(), payButton])
        h.axis = .horizontal
        h.alignment = .center
        h.spacing = 12

        bottomBar.addSubview(h)
        h.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(bottomBar)
        bottomBar.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            bottomBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            bottomBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            bottomBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),

            h.topAnchor.constraint(equalTo: bottomBar.topAnchor, constant: 12),
            h.leadingAnchor.constraint(equalTo: bottomBar.leadingAnchor, constant: 14),
            h.trailingAnchor.constraint(equalTo: bottomBar.trailingAnchor, constant: -14),
            h.bottomAnchor.constraint(equalTo: bottomBar.bottomAnchor, constant: -12),
        ])
    }

    // MARK: - Helpers

    private func cartTotal() -> Int {
        // sum у тебя уже есть в CartItemDTO
        // округление если надо — здесь
        return cartItems.reduce(0) { $0 + Int($1.sum) }
    }

    private func deliveryFee() -> Int {
        // пример логики
        guard deliveryMode == .delivery else { return 0 }
        return cartTotal() >= 1200 ? 0 : 149
    }

    private func grandTotal() -> Int {
        cartTotal() + deliveryFee()
    }

    private func formatRub(_ value: Int) -> String {
        "\(value) ₽"
    }

    private func refreshBottomBar() {
        let total = grandTotal()
        totalLabel.text = "Итого: \(formatRub(total))"
        let btnTitle: String = (paymentMode == .cash) ? "Оформить" : "Оплатить"
        payButton.setTitle(btnTitle, for: .normal)
    }

    private func presentStub(_ title: String, _ message: String, onOK: (() -> Void)? = nil) {
        let a = UIAlertController(title: title, message: message, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "Ок", style: .default) { _ in
            onOK?()
        })
        present(a, animated: true)
    }

    // MARK: - Actions

    @objc private func payTapped() {
        // 1) проверки
        if deliveryMode == .delivery, selectedAddressId == nil {
            presentStub("Адрес не выбран", "Выбери адрес доставки.")
            return
        }
        if phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            presentStub("Телефон", "Укажи номер телефона.")
            return
        }

        // 2) собираем dto
        let dto = CreateOrderDTO(
            addressId: selectedAddressId ?? "", // при pickup можешь не требовать, но лучше на бэке сделать nullable
            comment: commentText.isEmpty ? nil : commentText,
            paymentMode: (paymentMode == .card) ? "card" : "cash",
            deliveryMode: (deliveryMode == .delivery) ? "delivery" : "pickup",
            leaveAtDoor: (deliveryMode == .delivery) ? leaveAtDoor : nil,
            phone: phone
        )

        payButton.isEnabled = false

        Task {
            do {
                let order = try await OrdersService.shared.createOrder(dto: dto)

                await MainActor.run {
                    self.payButton.isEnabled = true

                    // обновляем корзину
                    NotificationCenter.default.post(name: .cartDidChange, object: nil)

                    self.presentStub(
                        "Заказ создан ✅",
                        "Номер: \(order.id)\nСтатус: \(order.status)\nСумма: \(self.formatRub(order.totalPrice))"
                    ) { [weak self] in
                        guard let self else { return }

                        // 1) закрываем оформление (возврат на корзину/куда пришли)
                        self.navigationController?.popViewController(animated: true)

                        // 2) переключаем таб на "Меню"
                        self.tabBarController?.selectedIndex = 0   // если "Меню" первый таб
                    }
                }
        
            } catch {
                await MainActor.run {
                    self.payButton.isEnabled = true
                    self.presentStub("Ошибка", error.localizedDescription)
                }
            }
        }
    }
}

// MARK: - UITableViewDataSource / Delegate

extension MakeOrderViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int { Section.allCases.count }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let s = Section(rawValue: section) else { return 0 }
        switch s {
        case .delivery: return (deliveryMode == .delivery ? 4 : 3)
        // 0 Способ, 1 Адрес, 2 Телефон, 3 Оставить у двери
        // при самовывозе: 0 Способ, 1 Точка, 2 Телефон
        case .payment: return PaymentMode.allCases.count
        case .comment: return 1  // оставляем только поле комментария
        case .summary: return 2 // товары + доставка
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let s = Section(rawValue: section) else { return nil }
        switch s {
        case .delivery: return "Доставка"
        case .payment: return "Оплата"
        case .comment: return "Пожелания"
        case .summary: return "Итог"
        }
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        guard let s = Section(rawValue: section) else { return nil }
        switch s {
        case .delivery:
            return deliveryMode == .delivery ? "Адрес можно выбрать/изменить." : "Самовывоз — без адреса."
        default:
            return nil
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let section = Section(rawValue: indexPath.section)!
        
        switch section {
            
        case .delivery:
            
            if indexPath.row == 0 {
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: MakeOrderValueCell.reuseId,
                    for: indexPath
                ) as! MakeOrderValueCell
                
                cell.configure(
                    title: "Способ",
                    value: deliveryMode == .delivery ? "Доставка" : "Самовывоз",
                    icon: UIImage(systemName: "shippingbox")
                )
                cell.accessoryType = .disclosureIndicator
                return cell
            }
            
            if indexPath.row == 1 {
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: MakeOrderValueCell.reuseId,
                    for: indexPath
                ) as! MakeOrderValueCell
                
                if deliveryMode == .delivery {
                    cell.configure(
                        title: selectedAddressTitle ?? "Адрес",
                        subtitle: selectedAddressSubtitle ?? "Выбрать адрес",
                        value: nil,
                        icon: UIImage(systemName: "mappin.and.ellipse")
                    )
                } else {
                    cell.configure(
                        title: "Точка самовывоза",
                        subtitle: "Выбрать ресторан",
                        value: nil,
                        icon: UIImage(systemName: "fork.knife")
                    )
                }
                cell.accessoryType = .disclosureIndicator
                return cell
            }
            
            // row 2 (Телефон)
            if indexPath.row == 2 {
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: MakeOrderPhoneCell.reuseId,
                    for: indexPath
                ) as! MakeOrderPhoneCell
                
                cell.configure(
                    title: "Телефон",
                    placeholder: "+7 (999) 123-45-67",
                    text: phone
                )
                cell.onTextChange = { [weak self] text in
                    self?.phone = text
                }
                return cell
            }
            
            // row 3 (Оставить у двери) — только при доставке
            if deliveryMode == .delivery {
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: MakeOrderSwitchCell.reuseId,
                    for: indexPath
                ) as! MakeOrderSwitchCell

                cell.configure(
                    title: "Оставить у двери",
                    isOn: leaveAtDoor,
                    icon: UIImage(systemName: "door.left.hand.open")
                )
                cell.onChange = { [weak self] v in
                    self?.leaveAtDoor = v
                }
                cell.selectionStyle = .none
                return cell
            } else {
                // этот ряд не должен появляться при самовывозе,
                // но чтобы компилятор был доволен — возвращаем пустую
                return UITableViewCell()
            }
            
            //            // row 2
            //            let cell = tableView.dequeueReusableCell(
            //                withIdentifier: MakeOrderSwitchCell.reuseId,
            //                for: indexPath
            //            ) as! MakeOrderSwitchCell
            //
            //            cell.configure(
            //                title: "Оставить у двери",
            //                isOn: leaveAtDoor,
            //                icon: UIImage(systemName: "door.left.hand.open")
            //            )
            //            cell.onChange = { [weak self] v in
            //                self?.leaveAtDoor = v
            //            }
            //            cell.selectionStyle = .none
            //            return cell
            
        case .payment:
            let cell = tableView.dequeueReusableCell(
                withIdentifier: MakeOrderRadioCell.reuseId,
                for: indexPath
            ) as! MakeOrderRadioCell
            
            let mode = PaymentMode.allCases[indexPath.row]
            cell.configure(title: mode.title, icon: mode.icon, isOn: mode == paymentMode)
            return cell
            
        case .comment:
            let cell = tableView.dequeueReusableCell(
                withIdentifier: MakeOrderCommentCell.reuseId,
                for: indexPath
            ) as! MakeOrderCommentCell
            
            cell.configure(
                placeholder: "Комментарий курьеру/кухне (необязательно)",
                text: commentText
            )
            cell.onTextChange = { [weak self] text in
                self?.commentText = text
            }
            return cell
            
        case .summary:
            let cell = tableView.dequeueReusableCell(
                withIdentifier: MakeOrderValueCell.reuseId,
                for: indexPath
            ) as! MakeOrderValueCell
            
            cell.selectionStyle = .none
            
            if indexPath.row == 0 {
                cell.configure(title: "Товары", value: formatRub(cartTotal()), icon: UIImage(systemName: "bag"))
            } else {
                let fee = deliveryFee()
                let value = (fee == 0) ? "Бесплатно" : formatRub(fee)
                cell.configure(title: "Доставка", value: value, icon: UIImage(systemName: "bicycle"))
            }
            
            cell.accessoryType = .none
            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let section = Section(rawValue: indexPath.section) else { return }
        tableView.deselectRow(at: indexPath, animated: true)

        switch section {

        case .delivery:

            // row 0 — Способ (Доставка/Самовывоз)
            if indexPath.row == 0 {
                let sheet = UIAlertController(title: "Способ", message: nil, preferredStyle: .actionSheet)

                sheet.addAction(UIAlertAction(title: "Доставка", style: .default) { [weak self] _ in
                    guard let self else { return }
                    self.deliveryMode = .delivery
                    self.refreshBottomBar()

                    self.tableView.reloadSections(
                        IndexSet([Section.delivery.rawValue, Section.summary.rawValue]),
                        with: .automatic
                    )
                })

                sheet.addAction(UIAlertAction(title: "Самовывоз", style: .default) { [weak self] _ in
                    guard let self else { return }
                    self.deliveryMode = .pickup
                    self.refreshBottomBar()

                    self.tableView.reloadSections(
                        IndexSet([Section.delivery.rawValue, Section.summary.rawValue]),
                        with: .automatic
                    )
                })

                sheet.addAction(UIAlertAction(title: "Отмена", style: .cancel))

                // для iPad (на всякий) — чтобы не падало
                if let pop = sheet.popoverPresentationController,
                   let cell = tableView.cellForRow(at: indexPath) {
                    pop.sourceView = cell
                    pop.sourceRect = cell.bounds
                }

                present(sheet, animated: true)
                return
            }

            // row 1 — Адрес / Точка самовывоза
            if indexPath.row == 1 {
                if deliveryMode == .delivery {
                    let vc = AddressesViewController()

                    vc.onAddressSelected = { [weak self] a in
                        guard let self else { return }

                        self.selectedAddressTitle = a.title
                        self.selectedAddressId = a.id
                        self.selectedAddressSubtitle = {
                            var parts: [String] = [a.baseAddress]
                            if let e = a.entrance, !e.isEmpty { parts.append("подъезд \(e)") }
                            if let f = a.flat, !f.isEmpty { parts.append("кв. \(f)") }
                            return parts.joined(separator: " • ")
                        }()

                        self.tableView.reloadRows(
                            at: [IndexPath(row: 1, section: Section.delivery.rawValue)],
                            with: .none
                        )
                    }

                    navigationController?.pushViewController(vc, animated: true)
                } else {
                    presentStub("Заглушка", "Открой выбор ресторана.")
                }
                return
            }

            // row 2/3 — телефон / оставить у двери — ничего не делаем
            return

        case .payment:
            paymentMode = PaymentMode.allCases[indexPath.row]
            refreshBottomBar()
            tableView.reloadSections(IndexSet(integer: Section.payment.rawValue), with: .none)
            return

        case .comment:
            // обычно ничего — пусть редактирует текст в ячейке
            return

        case .summary:
            // ничего
            return
        }
    }
}

// MARK: - UI Cells

final class MakeOrderValueCell: UITableViewCell {
    static let reuseId = "MakeOrderValueCell"

    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let valueLabel = UILabel()
    private let vStack = UIStackView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        accessoryType = .none

        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = .secondaryLabel
        iconView.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.font = .systemFont(ofSize: 16, weight: .regular)
        subtitleLabel.font = .systemFont(ofSize: 13, weight: .regular)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 0
        subtitleLabel.lineBreakMode = .byWordWrapping
        
        titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        subtitleLabel.setContentCompressionResistancePriority(.required, for: .vertical)

        valueLabel.font = .systemFont(ofSize: 16, weight: .regular)
        valueLabel.textColor = .secondaryLabel
        valueLabel.textAlignment = .right

        vStack.axis = .vertical
        vStack.spacing = 2
        vStack.addArrangedSubview(titleLabel)
        vStack.addArrangedSubview(subtitleLabel)

        let h = UIStackView(arrangedSubviews: [iconView, vStack, UIView(), valueLabel])
        h.axis = .horizontal
        h.alignment = .center
        h.spacing = 12
        contentView.addSubview(h)
        h.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 22),
            iconView.heightAnchor.constraint(equalToConstant: 22),

            h.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            h.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 14),
            h.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            h.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(title: String, subtitle: String? = nil, value: String? = nil, icon: UIImage?) {
        titleLabel.text = title
        subtitleLabel.text = subtitle
        subtitleLabel.isHidden = (subtitle == nil)
        valueLabel.text = value
        iconView.image = icon
    }
}

final class MakeOrderRadioCell: UITableViewCell {
    static let reuseId = "MakeOrderRadioCell"

    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let check = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = .secondaryLabel
        check.tintColor = .systemBlue

        titleLabel.font = .systemFont(ofSize: 16, weight: .regular)

        let h = UIStackView(arrangedSubviews: [iconView, titleLabel, UIView(), check])
        h.axis = .horizontal
        h.alignment = .center
        h.spacing = 12

        contentView.addSubview(h)
        h.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 22),
            iconView.heightAnchor.constraint(equalToConstant: 22),

            h.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            h.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 14),
            h.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            h.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(title: String, icon: UIImage?, isOn: Bool) {
        titleLabel.text = title
        iconView.image = icon
        check.isHidden = !isOn
    }
}

final class MakeOrderSwitchCell: UITableViewCell {
    static let reuseId = "MakeOrderSwitchCell"

    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let sw = UISwitch()

    var onChange: ((Bool) -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = .secondaryLabel
        titleLabel.font = .systemFont(ofSize: 16, weight: .regular)

        sw.addTarget(self, action: #selector(changed), for: .valueChanged)

        let h = UIStackView(arrangedSubviews: [iconView, titleLabel, UIView(), sw])
        h.axis = .horizontal
        h.alignment = .center
        h.spacing = 12

        contentView.addSubview(h)
        h.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 22),
            iconView.heightAnchor.constraint(equalToConstant: 22),

            h.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            h.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 14),
            h.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            h.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(title: String, isOn: Bool, icon: UIImage?) {
        titleLabel.text = title
        sw.isOn = isOn
        iconView.image = icon
    }

    @objc private func changed() {
        onChange?(sw.isOn)
    }
}

final class MakeOrderCommentCell: UITableViewCell, UITextViewDelegate {
    static let reuseId = "MakeOrderCommentCell"

    private let tv = UITextView()
    private let placeholderLabel = UILabel()

    var onTextChange: ((String) -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        selectionStyle = .none

        tv.font = .systemFont(ofSize: 16)
        tv.isScrollEnabled = false
        tv.delegate = self
        tv.backgroundColor = .clear

        placeholderLabel.font = .systemFont(ofSize: 16)
        placeholderLabel.textColor = .tertiaryLabel

        contentView.addSubview(tv)
        contentView.addSubview(placeholderLabel)

        tv.translatesAutoresizingMaskIntoConstraints = false
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            tv.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            tv.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 14),
            tv.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -14),
            tv.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),

            placeholderLabel.topAnchor.constraint(equalTo: tv.topAnchor, constant: 6),
            placeholderLabel.leadingAnchor.constraint(equalTo: tv.leadingAnchor, constant: 5),
            placeholderLabel.trailingAnchor.constraint(equalTo: tv.trailingAnchor),
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(placeholder: String, text: String) {
        placeholderLabel.text = placeholder
        tv.text = text
        placeholderLabel.isHidden = !text.isEmpty
    }

    func textViewDidChange(_ textView: UITextView) {
        placeholderLabel.isHidden = !textView.text.isEmpty
        onTextChange?(textView.text)
    }
}

final class MakeOrderPhoneCell: UITableViewCell, UITextFieldDelegate {
    static let reuseId = "MakeOrderPhoneCell"

    private let iconView = UIImageView(image: UIImage(systemName: "phone"))
    private let titleLabel = UILabel()
    private let textField = UITextField()

    var onTextChange: ((String) -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        selectionStyle = .none

        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = .secondaryLabel

        titleLabel.font = .systemFont(ofSize: 16, weight: .regular)

        textField.font = .systemFont(ofSize: 16)
        textField.textAlignment = .right
        textField.keyboardType = .phonePad
        textField.returnKeyType = .done
        textField.delegate = self
        textField.addTarget(self, action: #selector(changed), for: .editingChanged)

        let h = UIStackView(arrangedSubviews: [iconView, titleLabel, UIView(), textField])
        h.axis = .horizontal
        h.alignment = .center
        h.spacing = 12

        contentView.addSubview(h)
        h.translatesAutoresizingMaskIntoConstraints = false
        iconView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 22),
            iconView.heightAnchor.constraint(equalToConstant: 22),

            h.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            h.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 14),
            h.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -14),
            h.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),

            textField.widthAnchor.constraint(greaterThanOrEqualToConstant: 140)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(title: String, placeholder: String, text: String) {
        titleLabel.text = title
        textField.placeholder = placeholder
        textField.text = text
    }

    @objc private func changed() {
        onTextChange?(textField.text ?? "")
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
