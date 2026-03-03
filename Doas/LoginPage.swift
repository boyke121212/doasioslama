import UIKit

final class LoginPage: UIViewController {
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private let headerAccent = UIView()
    private let cardView = UIView()
    
    private let logoImageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let divider = UIView()
    
    private let usernameField = UITextField()
    private let passwordField = UITextField()
    private let loginButton = UIButton(type: .system)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    // =================================================
    // UI SETUP
    // =================================================
    
    private func setupUI() {
        view.backgroundColor = UIColor(red: 244/255, green: 246/255, blue: 248/255, alpha: 1)
        
        // =========================
        // SCROLL VIEW
        // =========================
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        
        // =========================
        // HEADER ACCENT
        // =========================
        headerAccent.backgroundColor = UIColor(red: 41/255, green: 98/255, blue: 255/255, alpha: 1)
        headerAccent.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(headerAccent)
        
        NSLayoutConstraint.activate([
            headerAccent.topAnchor.constraint(equalTo: contentView.topAnchor),
            headerAccent.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            headerAccent.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            headerAccent.heightAnchor.constraint(equalToConstant: 160)
        ])
        
        // =========================
        // CARD VIEW
        // =========================
        cardView.backgroundColor = .white
        cardView.layer.cornerRadius = 22
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.2
        cardView.layer.shadowOffset = CGSize(width: 0, height: 6)
        cardView.layer.shadowRadius = 12
        cardView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(cardView)
        
        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: headerAccent.bottomAnchor, constant: -80),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24)
        ])
        
        // =========================
        // INNER STACK
        // =========================
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 14
        stack.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(stack)
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 28),
            stack.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -28),
            stack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 28),
            stack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -28)
        ])
        
        // =========================
        // LOGO
        // =========================
        logoImageView.contentMode = .scaleAspectFit
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        
        if let url = Bundle.main.url(forResource: "doas2", withExtension: "png"),
           let data = try? Data(contentsOf: url),
           let image = UIImage(data: data) {
            logoImageView.image = image
        }
        
        NSLayoutConstraint.activate([
            logoImageView.heightAnchor.constraint(equalToConstant: 88)
        ])
        
        // =========================
        // TITLE
        // =========================
        titleLabel.text = "Masuk ke DOAS"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 22)
        titleLabel.textAlignment = .center
        
        subtitleLabel.text = "Data Anda Adalah Tanggung Jawab Anda"
        subtitleLabel.font = UIFont.systemFont(ofSize: 14)
        subtitleLabel.textColor = .gray
        subtitleLabel.textAlignment = .center
        
        divider.backgroundColor = UIColor(red: 41/255, green: 98/255, blue: 255/255, alpha: 1)
        divider.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            divider.heightAnchor.constraint(equalToConstant: 4),
            divider.widthAnchor.constraint(equalToConstant: 40)
        ])
        
        // =========================
        // TEXTFIELDS
        // =========================
        usernameField.placeholder = "Username"
        usernameField.borderStyle = .roundedRect
        
        passwordField.placeholder = "Password"
        passwordField.borderStyle = .roundedRect
        passwordField.isSecureTextEntry = true
        
        // =========================
        // BUTTON
        // =========================
        loginButton.setTitle("LOGIN", for: .normal)
        loginButton.setTitleColor(.white, for: .normal)
        loginButton.backgroundColor = UIColor(red: 41/255, green: 98/255, blue: 255/255, alpha: 1)
        loginButton.layer.cornerRadius = 16
        loginButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            loginButton.heightAnchor.constraint(equalToConstant: 54)
        ])
        
        loginButton.addTarget(self, action: #selector(handleLogin), for: .touchUpInside)
        
        // Add to stack
        stack.addArrangedSubview(logoImageView)
        stack.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(subtitleLabel)
        stack.addArrangedSubview(divider)
        stack.addArrangedSubview(usernameField)
        stack.addArrangedSubview(passwordField)
        stack.addArrangedSubview(loginButton)
        
        // Bottom constraint
        cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40).isActive = true
    }
    
    // =================================================
    // LOGIN ACTION
    // =================================================
    
    @objc private func handleLogin() {

        let username = usernameField.text ?? ""
        let password = passwordField.text ?? ""

        if username.isEmpty || password.isEmpty {
            showAlert("Username dan Password harus diisi")
            return
        }

        guard let url = URL(string: "\(AppConfig.BASE_URL)cekdata") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        // ===== DEVICE SECURITY =====
        let deviceHash = DeviceSecurityHelper.getDeviceHash()
        let appSignature = DeviceSecurityHelper.getAppSignatureHash()

        let isRooted = DeviceSecurityHelper.isDeviceJailbroken()
        let isEmulator = DeviceSecurityHelper.isEmulator()
        let isDebug = DeviceSecurityHelper.isDebuggable()

        let params: [String: String] = [
            "username": username,
            "password": password,

            "device_hash": deviceHash,
            "app_signature": appSignature,

            "is_rooted": isRooted ? "1" : "0",
            "is_emulator": isEmulator ? "1" : "0",
            "is_fake_gps": "0",
            "is_debug": isDebug ? "1" : "0",
            "is_installer_valid": "1",

            "platform": "ios"
        ]

        let bodyString = params
            .map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }
            .joined(separator: "&")

        request.httpBody = bodyString.data(using: .utf8)

        URLSession.shared.dataTask(with: request) { data, response, error in

            DispatchQueue.main.async {

                if let error = error {
                    self.showAlert(error.localizedDescription)
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    self.showAlert("Response tidak valid")
                    return
                }

                guard let data = data else {
                    self.showAlert("Response kosong")
                    return
                }

                if httpResponse.statusCode != 200 {
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        self.showAlert(json["message"] as? String ?? "Login gagal")
                    } else {
                        self.showAlert("Login gagal")
                    }
                    return
                }

                guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    self.showAlert("Response tidak valid")
                    return
                }

                if json["status"] as? String == "success" {

                    let accessToken = json["access_token"] as? String ?? ""
                    let refreshToken = json["refresh_token"] as? String ?? ""

                    SecurePrefs().saveAccessToken(accessToken)
                    SecurePrefs().saveRefreshToken(refreshToken)

                    self.logboundFlow()

                } else {
                    self.showAlert(json["message"] as? String ?? "Login gagal")
                }
            }

        }.resume()
    }
    
    private func showAlert(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    private func logboundFlow() {

        AuthManager().checkAuth(
            endpoint: "api/auth-check",
            params: nil,
            onSuccess: { json in

                guard let aesKey = json["aes_key"] as? String else {
                    self.showAlert("AES Key tidak ditemukan")
                    return
                }

                let prefs = SecurePrefs()
                prefs.saveAesKey(aesKey)

                let home = Home()
                home.modalPresentationStyle = .fullScreen
                self.present(home, animated: true)
            },
            onLogout: { message in
                self.showAlert(message)
            },
            onLoading: { _ in }
        )
    }
}

