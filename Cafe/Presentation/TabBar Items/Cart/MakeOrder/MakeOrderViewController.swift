//
//  MakeOrderViewController.swift
//  Cafe
//
//  Created by Антон Абалуев on 06.02.2026.
//

import UIKit

final class MakeOrderViewController: UIViewController {
    private enum PickupPoint {
        static let address = "Проспект Мира, 95с1"
        static let latitude = 55.8079
        static let longitude = 37.6387
    }
    private enum DeliveryPricing {
        static let freeDeliveryThreshold = 1200
        static let standardDeliveryFee = 149
    }
    private enum DeliveryArea {
        static let minLatitude = 54.25
        static let maxLatitude = 56.95
        static let minLongitude = 35.15
        static let maxLongitude = 40.25
    }

    // MARK: - Models

    enum Section: Int, CaseIterable {
        case delivery
        case bonus
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
            case .card: return "Картой при получении"
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
    private let customCake: CustomCakeOrderDTO?
    private let customCakeTitle: String?
    private let customCakePrice: Int?

    // MARK: - State

    private var deliveryMode: DeliveryMode = .delivery
    private var selectedAddressTitle: String?
    private var selectedAddressSubtitle: String?
    private var paymentMode: PaymentMode = .card
    private var leaveAtDoor: Bool = false
    private var useBonusPoints: Bool = false
    private var userBonusBalance: Int = AuthService.shared.currentUser?.bonusPoints ?? 0
    private var commentText: String = ""
    private var phone: String = ""
    
    private var selectedAddressId: String?
    private var selectedAddressCoordinate: Coordinate?
    
    // MARK: - UI

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    // bottom bar
    private let bottomBar = UIView()
    private let totalLabel = UILabel()
    private let payButton = UIButton(type: .system)

    init(cartItems: [CartItemDTO]) {
        self.cartItems = cartItems
        self.customCake = nil
        self.customCakeTitle = nil
        self.customCakePrice = nil
        super.init(nibName: nil, bundle: nil)
    }

    init(customCake: CustomCakeOrderDTO, title: String, price: Int) {
        self.cartItems = []
        self.customCake = customCake
        self.customCakeTitle = title
        self.customCakePrice = price
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        useRussianBackButtonTitle()
        view.backgroundColor = .systemBackground
        title = "Оформление заказа"

        setupTable()
        setupKeyboardDismiss()
        
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
                        self.userBonusBalance = me.bonusPoints
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
                    self.selectedAddressCoordinate = Coordinate(latitude: def.latitude, longitude: def.longitude)
                    
                    // собираем красивый сабтитл как у тебя в UI
                    var parts: [String] = [def.baseAddress]

                    if let e = def.entrance, !e.isEmpty {
                        parts.append("подъезд \(e)")
                    }
                    if let f = def.flat, !f.isEmpty {
                        parts.append("кв. \(f)")
                    }

                    self.selectedAddressSubtitle = parts.joined(separator: " • ")

                    self.tableView.reloadSections(IndexSet([Section.delivery.rawValue, Section.bonus.rawValue, Section.summary.rawValue]), with: .none)
                    self.refreshBottomBar()
                }
            } else {
                await MainActor.run {
                    self.selectedAddressTitle = nil
                    self.selectedAddressSubtitle = nil
                    self.selectedAddressId = nil
                    self.selectedAddressCoordinate = nil
                    self.tableView.reloadSections(IndexSet([Section.delivery.rawValue, Section.bonus.rawValue, Section.summary.rawValue]), with: .none)
                    self.refreshBottomBar()
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
        tableView.keyboardDismissMode = .interactive
        
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

    private func setupKeyboardDismiss() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(endEditing))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
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

        totalLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        totalLabel.numberOfLines = 0
        totalLabel.adjustsFontSizeToFitWidth = true
        totalLabel.minimumScaleFactor = 0.85
        totalLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        totalLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)

        payButton.setTitle("Подтвердить заказ", for: .normal)
        payButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        payButton.titleLabel?.adjustsFontSizeToFitWidth = true
        payButton.titleLabel?.minimumScaleFactor = 0.85
        payButton.titleLabel?.lineBreakMode = .byClipping
        payButton.contentEdgeInsets = UIEdgeInsets(top: 14, left: 14, bottom: 14, right: 14)
        payButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        payButton.setContentHuggingPriority(.required, for: .horizontal)
        payButton.layer.cornerRadius = 14
        payButton.backgroundColor = .systemBlue
        payButton.tintColor = .white
        payButton.addTarget(self, action: #selector(payTapped), for: .touchUpInside)

        let h = UIStackView(arrangedSubviews: [totalLabel, payButton])
        h.axis = .horizontal
        h.alignment = .center
        h.spacing = 10

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
        if let customCakePrice {
            return customCakePrice
        }
        // sum у тебя уже есть в CartItemDTO
        // округление если надо — здесь
        return cartItems.reduce(0) { $0 + Int($1.sum) }
    }

