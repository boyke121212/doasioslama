import Foundation
import UIKit

final class AuthManager {

    private let baseURL = AppConfig.BASE_URL
    private let securePrefs = SecurePrefs()
    private let endpoint: String

    // ======================================================
    // CONSTRUCTOR (SAMA DENGAN ANDROID)
    // ======================================================

    init(endpoint: String) {
        self.endpoint = endpoint
    }

    // ======================================================
    // ANTI RACE CONDITION
    // ======================================================

    private var isRefreshing = false
    private var waitingQueue: [() -> Void] = []

    private func refreshTokenSafe(
        onSuccess: @escaping () -> Void,
        onLogout: @escaping (String) -> Void
    ) {

        if isRefreshing {
            waitingQueue.append(onSuccess)
            return
        }

        isRefreshing = true

        refreshTokenOnly(
            onSuccess: {

                self.isRefreshing = false
                onSuccess()

                self.waitingQueue.forEach { $0() }
                self.waitingQueue.removeAll()
            },

            onLogout: { msg in
                self.isRefreshing = false
                self.waitingQueue.removeAll()
                onLogout(msg)
            }
        )
    }

    // ======================================================
    // CHECK AUTH
    // ======================================================

    func checkAuth(
        params: [String: String]? = nil,
        onSuccess: @escaping ([String: Any]) -> Void,
        onLogout: @escaping (String) -> Void,
        onLoading: @escaping (Bool) -> Void
    ) {

        if !Auto.isInternetAvailable() {
            onLoading(false)
            onLogout("Tidak ada koneksi internet")
            return
        }

        guard let accessToken = securePrefs.getAccessToken(),
              let refreshToken = securePrefs.getRefreshToken(),
              !accessToken.isEmpty,
              !refreshToken.isEmpty else {

            onLogout("Sesi tidak valid")
            return
        }

        requestAuth(
            accessToken: accessToken,
            params: params,
            onSuccess: onSuccess,
            onUnauthorized: {

                self.refreshTokenSafe(

                    onSuccess: {
                        self.checkAuth(
                            params: params,
                            onSuccess: onSuccess,
                            onLogout: onLogout,
                            onLoading: onLoading
                        )
                    },

                    onLogout: onLogout
                )
            },
            onError: { message in
                onLoading(false)
                self.showToast(message)
            },
            onLoading: onLoading
        )
    }

    // ======================================================
    // REQUEST AUTH
    // ======================================================

    private func requestAuth(
        accessToken: String,
        params: [String: String]?,
        onSuccess: @escaping ([String: Any]) -> Void,
        onUnauthorized: @escaping () -> Void,
        onError: @escaping (String) -> Void,
        onLoading: @escaping (Bool) -> Void
    ) {

        guard let url = URL(string: baseURL + endpoint) else {
            onError("URL tidak valid")
            return
        }

        onLoading(true)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(DeviceSecurityHelper.getDeviceHash(), forHTTPHeaderField: "X-Device-Hash")
        request.setValue(DeviceSecurityHelper.getAppSignatureHash(), forHTTPHeaderField: "X-App-Signature")
        request.setValue("ios", forHTTPHeaderField: "Platform")

        if let params = params {

            let bodyString = params
                .map { "\($0.key)=\($0.value)" }
                .joined(separator: "&")

            request.httpBody = bodyString.data(using: .utf8)
        }

        URLSession.shared.dataTask(with: request) { data, response, error in

            DispatchQueue.main.async {

                onLoading(false)

                if let error = error {
                    onError(error.localizedDescription)
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    onError("Response tidak valid")
                    return
                }

                if httpResponse.statusCode == 401 {
                    onUnauthorized()
                    return
                }

                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {

                    onError("Response server tidak valid")
                    return
                }

                if json["status"] as? String == "ok" {
                    onSuccess(json)
                } else {
                    onError(json["message"] as? String ?? "Terjadi kesalahan")
                }
            }

        }.resume()
    }

    // ======================================================
    // UPLOAD FOTO (PORT DARI uploadMultipartAuth)
    // ======================================================

