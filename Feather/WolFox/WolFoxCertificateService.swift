import Foundation
import UIKit

struct WolFoxRemoteCertificate: Decodable {
	let devp12: String?
	let devmp: String?
	let p12Password: String?
	let devName: String?
    let expireTime: Int?
    let planSelected: String?
    let certType: String?
    let udid: String?
    let usesPrimarySigningFields: Bool

    var hasSigningAssets: Bool {
        guard let devp12, let devmp, !devp12.isEmpty, !devmp.isEmpty else { return false }
        return Data(base64Encoded: devp12, options: .ignoreUnknownCharacters) != nil
            && Data(base64Encoded: devmp, options: .ignoreUnknownCharacters) != nil
    }

    enum CodingKeys: String, CodingKey {
		case devp12, devmp, udid
		case p12Password = "p12_password"
		case password
        case devName = "dev_name"
        case expireTime = "expire_time"
        case planSelected = "plan_selected"
        case certType = "cert_type"
        case p12, mobileProvision = "mobileprovision"
        case extraMobileProvision = "extra_mobile_provision"
        case name, pname
        case devCertType = "dev_cert_type"
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let primaryP12 = try values.decodeIfPresent(String.self, forKey: .devp12)
        let primaryProvision = try values.decodeIfPresent(String.self, forKey: .devmp)
        let fallbackP12 = try values.decodeIfPresent(String.self, forKey: .p12)
        let fallbackProvision = try values.decodeIfPresent(String.self, forKey: .mobileProvision)
        let extraProvision = try values.decodeIfPresent(String.self, forKey: .extraMobileProvision)

		devp12 = primaryP12 ?? fallbackP12
		devmp = primaryProvision ?? fallbackProvision ?? extraProvision
		p12Password = try values.decodeIfPresent(String.self, forKey: .p12Password)
			?? values.decodeIfPresent(String.self, forKey: .password)
		devName = try values.decodeIfPresent(String.self, forKey: .devName)
            ?? (try values.decodeIfPresent(String.self, forKey: .name))
            ?? (try values.decodeIfPresent(String.self, forKey: .pname))
        expireTime = try values.decodeIfPresent(Int.self, forKey: .expireTime)
        planSelected = try values.decodeIfPresent(String.self, forKey: .planSelected)
        certType = try values.decodeIfPresent(String.self, forKey: .certType)
            ?? (try values.decodeIfPresent(String.self, forKey: .devCertType))
        udid = try values.decodeIfPresent(String.self, forKey: .udid)
        usesPrimarySigningFields = !(primaryP12?.isEmpty ?? true) && !(primaryProvision?.isEmpty ?? true)
    }
}

enum WolFoxCertificateError: LocalizedError {
    case unavailableForDevice
    case server(Int)
    case invalidResponse
	case incompletePayload
	case missingPassword
	case validationFailed

    var errorDescription: String? {
        switch self {
        case .unavailableForDevice:
            return "لا توجد شهادة مسجلة لهذا الجهاز في الخادم الخارجي. انسخ معرف الجهاز وسجّله لدى المزوّد ثم أعد المحاولة."
        case .server(let status):
            return "تعذر الاتصال بخادم الشهادات (HTTP \(status))."
        case .invalidResponse:
            return "استجابة خادم الشهادات غير صالحة."
		case .incompletePayload:
			return "بيانات الشهادة المستلمة غير مكتملة."
		case .missingPassword:
			return "لم يرسل خادم الشهادات كلمة مرور صريحة للشهادة؛ تم إيقاف الاستيراد الآمن."
		case .validationFailed:
            return "تعذر التحقق من صحة الشهادة المستلمة."
        }
    }
}

enum WolFoxCertificateService {
	static let endpoint = WolFoxRepository.certificateProviderURL
    private static let installationIdentifierKey = "WolFox.installIdentifier"
    private static let certificateUDIDKey = "WolFox.certificateUDID"

    static var providerName: String {
        endpoint.host ?? "خادم الشهادات الخارجي"
    }

