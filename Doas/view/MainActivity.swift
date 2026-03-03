import UIKit

final class MainActivity: UIViewController {
    
    private let backgroundImageView = UIImageView()
    private let logoImageView = UIImageView()
    private let bottomStack = UIStackView()
    private let tvBareskrim = UILabel()
    private let btLogin = UIButton(type: .system)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Auto.cleanTempPhotos()
        checkLogin()   // pindahkan ke sini
    }
    
    private func setupUI() {
        view.backgroundColor = .black
        
        // =========================
        // BACKGROUND (MATCH_PARENT)
        // =========================
        backgroundImageView.image = UIImage(named: "opening")
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backgroundImageView)
        
        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        // =========================
        // LOGO (WRAP_CONTENT TOP)
        // =========================
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        logoImageView.contentMode = .scaleAspectFit
        
        // WebP manual load
        if let url = Bundle.main.url(forResource: "logodit", withExtension: "webp"),
           let data = try? Data(contentsOf: url),
           let image = UIImage(data: data) {
            logoImageView.image = image
        }
        
        view.addSubview(logoImageView)
        
        NSLayoutConstraint.activate([
            logoImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoImageView.widthAnchor.constraint(equalToConstant: 90),
            logoImageView.heightAnchor.constraint(equalToConstant: 90)
        ])
        
        // =========================
        // BOTTOM GROUP (MATCH_PARENT WIDTH)
        // =========================
        bottomStack.axis = .vertical
        bottomStack.alignment = .fill
        bottomStack.spacing = 12
        bottomStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bottomStack)
        
        NSLayoutConstraint.activate([
            bottomStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            bottomStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            bottomStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -32)
        ])
        
        // LABEL
        tvBareskrim.text = "BARESKRIM POLRI"
        tvBareskrim.textColor = UIColor(white: 0.9, alpha: 1)
        tvBareskrim.font = UIFont.systemFont(ofSize: 12)
        tvBareskrim.textAlignment = .center
        
        // BUTTON
        btLogin.setTitle("LOGIN", for: .normal)
        btLogin.setTitleColor(.white, for: .normal)
        btLogin.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        btLogin.backgroundColor = .systemBlue
        btLogin.layer.cornerRadius = 12
        btLogin.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            btLogin.heightAnchor.constraint(equalToConstant: 56)
        ])
        
        btLogin.addTarget(self, action: #selector(goToLogin), for: .touchUpInside)
        
        bottomStack.addArrangedSubview(tvBareskrim)
        bottomStack.addArrangedSubview(btLogin)
     
    }
    
    private func checkLogin() {
        let akses = SecurePrefs().getAccessToken()
        let refresh = SecurePrefs().getRefreshToken()
    
        if akses?.isEmpty ?? true || refresh?.isEmpty ?? true {
            btLogin.isHidden = false
        } else {
            goToHome()
        }
        
        
    }
    
    @objc private func goToLogin() {
        let vc = LoginPage()
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true)
    }
    
    private func goToHome() {
        let vc = Home()
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: false)
    }
}
