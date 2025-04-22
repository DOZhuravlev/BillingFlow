import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case server(statusCode: Int, message: String?)
    case decoding(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Некорректный адрес запроса."
        case .invalidResponse:
            return "Сервер вернул некорректный ответ."
        case .server(_, let message):
            return message ?? "Не удалось выполнить запрос."
        case .decoding:
            return "Не удалось прочитать ответ сервера."
        }
    }
}