    private func deliveryFee() -> Int {
        // пример логики
        guard deliveryMode == .delivery else { return 0 }
        return cartTotal() >= DeliveryPricing.freeDeliveryThreshold ? 0 : DeliveryPricing.standardDeliveryFee
    }

    private func remainingAmountForFreeDelivery() -> Int {
        max(0, DeliveryPricing.freeDeliveryThreshold - cartTotal())
    }

    private func expectedDeliveryTimeText() -> String {
        guard deliveryMode == .delivery else {
            return "Самовывоз"
        }

        guard let coordinate = selectedAddressCoordinate else {
            return "Выберите адрес"
        }

        let distance = distanceKilometers(
            fromLatitude: PickupPoint.latitude,
            longitude: PickupPoint.longitude,
            toLatitude: coordinate.latitude,
            longitude: coordinate.longitude
        )

        return deliveryTimeText(for: distance)
    }

    private func deliveryTimeText(for distanceKilometers: Double) -> String {
        switch distanceKilometers {
        case ...5:
            return "30-40 минут"
        case ...10:
            return "50-60 минут"
        case ...20:
            return "100-120 минут"
        default:
            return "120-180 минут"
        }
    }

    private func distanceKilometers(
        fromLatitude: Double,
        longitude fromLongitude: Double,
        toLatitude: Double,
        longitude toLongitude: Double
    ) -> Double {
        let earthRadiusKilometers = 6371.0
        let fromLatitudeRadians = fromLatitude * .pi / 180
        let toLatitudeRadians = toLatitude * .pi / 180
        let deltaLatitude = (toLatitude - fromLatitude) * .pi / 180
        let deltaLongitude = (toLongitude - fromLongitude) * .pi / 180

        let a = sin(deltaLatitude / 2) * sin(deltaLatitude / 2)
            + cos(fromLatitudeRadians) * cos(toLatitudeRadians)
            * sin(deltaLongitude / 2) * sin(deltaLongitude / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))

