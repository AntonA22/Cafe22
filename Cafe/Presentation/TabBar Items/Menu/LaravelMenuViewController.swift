import UIKit
import Supabase
import Foundation

struct MenuItem {
    let id: Int
    let name: String
    let price: Int
    let imageName: String
    var qty: Int = 0
}

class LaravelMenuCell: UICollectionViewCell {

    private var productId: Int?
    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    private let addToCartButton = UIButton(type: .system)
    private let cartImageView = UIImageView()
    
    weak var parentViewController: UIViewController?

    
    private var quantity: Int = 0 {
        didSet { updateCartUI() }
    }
    private let qtyContainer = UIStackView()
    private let qtyBackgroundView = UIView()
    private let minusButton = UIButton(type: .system)
    private let qtyLabel = UILabel()
    private let plusButton = UIButton(type: .system)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func imageTapped(_ sender: UITapGestureRecognizer) {
        guard let tappedImageView = sender.view as? UIImageView else { return }
        let imageTag = tappedImageView.tag
        print("Image tapped \(imageTag)")
        
        let detailVC = ProductDetailViewController()
        detailVC.productId = imageTag
        
        if let sheet = detailVC.sheetPresentationController {
            sheet.detents = [.medium(), .large()] // поддерживаем оба размера
            sheet.selectedDetentIdentifier = .large // сразу открываем на больший размер
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 16
        }
        
        parentViewController?.present(detailVC, animated: true)
    }
    
    private func setupUI() {
        contentView.backgroundColor = .white
        contentView.layer.cornerRadius = 12
        contentView.layer.borderWidth = 1
        contentView.layer.borderColor = UIColor.lightGray.cgColor
        contentView.clipsToBounds = true

        // Tap on image
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(imageTapped))
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(tapGesture)

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true

        titleLabel.font = .systemFont(ofSize: 14, weight: .regular)
        titleLabel.numberOfLines = 2
        titleLabel.textAlignment = .center

