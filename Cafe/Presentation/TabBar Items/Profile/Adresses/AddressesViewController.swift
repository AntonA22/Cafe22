

//
//  AddressesViewController.swift
//  Cafe
//
//  Created by Антон Абалуев on 03.02.2026.
//

import UIKit
import YandexMapsMobile
import CoreLocation

struct Coordinate {
    let latitude: Double
    let longitude: Double
}

final class AddressesViewController: UIViewController {
    private enum DeliveryArea {
        static let minLatitude = 54.25
        static let maxLatitude = 56.95
        static let minLongitude = 35.15
        static let maxLongitude = 40.25
    }

    // MARK: UI
    private let mapView: YMKMapView = YMKMapView(frame: .zero)!
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let emptyLabel = UILabel()

    // MARK: Data (mock)
//    private var addresses: [Address] = [
//        Address(
//            title: "Дом",
//            baseAddress: "ул. Тверская, 7, Москва",
//            coordinate: Coordinate(latitude: 55.7576, longitude: 37.6130)
//        ),
//        Address(
//            title: "Работа",
//            baseAddress: "Москва-Сити, Пресненская наб., 8",
//            coordinate: Coordinate(latitude: 55.7499, longitude: 37.5392)
//        )
//    ]
    private var addresses: [Address] = []
    private var selectedId: String?
    private var placemarkById: [String: YMKPlacemarkMapObject] = [:]
    var canSelectAddress: ((Address) -> Bool)?
    var onAddressSelected: ((Address) -> Void)?


    // Чтобы можно было (при желании) выделять выбранный пин и т.п.

    override func viewDidLoad() {
        super.viewDidLoad()
        useRussianBackButtonTitle()
        title = "Адреса"
        view.backgroundColor = .systemBackground

        setupUI()
        setupNavBar()

        Task { await loadAddresses() }
    }
    
