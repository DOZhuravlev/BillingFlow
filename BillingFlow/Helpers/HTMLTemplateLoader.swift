import Foundation

enum HTMLTemplateLoader {

    enum Template: String {
        case invoice
        case act
        case deliveryNote

        var fileName: String { rawValue }
    }

    static func load(_ template: Template) throws -> String {
        guard let url = Bundle.main.url(
            forResource: template.fileName,
            withExtension: "html"
        ) else {
            throw LoaderError.templateNotFound(template)
        }

        return try String(contentsOf: url, encoding: .utf8)
    }
}

extension HTMLTemplateLoader {
    enum LoaderError: LocalizedError {
        case templateNotFound(Template)

        var errorDescription: String? {
            switch self {
            case .templateNotFound(let template):
                return "Не удалось найти \(template.fileName).html в bundle приложения."
            }
        }
    }
}
