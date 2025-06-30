import Foundation

nonisolated enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case network(URLError.Code)
    case server(statusCode: Int, message: String?)
    case decoding(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Некорректный адрес запроса."
        case .invalidResponse:
            return "Сервер вернул некорректный ответ."
        case .network(let code):
            switch code {
            case .notConnectedToInternet, .networkConnectionLost:
                return "Нет подключения к интернету."
            case .cannotFindHost, .cannotConnectToHost, .dnsLookupFailed:
                return "Не удалось подключиться к серверу."
            case .timedOut:
                return "Сервер не ответил вовремя. Попробуйте ещё раз."
            case .secureConnectionFailed, .serverCertificateUntrusted:
                return "Не удалось установить защищённое соединение."
            default:
                return "Ошибка сети. Попробуйте ещё раз."
            }
        case .server(let statusCode, _) where statusCode == 401:
            return "Войдите в аккаунт, чтобы выполнить это действие."
        case .server(_, let message):
            return message ?? "Не удалось выполнить запрос."
        case .decoding:
            return "Не удалось прочитать ответ сервера."
        }
    }
}
