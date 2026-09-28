import Foundation
import UIKit

struct WolFoxRemoteCertificate: Decodable {
    let devp12: String?
    let devmp: String?
    let devName: String?
    let expireTime: Int?
    let planSelected: String?
    let certType: String?
    let udid: String?

    enum CodingKeys: String, CodingKey {
        case devp12, devmp, udid
        case devName = "dev_name"
        case expireTime = "expire_time"
        case planSelected = "plan_selected"
        case certType = "cert_type"
    }
}

enum WolFoxCertificateError: LocalizedError {
    case unavailableForDevice
    case server(Int)
    case invalidResponse
    case incompletePayload
    case validationFailed

    var errorDescription: String? {
        switch self {
        case .unavailableForDevice:
            return "لا توجد شهادة مسجلة لهذا الجهاز في الخادم الخارجي."
        case .server(let status):
            return "تعذر الاتصال بخادم الشهادات (HTTP \(status))."
        case .invalidResponse:
            return "استجابة خادم الشهادات غير صالحة."
        case .incompletePayload:
            return "بيانات الشهادة المستلمة غير مكتملة."
        case .validationFailed:
            return "تعذر التحقق من صحة الشهادة المستلمة."
        }
    }
}

enum WolFoxCertificateService {
    static let endpoint = WolFoxRepository.certificateProviderURL
    static let p12Password = "1"

    static var providerName: String {
        endpoint.host ?? "خادم الشهادات الخارجي"
    }

    static func deviceIdentifier() -> String {
        let key = "WolFox.installIdentifier"
        if let value = UserDefaults.standard.string(forKey: key), !value.isEmpty { return value }
        let value = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        UserDefaults.standard.set(value, forKey: key)
        return value
    }

    static func maskedDeviceIdentifier() -> String {
        let value = deviceIdentifier()
        guard value.count > 12 else { return value }
        return "\(value.prefix(8))••••\(value.suffix(4))"
    }

    static func fetch(completion: @escaping (Result<WolFoxRemoteCertificate, Error>) -> Void) {
        var parts = URLComponents(url: endpoint, resolvingAgainstBaseURL: false)!
        parts.queryItems = [URLQueryItem(name: "udid", value: deviceIdentifier())]

        URLSession.shared.dataTask(with: parts.url!) { data, response, error in
            if let error {
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }

            guard let http = response as? HTTPURLResponse else {
                DispatchQueue.main.async { completion(.failure(WolFoxCertificateError.invalidResponse)) }
                return
            }
            guard (200...299).contains(http.statusCode), let data else {
                let error: Error = http.statusCode == 404
                    ? WolFoxCertificateError.unavailableForDevice
                    : WolFoxCertificateError.server(http.statusCode)
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }

            do {
                let decoder = JSONDecoder()
                let certificate: WolFoxRemoteCertificate
                if let list = try? decoder.decode([WolFoxRemoteCertificate].self, from: data) {
                    guard let first = list.first else { throw WolFoxCertificateError.unavailableForDevice }
                    certificate = first
                } else {
                    certificate = try decoder.decode(WolFoxRemoteCertificate.self, from: data)
                }
                DispatchQueue.main.async { completion(.success(certificate)) }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error is WolFoxCertificateError ? error : WolFoxCertificateError.invalidResponse))
                }
            }
        }.resume()
    }

    static func importCertificate(_ certificate: WolFoxRemoteCertificate, completion: @escaping (Error?) -> Void) {
        guard let p12 = certificate.devp12,
              let provision = certificate.devmp,
              let p12URL = FileManager.default.decodeAndWrite(base64: p12, pathComponent: ".p12"),
              let provisionURL = FileManager.default.decodeAndWrite(base64: provision, pathComponent: ".mobileprovision") else {
            completion(WolFoxCertificateError.incompletePayload)
            return
        }
        guard FR.checkPasswordForCertificate(for: p12URL, with: p12Password, using: provisionURL) else {
            completion(WolFoxCertificateError.validationFailed)
            return
        }
        FR.handleCertificateFiles(
            p12URL: p12URL,
            provisionURL: provisionURL,
            p12Password: p12Password,
            certificateName: certificate.devName ?? "WolFox Device Certificate"
        ) { error in
            completion(error)
        }
    }
}
