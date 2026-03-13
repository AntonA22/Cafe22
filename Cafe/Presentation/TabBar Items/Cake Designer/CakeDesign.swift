import Foundation

struct CakeWeightOption {
    let title: String
    let grams: Int
}

struct CakeDesign {
    let id: String
    let name: String
    let subtitle: String
    let imageName: String
    let filling: String
    let accent: String
    let kcalPer100g: Int
    let pricePerKg: Int
    let recommendedText: String
    let availableWeights: [CakeWeightOption]

    func price(for grams: Int) -> Int {
        Int((Double(pricePerKg) * Double(grams) / 1000.0).rounded())
    }

    func totalCalories(for grams: Int) -> Int {
        kcalPer100g * grams / 100
    }
}

extension CakeDesign {
    static let mockDesigns: [CakeDesign] = [
        CakeDesign(
            id: "berry-cloud",
            name: "Ягодное облако",
            subtitle: "Воздушный крем, живые ягоды, белый декор",
            imageName: "cheesecake",
            filling: "Ванильный бисквит, сливочный крем, клубничный конфитюр",
            accent: "Для нежного дня рождения или романтического вечера",
            kcalPer100g: 315,
            pricePerKg: 2900,
            recommendedText: "Надписи смотрятся особенно аккуратно на верхнем ярусе",
            availableWeights: [
                CakeWeightOption(title: "0.8 кг", grams: 800),
                CakeWeightOption(title: "1.4 кг", grams: 1400),
                CakeWeightOption(title: "2.0 кг", grams: 2000)
            ]
        ),
        CakeDesign(
            id: "pink-party",
            name: "Праздничный акцент",
            subtitle: "Яркий декор, ягодные мазки и вау-подача",
            imageName: "фото1",
            filling: "Шоколадный бисквит, крем-чиз, вишня",
            accent: "Подходит для вечеринки, детского праздника и сюрпризов",
            kcalPer100g: 338,
            pricePerKg: 3250,
            recommendedText: "Лучше всего смотрится короткая надпись до 18 символов",
            availableWeights: [
                CakeWeightOption(title: "1.0 кг", grams: 1000),
                CakeWeightOption(title: "1.8 кг", grams: 1800),
                CakeWeightOption(title: "2.5 кг", grams: 2500)
            ]
        ),
        CakeDesign(
            id: "golden-minimal",
            name: "Минимализм золото",
            subtitle: "Спокойный стиль, ровные линии и акцентный декор",
            imageName: "фото2",
            filling: "Красный бархат, сливочный мусс, малина",
            accent: "Для юбилея, свадьбы или подарка с персональной надписью",
            kcalPer100g: 298,
            pricePerKg: 3600,
            recommendedText: "Хорошо выглядит длинная надпись и спокойная палитра",
            availableWeights: [
                CakeWeightOption(title: "1.2 кг", grams: 1200),
                CakeWeightOption(title: "2.0 кг", grams: 2000),
                CakeWeightOption(title: "3.0 кг", grams: 3000)
            ]
        )
    ]
}