    func uploadFoto(
        files: [URL]?,
        params: [String: String],
        onSuccess: @escaping ([String: Any]) -> Void,
        onError: @escaping (String) -> Void,
        onLogout: @escaping (String) -> Void,
        onLoading: @escaping (Bool) -> Void
    ) {

        if !Auto.isInternetAvailable() {
            onLoading(false)
            onLogout("Tidak ada koneksi internet")
            return
        }

        guard let accessToken = securePrefs.getAccessToken(),
              !accessToken.isEmpty else {

            onLogout("Sesi tidak valid")
            return
        }

        let realFiles = (files != nil && files!.isEmpty) ? nil : files

        guard let url = URL(string: baseURL + endpoint) else {
            onError("URL tidak valid")
            return
        }

        onLoading(true)

        let boundary = "Boundary-\(UUID().uuidString)"

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue(DeviceSecurityHelper.getDeviceHash(), forHTTPHeaderField: "X-Device-Hash")
        request.setValue(DeviceSecurityHelper.getAppSignatureHash(), forHTTPHeaderField: "X-App-Signature")
        request.setValue("ios", forHTTPHeaderField: "Platform")

        var body = Data()

        for (key, value) in params {

            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }

        realFiles?.enumerated().forEach { index, fileURL in

            guard let fileData = try? Data(contentsOf: fileURL) else { return }

            let mime: String

            if fileURL.path.lowercased().hasSuffix(".png") {
                mime = "image/png"
            } else if fileURL.path.lowercased().hasSuffix(".webp") {
                mime = "image/webp"
            } else {
                mime = "image/jpeg"
            }

            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append(
                "Content-Disposition: form-data; name=\"foto\(index + 1)\"; filename=\"\(fileURL.lastPathComponent)\"\r\n"
                    .data(using: .utf8)!
            )
            body.append("Content-Type: \(mime)\r\n\r\n".data(using: .utf8)!)
            body.append(fileData)
            body.append("\r\n".data(using: .utf8)!)
        }

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        URLSession.shared.dataTask(with: request) { data, response, error in

            DispatchQueue.main.async {

                onLoading(false)

                if let error = error {
                    onError(error.localizedDescription)
                    return
                }

                guard let http = response as? HTTPURLResponse else {
                    onError("Response tidak valid")
                    return
                }

                if http.statusCode == 401 {

                    self.refreshTokenSafe(

                        onSuccess: {
                            self.uploadFoto(
                                files: files,
                                params: params,
                                onSuccess: onSuccess,
                                onError: onError,
                                onLogout: onLogout,
                                onLoading: onLoading
                            )
                        },

                        onLogout: { message in
                            onLogout(message)
                        }
                    )

                    return
                }

                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {

                    onError("Response server tidak valid")
                    return
                }

                realFiles?.forEach { file in
                    try? FileManager.default.removeItem(at: file)
                }

                onSuccess(json)
            }

        }.resume()
    }

    // ======================================================
    // REFRESH TOKEN
    // ======================================================

    private func refreshTokenOnly(
        onSuccess: @escaping () -> Void,
        onLogout: @escaping (String) -> Void
    ) {

        guard let refreshToken = securePrefs.getRefreshToken(),
              !refreshToken.isEmpty else {

            onLogout("Refresh token tidak ditemukan")
            return
        }

        guard let url = URL(string: baseURL + AppConfig.refresh) else {
            onLogout("URL refresh tidak valid")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        request.setValue("Bearer \(refreshToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(DeviceSecurityHelper.getDeviceHash(), forHTTPHeaderField: "X-Device-Hash")
        request.setValue(DeviceSecurityHelper.getAppSignatureHash(), forHTTPHeaderField: "X-App-Signature")
        request.setValue("ios", forHTTPHeaderField: "Platform")

        URLSession.shared.dataTask(with: request) { data, response, error in

            DispatchQueue.main.async {

                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {

                    onLogout("Response refresh tidak valid")
                    return
                }

                let newAccess = json["access_token"] as? String ?? ""
                let newRefresh = json["refresh_token"] as? String ?? ""

                if newAccess.isEmpty || newRefresh.isEmpty {

                    onLogout("Refresh token tidak valid")
                    return
                }

                self.securePrefs.saveAccessToken(newAccess)
                self.securePrefs.saveRefreshToken(newRefresh)

                onSuccess()
            }

        }.resume()
    }

    // ======================================================
    // TOAST
    // ======================================================

    private func showToast(_ message: String) {

        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first,
              let root = window.rootViewController else {
            return
        }

        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        root.present(alert, animated: true)
    }
}