        return earthRadiusKilometers * c
    }

    private func grandTotal() -> Int {
        max(0, cartTotal() - appliedBonusPoints()) + deliveryFee()
    }

    private func maxBonusPointsToSpend() -> Int {
        Int(floor(Double(cartTotal()) * 0.30))
    }

    private func appliedBonusPoints() -> Int {
        guard useBonusPoints else { return 0 }
        return min(userBonusBalance, maxBonusPointsToSpend())
    }

    private func expectedBonusEarned() -> Int {
        let rewardBase = max(0, cartTotal() - appliedBonusPoints())
        return Int(floor(Double(rewardBase) * 0.05))
    }

    private func formatRub(_ value: Int) -> String {
        "\(value) ₽"
    }

    private func refreshBottomBar() {
        let total = grandTotal()
        let bonusText = appliedBonusPoints() > 0 ? "\nСписано \(appliedBonusPoints()) бонусов" : ""
        totalLabel.text = "Итого: \(formatRub(total))\(bonusText)"
        let btnTitle = "Подтвердить заказ"
        payButton.setTitle(btnTitle, for: .normal)
        updatePayButtonState()
    }

    private func updatePayButtonState() {
        let hasPhone = !phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasAddressForDelivery = deliveryMode == .pickup || selectedAddressId != nil
        let hasOrderItems = cartTotal() > 0
        let isEnabled = hasOrderItems && hasPhone && hasAddressForDelivery

        payButton.isEnabled = isEnabled
        payButton.alpha = isEnabled ? 1.0 : 0.55
    }

    private func isInsideDeliveryArea(_ coordinate: Coordinate) -> Bool {
        (DeliveryArea.minLatitude...DeliveryArea.maxLatitude).contains(coordinate.latitude)
            && (DeliveryArea.minLongitude...DeliveryArea.maxLongitude).contains(coordinate.longitude)
    }

    private func validateDeliveryAreaBeforeOrder() -> Bool {
        guard deliveryMode == .delivery else { return true }

        guard let coordinate = selectedAddressCoordinate else {
            presentStub("Адрес не выбран", "Выбери адрес доставки.")
            return false
        }

        guard isInsideDeliveryArea(coordinate) else {
            presentStub(
                "Доставка недоступна",
                "Просим прощения, сейчас мы работаем только в Москве и Московской области. Пожалуйста, выберите другой адрес доставки."
            )
            return false
        }

        return true
    }

    private func presentStub(_ title: String, _ message: String, onOK: (() -> Void)? = nil) {
        let a = UIAlertController(title: title, message: message, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "Ок", style: .default) { _ in
            onOK?()
        })
        (navigationController?.visibleViewController ?? self).present(a, animated: true)
    }

    @objc private func endEditing() {
        view.endEditing(true)
    }

    // MARK: - Actions

    @objc private func payTapped() {
        view.endEditing(true)

        // 1) проверки
        if cartTotal() <= 0 {
            presentStub("Пустой заказ", "Добавьте товары, чтобы оформить заказ.")
            return
        }
        if deliveryMode == .delivery, selectedAddressId == nil {
            presentStub("Адрес не выбран", "Выбери адрес доставки.")
            return
        }
        guard validateDeliveryAreaBeforeOrder() else {
            return
        }
        if phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            presentStub("Телефон", "Укажи номер телефона.")
            return
        }
        // 2) собираем dto
        let dto = CreateOrderDTO(
            addressId: deliveryMode == .delivery ? selectedAddressId : nil,
            comment: commentText.isEmpty ? nil : commentText,
            paymentMode: (paymentMode == .card) ? "card" : "cash",
            deliveryMode: (deliveryMode == .delivery) ? "delivery" : "pickup",
            leaveAtDoor: (deliveryMode == .delivery) ? leaveAtDoor : nil,
            useBonusPoints: useBonusPoints,
            phone: phone,
            customCake: customCake
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
                        "Номер: \(formattedOrderNumber(order))\nСтатус: \(order.statusTitle)\nСумма: \(self.formatRub(order.totalPrice))\nОжидаемое время доставки: \(self.expectedDeliveryTimeText())\nСписано бонусов: \(order.bonusPointsSpent)"
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
        case .bonus: return 2
        case .payment: return PaymentMode.allCases.count
        case .comment: return 1  // оставляем только поле комментария
        case .summary: return deliveryMode == .delivery ? 4 : 3 // товары + доставка + время + бонусы
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let s = Section(rawValue: section) else { return nil }
        switch s {
        case .delivery: return "Доставка"
        case .payment: return "Оплата"
        case .bonus: return "Бонусы"
        case .comment: return "Пожелания"
        case .summary: return "Итог"
        }
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        guard let s = Section(rawValue: section) else { return nil }
        switch s {
        case .delivery:
            return nil
        case .bonus:
            return "1 бонус = 1 ₽. Можно оплатить до 30% стоимости товаров, новые бонусы начислятся после доставки."
        case .summary:
            if deliveryMode == .delivery, remainingAmountForFreeDelivery() > 0 {
                return "Закажите еще на \(formatRub(remainingAmountForFreeDelivery())) для бесплатной доставки."
            }
            return nil
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
                        title: selectedAddressTitle ?? "Адрес доставки",
                        subtitle: selectedAddressSubtitle ?? "Выбрать адрес",
                        value: nil,
                        icon: UIImage(systemName: "mappin.and.ellipse")
                    )
                } else {
                    cell.configure(
                        title: "Точка самовывоза",
                        subtitle: PickupPoint.address,
                        value: nil,
                        icon: UIImage(systemName: "fork.knife")
                    )
                }
                cell.accessoryType = deliveryMode == .delivery ? .disclosureIndicator : .none
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
                    self?.refreshBottomBar()
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
            
        case .bonus:
            if indexPath.row == 0 {
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: MakeOrderValueCell.reuseId,
                    for: indexPath
                ) as! MakeOrderValueCell
                cell.selectionStyle = .none
                cell.configure(
                    title: "Баланс",
                    subtitle: "Начислим за заказ: \(expectedBonusEarned())",
                    value: "\(userBonusBalance)",
                    icon: UIImage(systemName: "sparkles")
                )
                return cell
            }

            let cell = tableView.dequeueReusableCell(
                withIdentifier: MakeOrderSwitchCell.reuseId,
                for: indexPath
            ) as! MakeOrderSwitchCell
            cell.configure(
                title: "Списать \(appliedBonusPoints() > 0 ? appliedBonusPoints() : min(userBonusBalance, maxBonusPointsToSpend())) бонусов",
                isOn: useBonusPoints,
                icon: UIImage(systemName: "giftcard")
            )
            cell.onChange = { [weak self] value in
                guard let self else { return }
                self.useBonusPoints = value && self.userBonusBalance > 0
                self.refreshBottomBar()
                self.tableView.reloadSections(IndexSet([Section.bonus.rawValue, Section.summary.rawValue]), with: .none)
            }
            cell.selectionStyle = .none
            return cell

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
                cell.configure(
                    title: customCakeTitle ?? "Товары",
                    value: formatRub(cartTotal()),
                    icon: UIImage(systemName: customCake == nil ? "bag" : "birthday.cake")
                )
            } else if indexPath.row == 1 {
                let fee = deliveryFee()
                let value = (fee == 0) ? "Бесплатно" : formatRub(fee)
                let title = deliveryMode == .delivery ? "Доставка" : "Самовывоз"
                let icon = deliveryMode == .delivery ? UIImage(systemName: "bicycle") : UIImage(systemName: "bag")
                cell.configure(title: title, value: value, icon: icon)
            } else if deliveryMode == .delivery && indexPath.row == 2 {
                cell.configure(
                    title: "Ожидаемое время доставки",
                    value: expectedDeliveryTimeText(),
                    icon: UIImage(systemName: "clock")
                )
            } else {
                cell.configure(
                    title: "Бонусы",
                    value: appliedBonusPoints() > 0 ? "Списано \(appliedBonusPoints()) бонусов" : "0 бонусов",
                    icon: UIImage(systemName: "giftcard")
                )
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
                        IndexSet([Section.delivery.rawValue, Section.bonus.rawValue, Section.summary.rawValue]),
                        with: .automatic
                    )
                })

                sheet.addAction(UIAlertAction(title: "Самовывоз", style: .default) { [weak self] _ in
                    guard let self else { return }
                    self.deliveryMode = .pickup
                    self.leaveAtDoor = false
                    self.refreshBottomBar()

                    self.tableView.reloadSections(
                        IndexSet([Section.delivery.rawValue, Section.bonus.rawValue, Section.summary.rawValue]),
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

                    vc.canSelectAddress = { [weak self] address in
                        guard let self else { return true }

                        guard self.isInsideDeliveryArea(address.coordinate) else {
                            self.presentStub(
                                "Доставка недоступна",
                                "Просим прощения, сейчас мы работаем только в Москве и Московской области. Пожалуйста, выберите другой адрес доставки."
                            )
                            return false
                        }

                        return true
                    }

                    vc.onAddressSelected = { [weak self] a in
                        guard let self else { return }

                        guard self.isInsideDeliveryArea(a.coordinate) else {
                            self.presentStub(
                                "Доставка недоступна",
                                "Просим прощения, сейчас мы работаем только в Москве и Московской области. Пожалуйста, выберите другой адрес доставки."
                            )
                            return
                        }

                        self.selectedAddressTitle = a.title
                        self.selectedAddressId = a.id
                        self.selectedAddressCoordinate = a.coordinate
                        self.selectedAddressSubtitle = {
                            var parts: [String] = [a.baseAddress]
                            if let e = a.entrance, !e.isEmpty { parts.append("подъезд \(e)") }
                            if let f = a.flat, !f.isEmpty { parts.append("кв. \(f)") }
                            return parts.joined(separator: " • ")
                        }()
                        self.refreshBottomBar()

                        self.tableView.reloadSections(IndexSet([Section.delivery.rawValue, Section.bonus.rawValue, Section.summary.rawValue]), with: .none)
                    }

                    navigationController?.pushViewController(vc, animated: true)
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
        case .bonus:
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
        tv.returnKeyType = .done

        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneBtn = UIBarButtonItem(title: "Готово", style: .done, target: self, action: #selector(dismissKeyboard))
        toolbar.items = [spacer, doneBtn]
        tv.inputAccessoryView = toolbar

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

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        }

        return true
    }

    @objc private func dismissKeyboard() {
        tv.resignFirstResponder()
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

        // Кнопка "Готово" над клавиатурой phonePad
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneBtn = UIBarButtonItem(title: "Готово", style: .done, target: self, action: #selector(dismissKeyboard))
        toolbar.items = [spacer, doneBtn]
        textField.inputAccessoryView = toolbar

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
        textField.text = text.isEmpty ? "" : formatPhone(text)
    }

    @objc private func dismissKeyboard() {
        textField.resignFirstResponder()
    }

    // MARK: - Phone formatting

    private func formatPhone(_ input: String) -> String {
        var digits = input.filter { $0.isNumber }
        guard !digits.isEmpty else { return "" }

        if digits.hasPrefix("8") { digits = "7" + digits.dropFirst() }
        if !digits.hasPrefix("7") { digits = "7" + digits }
        digits = String(digits.prefix(11))

        let chars = Array(digits.dropFirst()) // цифры после кода страны "7"
        var result = "+7"

        if !chars.isEmpty {
            result += " (" + String(chars.prefix(3))
            if chars.count >= 3 { result += ")" }
        }
        if chars.count > 3 {
            result += " " + String(chars[3..<min(6, chars.count)])
        }
        if chars.count > 6 {
            result += "-" + String(chars[6..<min(8, chars.count)])
        }
        if chars.count > 8 {
            result += "-" + String(chars[8..<min(10, chars.count)])
        }

        return result
    }

    // MARK: - UITextFieldDelegate

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let current = textField.text ?? ""
        guard let swiftRange = Range(range, in: current) else { return false }
        let updated = current.replacingCharacters(in: swiftRange, with: string)

        let formatted = formatPhone(updated)
        textField.text = formatted
        onTextChange?(formatted)
        return false
    }
}
