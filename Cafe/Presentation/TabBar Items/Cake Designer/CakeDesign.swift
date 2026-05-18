import Foundation

struct CakeWeightOption: Decodable {
    let title: String
    let grams: Int
}

struct CakeDesignGalleryItem {
    let title: String
    let imageName: String
    let imageURLString: String?
}

struct CakeDesign: Decodable {
    let id: String
    let name: String
    let subtitle: String
    let imageName: String
    let imageURLString: String?
    let galleryImageNames: [String]
    let galleryImageURLStrings: [String]
    let filling: String
    let accent: String
    let composition: String
    let storage: String
    let kcalPer100g: Int
    let pricePerKg: Int
    let recommendedText: String
    let availableWeights: [CakeWeightOption]

    init(
        id: String,
        name: String,
        subtitle: String,
        imageName: String,
        imageURLString: String? = nil,
        galleryImageNames: [String] = [],
        galleryImageURLStrings: [String] = [],
        filling: String,
        accent: String,
        composition: String,
        storage: String,
        kcalPer100g: Int,
        pricePerKg: Int,
        recommendedText: String,
        availableWeights: [CakeWeightOption]
    ) {
        self.id = id
        self.name = name
        self.subtitle = subtitle
        self.imageName = imageName
        self.imageURLString = imageURLString
        self.galleryImageNames = galleryImageNames
        self.galleryImageURLStrings = galleryImageURLStrings
        self.filling = filling
        self.accent = accent
        self.composition = composition
        self.storage = storage
        self.kcalPer100g = kcalPer100g
        self.pricePerKg = pricePerKg
        self.recommendedText = recommendedText
        self.availableWeights = availableWeights
    }

    enum CodingKeys: String, CodingKey {
        case id, name, subtitle, imageName, imageURLString, galleryImageNames, galleryImageURLStrings
        case filling, accent, composition, storage, kcalPer100g, pricePerKg, recommendedText, availableWeights
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        subtitle = try container.decode(String.self, forKey: .subtitle)
        imageName = try container.decode(String.self, forKey: .imageName)
        imageURLString = try container.decodeIfPresent(String.self, forKey: .imageURLString)
        galleryImageNames = try container.decodeIfPresent([String].self, forKey: .galleryImageNames) ?? []
        galleryImageURLStrings = try container.decodeIfPresent([String].self, forKey: .galleryImageURLStrings) ?? []
        filling = try container.decode(String.self, forKey: .filling)
        accent = try container.decode(String.self, forKey: .accent)
        composition = try container.decode(String.self, forKey: .composition)
        storage = try container.decode(String.self, forKey: .storage)
        kcalPer100g = try container.decode(Int.self, forKey: .kcalPer100g)
        pricePerKg = try container.decode(Int.self, forKey: .pricePerKg)
        recommendedText = try container.decode(String.self, forKey: .recommendedText)
        availableWeights = try container.decode([CakeWeightOption].self, forKey: .availableWeights)
    }

    var galleryItems: [CakeDesignGalleryItem] {
        let defaultNames = [imageName, "\(imageName)_example", "\(imageName)_inside"]
        let titles = ["Основное фото", "Пример надписи", "Начинка / разрез"]
        return titles.enumerated().map { index, title in
            CakeDesignGalleryItem(
                title: title,
                imageName: galleryImageNames.indices.contains(index) ? galleryImageNames[index] : defaultNames[index],
                imageURLString: galleryImageURLStrings.indices.contains(index) ? galleryImageURLStrings[index] : nil
            )
        }
    }

    func price(for grams: Int) -> Int {
        Int((Double(pricePerKg) * Double(grams) / 1000.0).rounded())
    }

    func totalCalories(for grams: Int) -> Int {
        kcalPer100g * grams / 100
    }
}

extension CakeDesign {
    private static let standardWeights = [
        CakeWeightOption(title: "0,8 кг", grams: 800),
        CakeWeightOption(title: "1,2 кг", grams: 1200),
        CakeWeightOption(title: "1,5 кг", grams: 1500)
    ]