        // addToCartButton
        addToCartButton.backgroundColor = .systemBlue
        addToCartButton.tintColor = .white
        addToCartButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .bold)
        addToCartButton.layer.cornerRadius = 10
        addToCartButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        addToCartButton.addTarget(self, action: #selector(addToCartTapped), for: .touchUpInside)

        cartImageView.image = UIImage(systemName: "cart.fill")
        cartImageView.tintColor = .white
        cartImageView.contentMode = .scaleAspectFit

        // qtyContainer
        qtyContainer.axis = .horizontal
        qtyContainer.alignment = .center
        qtyContainer.distribution = .equalCentering
        qtyContainer.spacing = 12
//        qtyContainer.isHidden = true

        minusButton.setImage(UIImage(systemName: "minus.circle.fill"), for: .normal)
        minusButton.tintColor = .systemBlue
        minusButton.addTarget(self, action: #selector(minusTapped), for: .touchUpInside)

        plusButton.setImage(UIImage(systemName: "plus.circle.fill"), for: .normal)
        plusButton.tintColor = .systemBlue
        plusButton.addTarget(self, action: #selector(plusTapped), for: .touchUpInside)
        
        minusButton.contentEdgeInsets = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
        plusButton.contentEdgeInsets  = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)

        qtyLabel.textColor = .label
        qtyLabel.font = .systemFont(ofSize: 15, weight: .semibold)

        qtyBackgroundView.layer.borderWidth = 1
        qtyBackgroundView.layer.borderColor = UIColor.systemGray4.cgColor

        qtyLabel.font = .systemFont(ofSize: 16, weight: .bold)
        qtyLabel.textAlignment = .center
        qtyLabel.setContentHuggingPriority(.required, for: .horizontal)
        
        qtyBackgroundView.backgroundColor = UIColor.systemGray6
        qtyBackgroundView.layer.cornerRadius = 16
        qtyBackgroundView.clipsToBounds = true
        
        qtyBackgroundView.addSubview(qtyContainer)
        qtyBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        qtyContainer.translatesAutoresizingMaskIntoConstraints = false

        qtyBackgroundView.isHidden = true // по умолчанию скрыт

        qtyContainer.addArrangedSubview(minusButton)
        qtyContainer.addArrangedSubview(qtyLabel)
        qtyContainer.addArrangedSubview(plusButton)

        // controlsStack: в нём либо кнопка, либо qty (оба на одном месте)
        let controlsStack = UIView()
        controlsStack.translatesAutoresizingMaskIntoConstraints = false
        controlsStack.addSubview(addToCartButton)
        controlsStack.addSubview(qtyBackgroundView)

        addToCartButton.translatesAutoresizingMaskIntoConstraints = false
        qtyContainer.translatesAutoresizingMaskIntoConstraints = false

        // image container (без внутренних отступов)
        contentView.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false

        // info stack (с отступами)
        let infoStack = UIStackView(arrangedSubviews: [titleLabel, controlsStack])
        infoStack.axis = .vertical
        infoStack.spacing = 10
        infoStack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(infoStack)

        // cart icon inside button
        addToCartButton.addSubview(cartImageView)
        cartImageView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // Image flush to card edges
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            // высота картинки как доля ширины (можно 0.6–0.75)
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 0.62),

            // info stack below image with padding
            infoStack.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 10),
            infoStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            infoStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            infoStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),

            // controlsStack height
            controlsStack.heightAnchor.constraint(greaterThanOrEqualToConstant: 36),

            // button/qty fill controlsStack
            addToCartButton.topAnchor.constraint(equalTo: controlsStack.topAnchor),
            addToCartButton.leadingAnchor.constraint(equalTo: controlsStack.leadingAnchor),
            addToCartButton.trailingAnchor.constraint(equalTo: controlsStack.trailingAnchor),
            addToCartButton.bottomAnchor.constraint(equalTo: controlsStack.bottomAnchor),

            // qtyBackgroundView fills controlsStack
            qtyBackgroundView.topAnchor.constraint(equalTo: controlsStack.topAnchor),
            qtyBackgroundView.leadingAnchor.constraint(equalTo: controlsStack.leadingAnchor),
            qtyBackgroundView.trailingAnchor.constraint(equalTo: controlsStack.trailingAnchor),
            qtyBackgroundView.bottomAnchor.constraint(equalTo: controlsStack.bottomAnchor),

            // qtyContainer inside qtyBackgroundView with padding
            qtyContainer.topAnchor.constraint(equalTo: qtyBackgroundView.topAnchor, constant: 6),
            qtyContainer.leadingAnchor.constraint(equalTo: qtyBackgroundView.leadingAnchor, constant: 12),
            qtyContainer.trailingAnchor.constraint(equalTo: qtyBackgroundView.trailingAnchor, constant: -12),
            qtyContainer.bottomAnchor.constraint(equalTo: qtyBackgroundView.bottomAnchor, constant: -6),
            
            // cart icon
            cartImageView.trailingAnchor.constraint(equalTo: addToCartButton.trailingAnchor, constant: -10),
            cartImageView.centerYAnchor.constraint(equalTo: addToCartButton.centerYAnchor),
            cartImageView.widthAnchor.constraint(equalToConstant: 18),
            cartImageView.heightAnchor.constraint(equalToConstant: 18),
        ])
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()

        let radius: CGFloat = 12
        contentView.layer.cornerRadius = radius
        contentView.clipsToBounds = true

        // скругляем ТОЛЬКО верхние углы картинки
        let path = UIBezierPath(
            roundedRect: imageView.bounds,
            byRoundingCorners: [.topLeft, .topRight],
            cornerRadii: CGSize(width: radius, height: radius)
        )
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        imageView.layer.mask = mask
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        productId = nil
        imageView.image = nil
        titleLabel.text = nil
        quantity = 0
    }

    func configure(item: MenuItem) {
        self.productId = item.id
        titleLabel.text = item.name
        addToCartButton.setTitle("\(item.price) ₽", for: .normal)
        imageView.image = UIImage(named: item.imageName)
        imageView.tag = item.id;
        
        // пока не знаем qty с сервера — ставим 0
        // позже можно прокинуть qty из модели MenuItem
        quantity = item.qty
    }
    
    private func updateCartUI() {
        // quantity == 0 -> показываем кнопку цены
        let inCart = quantity > 0

        addToCartButton.isHidden = inCart
        qtyBackgroundView.isHidden = !inCart

        qtyLabel.text = "\(max(quantity, 1))"
    }
    
    @objc private func addToCartTapped() {
        guard let productId else { return }

        Task {
            do {
                await setControlsEnabled(false)

                let cart = try await CartService.shared.addItem(dessertId: productId, qty: 1)
                let serverQty = cart.items.first(where: { $0.dessertId == productId })?.qty ?? 1

                await MainActor.run { self.quantity = serverQty }
            } catch {
                print("addToCart error:", error.localizedDescription)
            }

            await setControlsEnabled(true)
        }
    }

    @objc private func plusTapped() {
        guard let productId else { return }

        Task {
            do {
                await setControlsEnabled(false)

                let targetQty = quantity + 1
                let cart = try await CartService.shared.setQty(dessertId: productId, qty: targetQty)
                let serverQty = cart.items.first(where: { $0.dessertId == productId })?.qty ?? targetQty

                await MainActor.run { self.quantity = serverQty }
            } catch {
                print("plusTapped error:", error.localizedDescription)
            }

            await setControlsEnabled(true)
        }
    }

    @objc private func minusTapped() {
        guard let productId else { return }

        Task {
            do {
                await setControlsEnabled(false)

                let targetQty = quantity - 1

                if targetQty <= 0 {
                    let cart = try await CartService.shared.removeItem(dessertId: productId)

                    // после удаления товара его уже нет в items -> qty = 0
                    let serverQty = cart.items.first(where: { $0.dessertId == productId })?.qty ?? 0
                    await MainActor.run { self.quantity = serverQty }
                } else {
                    let cart = try await CartService.shared.setQty(dessertId: productId, qty: targetQty)
                    let serverQty = cart.items.first(where: { $0.dessertId == productId })?.qty ?? targetQty
                    await MainActor.run { self.quantity = serverQty }
                }
            } catch {
                print("minusTapped error:", error.localizedDescription)
            }

            await setControlsEnabled(true)
        }
    }
    
    private func setControlsEnabled(_ enabled: Bool) async {
        await MainActor.run {
            self.addToCartButton.isEnabled = enabled
            self.plusButton.isEnabled = enabled
            self.minusButton.isEnabled = enabled
        }
    }
}

