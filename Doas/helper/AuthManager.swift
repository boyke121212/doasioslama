import Foundation
import UIKit

final class AuthManager {

    private let baseURL = AppConfig.BASE_URL
    private let securePrefs = SecurePrefs()

    // =========================================================
    // ANTI RACE CONDITION
    // =========================================================

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

    // =========================================================
    // PUBLIC API
    // =========================================================

    func checkAuth(
        endpoint: String,
        params: [String: String]? = nil,
        onSuccess: @escaping ([String: Any]) -> Void,
        onLogout: @escaping (String) -> Void,
        onLoading: @escaping (Bool) -> Void
    ) {

        guard ensureInternet(onLoading: onLoading, onLogout: onLogout) else { return }

        guard let accessToken = securePrefs.getAccessToken(),
              let refreshToken = securePrefs.getRefreshToken(),
              !accessToken.isEmpty,
              !refreshToken.isEmpty else {

            onLogout("Sesi tidak valid")
            forceLogout()
            return
        }

        requestAuth(
            endpoint: endpoint,
            accessToken: accessToken,
            params: params,
            onLoading: onLoading,
            onSuccess: onSuccess,
            onUnauthorized: {

                onLoading(false)

                self.refreshTokenSafe(
                    onSuccess: {
                        self.checkAuth(
                            endpoint: endpoint,
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
            }
        )
    }

    // =========================================================
    // REQUEST AUTH
    // =========================================================

    private func requestAuth(
        endpoint: String,
        accessToken: String,
        params: [String: String]?,
        onLoading: @escaping (Bool) -> Void,
        onSuccess: @escaping ([String: Any]) -> Void,
        onUnauthorized: @escaping () -> Void,
        onError: @escaping (String) -> Void
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

    // =========================================================
    // REFRESH TOKEN
    // =========================================================

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

                if let httpResponse = response as? HTTPURLResponse,
                   httpResponse.statusCode == 401 {

                    self.securePrefs.clear()
                    onLogout("Sesi berakhir")
                    return
                }

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

    // =========================================================
    // FORCE LOGOUT
    // =========================================================

    func forceLogout() {
        securePrefs.clear()

        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first else {
            return
        }

        window.rootViewController = LoginPage()
        window.makeKeyAndVisible()
    }

    // =========================================================
    // INTERNET CHECK
    // =========================================================

    private func ensureInternet(
        onLoading: ((Bool) -> Void)?,
        onLogout: ((String) -> Void)?
    ) -> Bool {

        if !Auto.isInternetAvailable() {
            onLoading?(false)
            onLogout?("Tidak ada koneksi internet")
            return false
        }

        return true
    }

    private func showToast(_ message: String) {

        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first,
              let root = window.rootViewController else {
            return
        }

        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        root.present(alert, animated: true)
    }
}//
//  AuthManager.swift
//  Doas
//
//  Created by Admin on 03/03/26.
//