    static func deviceIdentifier() -> String {
        if let value = UserDefaults.standard.string(forKey: installationIdentifierKey), !value.isEmpty { return value }
        let value = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        UserDefaults.standard.set(value, forKey: installationIdentifierKey)
        return value
    }

    static var registeredUDID: String? {
        let value = UserDefaults.standard.string(forKey: certificateUDIDKey)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return isValidUDID(value) ? value : nil
    }

    static var usesRegisteredUDID: Bool {
        registeredUDID != nil
    }

    static func certificateLookupIdentifier() -> String {
        registeredUDID ?? deviceIdentifier()
    }

    static func saveRegisteredUDID(_ value: String) -> Bool {
        let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isValidUDID(normalized) else { return false }
        UserDefaults.standard.set(normalized, forKey: certificateUDIDKey)
        return true
    }

    static func clearRegisteredUDID() {
        UserDefaults.standard.removeObject(forKey: certificateUDIDKey)
    }

    static func maskedLookupIdentifier() -> String {
        let value = certificateLookupIdentifier()
        guard value.count > 12 else { return value }
        return "\(value.prefix(8))••••\(value.suffix(4))"
    }

    private static func isValidUDID(_ value: String) -> Bool {
        value.range(of: "^[A-Za-z0-9-]{16,64}$", options: .regularExpression) != nil
    }

	static func fetch(completion: @escaping (Result<WolFoxRemoteCertificate, Error>) -> Void) {
		guard WolFoxRepository.isAllowedCertificateURL(endpoint) else {
			completion(.failure(WolFoxCertificateError.invalidResponse))
			return
		}
		var parts = URLComponents(url: endpoint, resolvingAgainstBaseURL: false)!
        parts.queryItems = [URLQueryItem(name: "udid", value: certificateLookupIdentifier())]

        URLSession.shared.dataTask(with: parts.url!) { data, response, error in
            if let error {
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }

            guard let http = response as? HTTPURLResponse else {
                DispatchQueue.main.async { completion(.failure(WolFoxCertificateError.invalidResponse)) }
                return
            }
			guard http.url?.host?.lowercased() == endpoint.host?.lowercased(),
				  (200...299).contains(http.statusCode),
				  WolFoxRepository.isJSONResponse(http),
				  let data, data.count <= 10 * 1024 * 1024 else {
                let error: Error = http.statusCode == 404
                    ? WolFoxCertificateError.unavailableForDevice
                    : WolFoxCertificateError.server(http.statusCode)
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }

            do {
                let decoder = JSONDecoder()
                let certificates: [WolFoxRemoteCertificate]
                if let list = try? decoder.decode([WolFoxRemoteCertificate].self, from: data) {
                    certificates = list
                } else {
                    certificates = [try decoder.decode(WolFoxRemoteCertificate.self, from: data)]
                }

                let certificate = certificates.first(where: { $0.usesPrimarySigningFields && $0.hasSigningAssets })
                    ?? certificates.first(where: { $0.hasSigningAssets })
                guard let certificate else { throw WolFoxCertificateError.unavailableForDevice }
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
			  let password = certificate.p12Password?.trimmingCharacters(in: .whitespacesAndNewlines),
			  !password.isEmpty,
			  let p12URL = FileManager.default.decodeAndWrite(base64: p12, pathComponent: ".p12"),
			  let provisionURL = FileManager.default.decodeAndWrite(base64: provision, pathComponent: ".mobileprovision") else {
			completion(certificate.p12Password == nil ? WolFoxCertificateError.missingPassword : WolFoxCertificateError.incompletePayload)
			return
		}
		guard FR.checkPasswordForCertificate(for: p12URL, with: password, using: provisionURL) else {
            completion(WolFoxCertificateError.validationFailed)
            return
        }
        FR.handleCertificateFiles(
			p12URL: p12URL,
			provisionURL: provisionURL,
			p12Password: password,
            certificateName: certificate.devName ?? "WolFox Device Certificate"
        ) { error in
            completion(error)
        }
    }
}