class LaravelMenuViewController: UIViewController {
    
    private var collectionView: UICollectionView!
    
    private let sectionInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
    private let itemSpacing: CGFloat = 12
    private let lineSpacing: CGFloat = 12
    private let searchTextField = UITextField()
    private let searchButton = UIButton()
    // Тут будут данные меню (пока мок)
    var items: [MenuItem] = [
       // MenuItem(name: "Капучино", price: 180, imageName: "cappuccino"),
       // MenuItem(name: "Латте", price: 190, imageName: "latte"),
//        MenuItem(name: "Эклер", price: 240, imageName: "eclair"),
//        MenuItem(name: "Чизкейк", price: 320, imageName: "cheesecake")
    ]
    
    private func loadData() {
        Task {
            do {
                async let productsTask = ProductsService.shared.fetchProducts()
                async let cartTask = CartService.shared.getCart()

                let products = try await productsTask
                let cartResponse = try await cartTask

                // qtyById: dessert_id -> qty
                let qtyById: [Int: Int] = Dictionary(
                    uniqueKeysWithValues: cartResponse.items.map { ($0.dessertId, $0.qty) }
                )

                let mapped: [MenuItem] = products.map { product in
                    MenuItem(
                        id: product.id,
                        name: product.name,
                        price: Int(product.price),
                        imageName: "eclair",
                        qty: qtyById[product.id] ?? 0
                    )
                }

                await MainActor.run {
                    self.items = mapped
                    self.collectionView.reloadData()
                }

            } catch {
                print("Load menu/cart error:", error.localizedDescription)
            }
        }
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Меню"
        view.backgroundColor = .white
        
        // Устанавливаем иконку для Tab Bar
        let forkSpoonImage = UIImage(systemName: "fork.knife") // SF Symbol "fork.knife"
        tabBarItem = UITabBarItem(title: "Меню", image: forkSpoonImage, selectedImage: forkSpoonImage)
        
        setupCollection()
        setupConstraints()
        loadData()
    }
      private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Поле поиска
            searchTextField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            searchTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            searchTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            searchTextField.heightAnchor.constraint(equalToConstant: 44),
            
