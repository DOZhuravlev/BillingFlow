import Foundation

struct DocumentUnit: Identifiable, Hashable, Sendable {
    let id: String
    let shortName: String
    let fullName: String

    init(shortName: String, fullName: String) {
        self.id = shortName
        self.shortName = shortName
        self.fullName = fullName
    }
}

extension DocumentUnit {
    static let piece = DocumentUnit(shortName: "шт", fullName: "Штука")
    static let service = DocumentUnit(shortName: "усл.", fullName: "Услуга")
    static let set = DocumentUnit(shortName: "компл.", fullName: "Комплект")
    static let package = DocumentUnit(shortName: "упак.", fullName: "Упаковка")
    static let box = DocumentUnit(shortName: "кор.", fullName: "Коробка")
    static let pair = DocumentUnit(shortName: "пар.", fullName: "Пара")
    static let roll = DocumentUnit(shortName: "рул.", fullName: "Рулон")
    static let place = DocumentUnit(shortName: "мест", fullName: "Место")
    static let hour = DocumentUnit(shortName: "ч", fullName: "Час")
    static let day = DocumentUnit(shortName: "дн.", fullName: "День")
    static let month = DocumentUnit(shortName: "мес.", fullName: "Месяц")
    static let meter = DocumentUnit(shortName: "м", fullName: "Метр")
    static let centimeter = DocumentUnit(shortName: "см", fullName: "Сантиметр")
    static let kilometer = DocumentUnit(shortName: "км", fullName: "Километр")
    static let squareMeter = DocumentUnit(shortName: "м²", fullName: "Квадратный метр")
    static let cubicMeter = DocumentUnit(shortName: "м³", fullName: "Кубический метр")
    static let gram = DocumentUnit(shortName: "г", fullName: "Грамм")
    static let kilogram = DocumentUnit(shortName: "кг", fullName: "Килограмм")
    static let ton = DocumentUnit(shortName: "т", fullName: "Тонна")
    static let milliliter = DocumentUnit(shortName: "мл", fullName: "Миллилитр")
    static let liter = DocumentUnit(shortName: "л", fullName: "Литр")

    static let all: [DocumentUnit] = [
        .piece, .service, .set, .package, .box, .pair, .roll, .place,
        .hour, .day, .month,
        .meter, .centimeter, .kilometer, .squareMeter, .cubicMeter,
        .gram, .kilogram, .ton, .milliliter, .liter
    ]
}