    @MainActor
    private func loadAddresses() async {
        do {
            let dtos = try await AddressService.shared.getAddresses()
            self.addresses = dtos.map(Address.init(dto:))
            if let def = self.addresses.first(where: { $0.isDefault }) {
                self.selectedId = def.id
            } else {
                self.selectedId = self.addresses.first?.id
            }
            self.tableView.reloadData()
            self.updateEmptyState()
            self.refreshMap()
        } catch {
            print("getAddresses error:", error)
            self.updateEmptyState()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        YMKMapKit.sharedInstance().onStart()  // важно  [oai_citation:2‡Yandex](https://yandex.com/maps-api/docs/mapkit/Swift/YMKMapKit.html?utm_source=chatgpt.com)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        YMKMapKit.sharedInstance().onStop()   // важно  [oai_citation:3‡Yandex](https://yandex.com/maps-api/docs/mapkit/Swift/YMKMapKit.html?utm_source=chatgpt.com)
    }

    private func makeOrderSubtitle(for a: Address) -> String {
        var parts: [String] = [a.baseAddress]
        if let e = a.entrance, !e.isEmpty { parts.append("подъезд \(e)") }
        if let f = a.flat, !f.isEmpty { parts.append("кв. \(f)") }
        return parts.joined(separator: " • ")
    }
    
    private func setupNavBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addTapped)
        )
    }

    private func setupUI() {
        mapView.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(mapView)
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapView.heightAnchor.constraint(equalToConstant: 220),

            tableView.topAnchor.constraint(equalTo: mapView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(AddressCell.self, forCellReuseIdentifier: "AddressCell")

        emptyLabel.text = "Нет адресов"
        emptyLabel.font = .preferredFont(forTextStyle: .body)
        emptyLabel.textColor = .secondaryLabel
        emptyLabel.textAlignment = .center
        emptyLabel.numberOfLines = 0
        tableView.backgroundView = emptyLabel
        updateEmptyState()
    }

    @objc private func addTapped() {
        let vc = AddAddressViewController()
        vc.onSave = { [weak self] newAddress in
            guard let self else { return }
            self.addresses.append(newAddress)
            self.tableView.reloadData()
            self.updateEmptyState()
            self.refreshMap(focusOn: newAddress)
        }

        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }

    private func deleteAddress(at index: Int) {
        let removed = addresses[index]
        let idToDelete = removed.id

        Task { @MainActor in
            do {
                try await AddressService.shared.deleteAddress(id: idToDelete)

                // ✅ обновляем UI ЛОКАЛЬНО (сервер уже удалил)
                self.addresses.remove(at: index)

                if self.selectedId == idToDelete {
                    self.selectedId = self.addresses.first?.id
                }

                self.tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
                self.updateEmptyState()
                self.refreshMap()
            } catch {
                print("deleteAddress error:", error)
                
            }
        }
    }

    private func refreshMap(focusOn address: Address? = nil) {
        let map = mapView.mapWindow.map
        map.mapObjects.clear()
        placemarkById.removeAll()

        for a in addresses {
            let point = YMKPoint(latitude: a.coordinate.latitude, longitude: a.coordinate.longitude)
            let placemark = map.mapObjects.addPlacemark(with: point)

            let image = UIImage(systemName: "mappin.circle.fill")?
                .withTintColor(view.tintColor, renderingMode: .alwaysOriginal)
            if let image { placemark.setIconWith(image) }

            placemarkById[a.id] = placemark
        }

        if let address {
            centerMap(on: address.coordinate)
        } else if let first = addresses.first {
            centerMap(on: first.coordinate)
        }
    }

    private func centerMap(on coordinate: Coordinate) {
        let point = YMKPoint(latitude: coordinate.latitude, longitude: coordinate.longitude)

        let position = YMKCameraPosition(
            target: point,
            zoom: 15,     // ~как твои 2500м, можно подстроить
            azimuth: 0,
            tilt: 0
        )

        mapView.mapWindow.map.move(
            with: position,
            animation: YMKAnimation(type: .smooth, duration: 0.35),
            cameraCallback: nil
        )
    }

    private func showDeleteConfirm(index: Int) {
        let ac = UIAlertController(title: "Удалить адрес?", message: nil, preferredStyle: .actionSheet)
        ac.addAction(UIAlertAction(title: "Удалить", style: .destructive) { [weak self] _ in
            self?.deleteAddress(at: index)
        })
        ac.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        present(ac, animated: true)
    }

    private func showAlert(_ message: String) {
        let alert = UIAlertController(title: "Доставка недоступна", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ок", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITableView

extension AddressesViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int { 1 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        addresses.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let address = addresses[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "AddressCell", for: indexPath) as! AddressCell

        var cfg = cell.defaultContentConfiguration()
        cfg.text = address.title
        cfg.secondaryText = address.subtitle
        cell.contentConfiguration = cfg

        cell.setChecked(address.id == selectedId)

        cell.onCheckboxTap = { [weak self] in
            guard let self else { return }

            guard self.canSelectAddress?(address) ?? self.validateAddressSelection(address) else {
                UIView.performWithoutAnimation {
                    self.tableView.reloadData()
                }
                return
            }

            Task { @MainActor in
                do {
                    // ✅ 1) Говорим серверу, что это адрес по умолчанию
                    let selectedDTO = try await AddressService.shared
                        .setDefaultAddress(id: address.id)
                    let selected = Address(dto: selectedDTO)

                    for index in self.addresses.indices {
                        self.addresses[index].isDefault = self.addresses[index].id == selected.id
                        if self.addresses[index].id == selected.id {
                            self.addresses[index] = selected
                        }
                    }

                    self.selectedId = selected.id

                    // ✅ 4) Обновляем UI без дёрганий
                    UIView.performWithoutAnimation {
                        self.tableView.reloadData()
                    }

                    // ✅ 5) Центрируем карту
                    self.centerMap(on: address.coordinate)
                    
                    // ✅ сообщаем назад и закрываем экран
                    self.onAddressSelected?(selected)
                    //self.navigationController?.popViewController(animated: true)

                } catch {
                    print("setDefault error:", error)
                }
            }
        }

        cell.backgroundConfiguration = .listGroupedCell()
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let address = addresses[indexPath.row]

        let vc = AddAddressViewController(edit: address)
        vc.onSave = { [weak self] updated in
            guard let self else { return }

            if let idx = self.addresses.firstIndex(where: { $0.id == updated.id }) {
                self.addresses[idx] = updated
            } else {
                self.addresses.append(updated)
            }

            self.tableView.reloadData()
            self.updateEmptyState()
            self.refreshMap(focusOn: updated)
        }

        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }

    func tableView(_ tableView: UITableView,
                   contextMenuConfigurationForRowAt indexPath: IndexPath,
                   point: CGPoint) -> UIContextMenuConfiguration? {

        let address = addresses[indexPath.row]

        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ in
            guard let self else { return UIMenu() }

            let select = UIAction(title: "Выбрать", image: UIImage(systemName: "checkmark.circle")) { _ in
                guard self.canSelectAddress?(address) ?? self.validateAddressSelection(address) else {
                    UIView.performWithoutAnimation {
                        self.tableView.reloadData()
                    }
                    return
                }

                self.selectedId = address.id
                self.tableView.reloadData()
                self.centerMap(on: address.coordinate)
            }

            let edit = UIAction(title: "Изменить", image: UIImage(systemName: "pencil")) { _ in
                // открыть тот же редактор
                self.tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
                self.tableView.delegate?.tableView?(tableView, didSelectRowAt: indexPath)
            }

            let delete = UIAction(title: "Удалить", image: UIImage(systemName: "trash"), attributes: .destructive) { _ in
                self.showDeleteConfirm(index: indexPath.row)
            }

            return UIMenu(title: "", children: [select, edit, delete])
        }
    }

    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath)
    -> UISwipeActionsConfiguration? {

        let delete = UIContextualAction(style: .destructive, title: "Удалить") { [weak self] _, _, done in
            self?.showDeleteConfirm(index: indexPath.row)
            done(true)
        }

        return UISwipeActionsConfiguration(actions: [delete])
    }

    private func updateEmptyState() {
        emptyLabel.isHidden = !addresses.isEmpty
    }

    private func validateAddressSelection(_ address: Address) -> Bool {
        guard isInsideDeliveryArea(address.coordinate) else {
            showAlert("Просим прощения, сейчас мы работаем только в Москве и Московской области. Пожалуйста, выберите другой адрес доставки.")
            return false
        }

        return true
    }

    private func isInsideDeliveryArea(_ coordinate: Coordinate) -> Bool {
        (DeliveryArea.minLatitude...DeliveryArea.maxLatitude).contains(coordinate.latitude)
            && (DeliveryArea.minLongitude...DeliveryArea.maxLongitude).contains(coordinate.longitude)
    }
}