            // Кнопка поиска
            searchButton.topAnchor.constraint(equalTo: searchTextField.bottomAnchor, constant: 20),
            searchButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            searchButton.widthAnchor.constraint(equalToConstant: 120),
            searchButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }




    @objc private func searchButtonTapped() {
         view.endEditing(true)
        guard let query = searchTextField.text, !query.isEmpty else {
            print("Введите запрос для поиска")
            return
        }
        
        Task {
            do {
                let products = try await ProductsService.shared.searchProducts(body: SearchDTO(query: query))
                print("Найдено товаров: \(products.count)")
                print(products)

                //добавляем products в массив
                //обновляем список товаров
                       let mapped: [MenuItem] = products.map { product in
                    MenuItem(
                        id: product.id,
                        name: product.name,
                        price: Int(product.price),
                        imageName: "eclair",
                       // qty: qtyById[product.id] ?? 0
                    )
                }


                  await MainActor.run {
                    self.items = mapped
                    self.collectionView.reloadData()
                }


            } catch {
                print("Ошибка поиска: \(error)")
            }
        }
    }
    private func setupCollection() {
    // Настраиваем текстовое поле
    searchTextField.placeholder = "Введите запрос..."
    searchTextField.borderStyle = .roundedRect
    searchTextField.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(searchTextField)
    
    // Настраиваем кнопку
    searchButton.setTitle("Поиск", for: .normal)
    searchButton.backgroundColor = .systemBlue
    searchButton.setTitleColor(.white, for: .normal)
    searchButton.layer.cornerRadius = 10
    searchButton.addTarget(self, action: #selector(searchButtonTapped), for: .touchUpInside)
    searchButton.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(searchButton)

    // CollectionView
    let layout = UICollectionViewFlowLayout()
    layout.minimumInteritemSpacing = itemSpacing
    layout.minimumLineSpacing = lineSpacing
    layout.sectionInset = sectionInsets

    collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
    collectionView.backgroundColor = .white
    collectionView.dataSource = self
    collectionView.delegate = self

    collectionView.register(LaravelMenuCell.self, forCellWithReuseIdentifier: "LaravelMenuCell")

    view.addSubview(collectionView)
    collectionView.translatesAutoresizingMaskIntoConstraints = false

    // 🔥 ИСПРАВЛЕННЫЕ КОНСТРЕЙНТЫ
    NSLayoutConstraint.activate([
        // Поле поиска
        searchTextField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
        searchTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
        searchTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
        searchTextField.heightAnchor.constraint(equalToConstant: 44),
        
        // Кнопка поиска
        searchButton.topAnchor.constraint(equalTo: searchTextField.bottomAnchor, constant: 12),
        searchButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        searchButton.widthAnchor.constraint(equalToConstant: 120),
        searchButton.heightAnchor.constraint(equalToConstant: 44),
        
        // CollectionView - ПОД кнопкой поиска
        collectionView.topAnchor.constraint(equalTo: searchButton.bottomAnchor, constant: 16),
        collectionView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
        collectionView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
        collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
    ])
}
}

extension LaravelMenuViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {

        let columns: CGFloat = 2

        let width = collectionView.bounds.width
        let insets = sectionInsets.left + sectionInsets.right
        let totalSpacing = (columns - 1) * itemSpacing
        let itemWidth = floor((width - insets - totalSpacing) / columns)

        // высоту подгони под себя (чуть выше, чтобы текст+кнопки не давили картинку)
        let itemHeight = itemWidth * 1.1

        return CGSize(width: itemWidth, height: itemHeight)
    }
}

extension LaravelMenuViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        return items.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "LaravelMenuCell", for: indexPath) as! LaravelMenuCell
        cell.configure(item: items[indexPath.row])
        cell.parentViewController = self // если self — это UICollectionViewController / UIViewController
        return cell
    }
}
