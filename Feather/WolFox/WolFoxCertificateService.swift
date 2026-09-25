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

enum WolFoxCertificateService {
    static let endpoint = URL(string: "https://api.nekoo.eu.org/certificate/public")!
    static let p12Password = "1"

    static func deviceIdentifier() -> String {
        let key = "WolFox.installIdentifier"
        if let value = UserDefaults.standard.string(forKey: key), !value.isEmpty { return value }
        let value = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        UserDefaults.standard.set(value, forKey: key)
        return value
    }

    static func fetch(completion: @escaping (Result<WolFoxRemoteCertificate, Error>) -> Void) {
        var parts = URLComponents(url: endpoint, resolvingAgainstBaseURL: false)!
        parts.queryItems = [URLQueryItem(name: "udid", value: deviceIdentifier())]
        URLSession.shared.dataTask(with: parts.url!) { data, response, error in
            if let error { DispatchQueue.main.async { completion(.failure(error)) }; return }
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode), let data else {
                let code = (response as? HTTPURLResponse)?.statusCode ?? -1
                let error = NSError(domain: "WolFoxCertificateService", code: code, userInfo: [NSLocalizedDescriptionKey: "No certificate found for this device"])
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }
            do {
                let list = try JSONDecoder().decode([WolFoxRemoteCertificate].self, from: data)
                guard let certificate = list.first else {
                    throw NSError(domain: "WolFoxCertificateService", code: 404, userInfo: [NSLocalizedDescriptionKey: "No certificate found for this device"])
                }
                DispatchQueue.main.async { completion(.success(certificate)) }
            } catch {
                DispatchQueue.main.async { completion(.failure(error)) }
            }
        }.resume()
    }

    static func importCertificate(_ certificate: WolFoxRemoteCertificate, completion: @escaping (Error?) -> Void) {
        guard let p12 = certificate.devp12, let provision = certificate.devmp,
              let p12URL = FileManager.default.decodeAndWrite(base64: p12, pathComponent: ".p12"),
              let provisionURL = FileManager.default.decodeAndWrite(base64: provision, pathComponent: ".mobileprovision") else {
            completion(NSError(domain: "WolFoxCertificateService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Certificate payload is incomplete"]))
            return
        }
        guard FR.checkPasswordForCertificate(for: p12URL, with: p12Password, using: provisionURL) else {
            completion(NSError(domain: "WolFoxCertificateService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Certificate validation failed"]))
            return
        }
        FR.handleCertificateFiles(p12URL: p12URL, provisionURL: provisionURL, p12Password: p12Password, certificateName: certificate.devName ?? "WolFox Device Certificate") { error in
            completion(error)
        }
    }
}