    static let mockDesigns: [CakeDesign] = [
        CakeDesign(
            id: "lutiki",
            name: "Лютики",
            subtitle: "Нежная цветочная композиция с местом под короткое поздравление",
            imageName: "cake_text_lutiki",
            filling: "Ванильный бисквит, малиновый конфитюр, фисташковое пюре",
            accent: "Свежие ягоды, белый шоколад и мягкая весенняя палитра",
            composition: "Ванильный бисквит, малиновый конфитюр, фисташковое пюре, сливки, кремчиз, ягоды свежие, белый шоколад.",
            storage: "0...+6 °C, 72 ч",
            kcalPer100g: 355,
            pricePerKg: 2250,
            recommendedText: "Лучше всего смотрится теплая надпись до 18 символов",
            availableWeights: standardWeights
        ),
        CakeDesign(
            id: "flower",
            name: "Цветочный",
            subtitle: "Светлый торт для дня рождения, признания или благодарности",
            imageName: "cake_text_flower",
            filling: "Ванильный бисквит, клубничный конфитюр, кремчиз",
            accent: "Белый шоколад и спокойный кремовый декор",
            composition: "Ванильный бисквит, клубничный конфитюр, сливки, кремчиз, красители пищевые, шоколад белый.",
            storage: "0...+6 °C, 72 ч",
            kcalPer100g: 325,
            pricePerKg: 2833,
            recommendedText: "Подходит для аккуратной надписи в одну строку",
            availableWeights: standardWeights
        ),
        CakeDesign(
            id: "roses",
            name: "Розы",
            subtitle: "Праздничная классика с выразительным цветочным оформлением",
            imageName: "cake_text_roses",
            filling: "Ванильный бисквит, клубничный конфитюр, сливочный крем",
            accent: "Розовый декор, белый шоколад и чистая зона для текста",
            composition: "Ванильный бисквит, клубничный конфитюр, сливки, кремчиз, красители пищевые, шоколад белый.",
            storage: "0...+6 °C, 72 ч",
            kcalPer100g: 325,
            pricePerKg: 2467,
            recommendedText: "Красиво работает с именем или короткой датой",
            availableWeights: standardWeights
        ),
        CakeDesign(
            id: "rafaelo-berries",
            name: "Рафаэло с ягодами",
            subtitle: "Белый шоколад, ягоды и мягкое праздничное настроение",
            imageName: "cake_text_rafaelo_berries",
            filling: "Ванильный бисквит, клубничный конфитюр, кремчиз",
            accent: "Молочный и белый шоколад, ягодные акценты",
            composition: "Ванильный бисквит, клубничный конфитюр, сливки, кремчиз, красители пищевые, шоколад белый, шоколад молочный.",
            storage: "0...+6 °C, 72 ч",
            kcalPer100g: 335,
            pricePerKg: 1909,
            recommendedText: "Оставляйте надпись короткой, чтобы сохранить легкий вид",
            availableWeights: standardWeights
        ),
        CakeDesign(
            id: "cloud",
            name: "Облачко",
            subtitle: "Воздушный светлый дизайн с яркими деталями и шоколадом",
            imageName: "cake_text_cloud",
            filling: "Ванильный бисквит, клубничный конфитюр, кремчиз",
            accent: "Белый, молочный, темный и цветной шоколад",
            composition: "Ванильный бисквит, клубничный конфитюр, сливки, кремчиз, красители пищевые, шоколад белый, шоколад молочный, шоколад горький, шоколад цветной.",
            storage: "0...+6 °C, 72 ч",
            kcalPer100g: 340,
            pricePerKg: 2043,
            recommendedText: "Подойдет для милой поздравительной фразы",
            availableWeights: standardWeights
        ),
        CakeDesign(
            id: "stump",
            name: "Пенёк",
            subtitle: "Шоколадный торт с тропической начинкой и теплым характером",
            imageName: "cake_text_stump",
            filling: "Шоколадный бисквит, манго, маракуйя, кремчиз",
            accent: "Насыщенный шоколадный декор и выразительная надпись",
            composition: "Шоколадный бисквит, манго конфитюр, маракуйя конфитюр, сливки, кремчиз, красители пищевые, шоколад белый, молочный, горький и цветной.",
            storage: "0...+6 °C, 72 ч",
            kcalPer100g: 350,
            pricePerKg: 2692,
            recommendedText: "Лучше смотрится контрастная надпись крупными буквами",
            availableWeights: standardWeights
        ),
        CakeDesign(
            id: "goose",
            name: "Праздничный гусь",
            subtitle: "Забавный акцентный дизайн для веселого праздника",
            imageName: "cake_text_goose",
            filling: "Шоколадный бисквит, персиковый конфитюр, кремчиз",
            accent: "Мультяшный декор и яркая композиция",
            composition: "Шоколадный бисквит, персиковый конфитюр, сливки, кремчиз, красители пищевые, шоколад белый, молочный, горький и цветной.",
            storage: "0...+6 °C, 72 ч",
            kcalPer100g: 350,
            pricePerKg: 2818,
            recommendedText: "Идеально для шутливой короткой фразы",
            availableWeights: standardWeights
        ),
        CakeDesign(
            id: "cat",
            name: "Котик",
            subtitle: "Милый шоколадный дизайн для детского или уютного праздника",
            imageName: "cake_text_cat",
            filling: "Шоколадный бисквит, персиковый конфитюр, кремчиз",
            accent: "Ласковый персонажный декор и чистая зона под имя",
            composition: "Шоколадный бисквит, персиковый конфитюр, сливки, кремчиз, красители пищевые, шоколад белый, молочный, горький и цветной.",
            storage: "0...+6 °C, 72 ч",
            kcalPer100g: 350,
            pricePerKg: 2667,
            recommendedText: "Хорошо смотрится имя и возраст",
            availableWeights: standardWeights
        ),
        CakeDesign(
            id: "space",
            name: "Космос",
            subtitle: "Темный эффектный дизайн с тропической начинкой",
            imageName: "cake_text_space",
            filling: "Шоколадный бисквит, манго, маракуйя, кремчиз",
            accent: "Глубокие оттенки, шоколадный декор и контрастный текст",
            composition: "Шоколадный бисквит, манго конфитюр, маракуйя конфитюр, сливки, кремчиз, красители пищевые, шоколад белый, молочный, горький и цветной.",
            storage: "0...+6 °C, 72 ч",
            kcalPer100g: 350,
            pricePerKg: 2333,
            recommendedText: "Выбирайте светлую надпись и короткое поздравление",
            availableWeights: standardWeights
        ),
        CakeDesign(
            id: "choco-berry",
            name: "Шоколадно-ягодный",
            subtitle: "Шоколадная основа, ягоды и насыщенный праздничный вид",
            imageName: "cake_text_choco_berry",
            filling: "Шоколадный бисквит, манго, маракуйя, ягоды",
            accent: "Молочный и горький шоколад со свежими ягодами",
            composition: "Шоколадный бисквит, манго конфитюр, маракуйя конфитюр, сливки, кремчиз, ягоды свежие, шоколад молочный, шоколад горький.",
            storage: "0...+6 °C, 72 ч",
            kcalPer100g: 348,
            pricePerKg: 2533,
            recommendedText: "Для надписи лучше выбрать одну строку без длинных слов",
            availableWeights: standardWeights
        )
    ]
}
