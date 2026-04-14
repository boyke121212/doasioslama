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

            //onLogout("Sesi tidak valid")
            self.forceLogout(message: " dari access kosong Anda telah Logout")
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

    func forceLogout(message: String) {

        securePrefs.clear()

        self.securePrefs.clear()

        let alert = UIAlertController(
            title: "Informasi",
            message: message,
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            self.goToMainActivity()
        })
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

            //onLogout("Sesi tidak valid")
            self.forceLogout(message: "Sesi Tidak Valid")
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

                guard let data = data else {
                    onLogout("Response kosong")
                    return
                }

                do {
                    
                    let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
                    
                    let status = json["status"] as? Int ?? 0
                    
                    let messages = json["messages"] as? [String: Any]
                    let message = messages?["error"] as? String ?? "Terjadi kesalahan"
                    
                    // ===== jika backend kirim 401 =====
                    if status == 401 {

                        self.securePrefs.clear()

                        let alert = UIAlertController(
                            title: "Informasi",
                            message: message,
                            preferredStyle: .alert
                        )

                        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                            self.goToMainActivity()
                        })

                        return
                    }
                

                    // ===== jika sukses =====
                    let newAccess = json["access_token"] as? String ?? ""
                    let newRefresh = json["refresh_token"] as? String ?? ""

                    if newAccess.isEmpty || newRefresh.isEmpty {
                        self.forceLogout(message: "Anda Harus Login Ulang")
                      //  onLogout(message)
                        return
                    }

                    self.securePrefs.saveAccessToken(newAccess)
                    self.securePrefs.saveRefreshToken(newRefresh)

                    onSuccess()

                } catch {

                    onLogout("Response server tidak valid")
                }
            }

        }.resume()
    }

    // ======================================================
    // TOAST
    // ======================================================

//    private func showToast(_ message: String) {
//
//        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
//              let window = scene.windows.first,
//              let root = window.rootViewController else {
//            return
//        }
//
//        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
//        root.present(alert, animated: true)
//    }
    
    private func showToast(_ message: String) {
        DispatchQueue.main.async {
            // Cara modern mengambil window di iOS 15+ untuk menghindari warning deprecation
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first(where: { $0.isKeyWindow }),
                  var topController = window.rootViewController else {
                return
            }

            // Cari ViewController paling atas (agar alert tidak tertutup modal lain)
            while let presented = topController.presentedViewController {
                topController = presented
            }

            // Mencegah alert muncul tumpang tindih jika sudah ada alert yang tampil
            if topController is UIAlertController { return }

            let alert = UIAlertController(title: "Informasi", message: message, preferredStyle: .alert)
            
            // Tambahkan tombol OK agar alert bisa di-dismiss
            let refreshAction = UIAlertAction(title: "Refresh", style: .default) { _ in
                if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = scene.windows.first {
                    
                    // Kita panggil Home() baru untuk memastikan state di-reset total
                    window.rootViewController = Home()
                    window.makeKeyAndVisible()
                }
            }
            
            alert.addAction(refreshAction)
            
            // 4. Tambahkan tombol OK/Tutup agar alert bisa di-dismiss manual
            alert.addAction(UIAlertAction(title: "Tutup", style: .cancel, handler: nil))
            
            topController.present(alert, animated: true)
        }
    }
    
    func goToMainActivity() {

        let vc = MainActivity()

        guard let window = UIApplication.shared
            .connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?
            .windows
            .first else { return }

        window.rootViewController = vc
        window.makeKeyAndVisible()
    }
}
