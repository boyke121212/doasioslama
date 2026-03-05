//
//  History.swift
//  Doas
//
//  Created by Admin on 06/03/26.
//

//
//  Statuses.swift
//  Doas
//
//  Created by Admin on 03/03/26.
//

import UIKit

class History: Boyke,UIScrollViewDelegate {
    let scrollView = UIScrollView()
    let contentView = UIView()
    let tbMenuStack = UIStackView()
    let gridContainer = UIStackView()
    private var bannerSlider: BannerSlider!
    let btAbsen = MenuItemView(title: "Absen", iconName: "ic_fingerprint")
    let btStatus = MenuItemView(title: "Status", iconName: "ic_status")
    let btInfo = MenuItemView(title: "Berita", iconName: "ic_news")
    let btLog = MenuItemView(title: "Log", iconName: "ic_log",active: true)
    let btProfile = MenuItemView(title: "Profile", iconName: "ic_person")
    let btDoas = MenuItemView(title: "DOAS", iconName: "ic_about")
    // MARK: - HERO SECTION
    
    let heroContainer = UIView()
    let floatingMenuCard = UIView()
    
    let logoImageView = UIImageView()
    let gradientView = UIView()
    let titleStack = UIStackView()
    let tvJudul = UILabel()
    let tvIsi = UILabel()
    
    // Collapsing header
    private let headerMaxHeight: CGFloat = 280
    private let headerMinHeight: CGFloat = 140
    private var headerHeightConstraint: NSLayoutConstraint!
    
    let pageController = UIPageViewController(
        transitionStyle: .scroll,
        navigationOrientation: .horizontal
    )
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLayout()
        let empty = UIViewController()
        empty.view.backgroundColor = .clear
        
        pageController.setViewControllers([empty], direction: .forward, animated: false)
        bannerSlider = BannerSlider(parent: self, container: heroContainer)

        btAbsen.addTarget(self, action: #selector(ontapMe), for: .touchUpInside)
        btStatus.addTarget(self, action: #selector(ontapInfo), for: .touchUpInside)
        btDoas.addTarget(self, action: #selector(ontapDoas), for: .touchUpInside)
        btInfo.addTarget(self, action: #selector(ontapLog), for: .touchUpInside)
        btProfile.addTarget(self, action: #selector(bukaprofile), for: .touchUpInside)

    }
    @objc private func bukaprofile() {
        let vc = ProfileActivity()
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: false)
    }
    @objc private func ontapInfo() {
      openPage(Statuses())
    }
    @objc private func ontapDoas() {
      openPage(Doas())
    }
    @objc private func ontapLog() {
     openPage(Berita())
    }
    
    private var headerAdjusted = false


    @objc private func ontapMe() {
      openPage(Home())
    }
    func scrollViewDidScroll(_ scrollView: UIScrollView) {

        let y = scrollView.contentOffset.y
        let newHeight = max(headerMinHeight, headerMaxHeight - y)

        headerHeightConstraint.constant = newHeight

        let progress = min(max((headerMaxHeight - newHeight) / (headerMaxHeight - headerMinHeight), 0), 1)

        tvJudul.alpha = 1 - 0.25 * progress
        tvIsi.alpha = 1 - 0.6 * progress

        view.layoutIfNeeded()
    }
    private func setupLayout() {
        
        view.backgroundColor = .systemBackground
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        scrollView.delegate = self
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        
        setupHeroSection()
        setupFloatingMenu()
        
    }
    
    
    private func setupFloatingMenu() {
        
        floatingMenuCard.translatesAutoresizingMaskIntoConstraints = false
        floatingMenuCard.backgroundColor = .white
        floatingMenuCard.layer.cornerRadius = 16
        floatingMenuCard.layer.shadowColor = UIColor.black.cgColor
        floatingMenuCard.layer.shadowOpacity = 0.15
        floatingMenuCard.layer.shadowRadius = 6
        floatingMenuCard.layer.shadowOffset = CGSize(width: 0, height: 4)
        
        contentView.addSubview(floatingMenuCard)
        
        NSLayoutConstraint.activate([
            floatingMenuCard.topAnchor.constraint(equalTo: heroContainer.bottomAnchor, constant: -26),
            floatingMenuCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            floatingMenuCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            floatingMenuCard.heightAnchor.constraint(equalToConstant: 64),
            floatingMenuCard.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24)
        ])
        
        tbMenuStack.axis = .horizontal
        tbMenuStack.distribution = .fillEqually
        tbMenuStack.translatesAutoresizingMaskIntoConstraints = false
        
        floatingMenuCard.addSubview(tbMenuStack)
        
        NSLayoutConstraint.activate([
            tbMenuStack.topAnchor.constraint(equalTo: floatingMenuCard.topAnchor),
            tbMenuStack.bottomAnchor.constraint(equalTo: floatingMenuCard.bottomAnchor),
            tbMenuStack.leadingAnchor.constraint(equalTo: floatingMenuCard.leadingAnchor),
            tbMenuStack.trailingAnchor.constraint(equalTo: floatingMenuCard.trailingAnchor)
        ])
        
        tbMenuStack.addArrangedSubview(btAbsen)
        tbMenuStack.addArrangedSubview(btStatus)
        tbMenuStack.addArrangedSubview(btInfo)
        tbMenuStack.addArrangedSubview(btLog)
        tbMenuStack.addArrangedSubview(btProfile)
        tbMenuStack.addArrangedSubview(btDoas)
        
        //        btAbsen.addTarget(self, action: #selector(onTapAbsen), for: .touchUpInside)
        //        btStatus.addTarget(self, action: #selector(onTapStatus), for: .touchUpInside)
        //        btInfo.addTarget(self, action: #selector(onTapInfo), for: .touchUpInside)
        //        btLog.addTarget(self, action: #selector(onTapLog), for: .touchUpInside)
        //        btProfile.addTarget(self, action: #selector(onTapProfile), for: .touchUpInside)
        //        btDoas.addTarget(self, action: #selector(onTapDoas), for: .touchUpInside)
    }
    
    private func setupHeroSection() {
        
        heroContainer.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(heroContainer)
        
        NSLayoutConstraint.activate([
            heroContainer.topAnchor.constraint(equalTo: contentView.topAnchor),
            heroContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            heroContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            // Store height constraint for collapsing header
            {
                let c = heroContainer.heightAnchor.constraint(equalToConstant: headerMaxHeight)
                self.headerHeightConstraint = c
                return c
            }()
        ])
        
        addChild(pageController)
        pageController.view.translatesAutoresizingMaskIntoConstraints = false
        heroContainer.addSubview(pageController.view)
        pageController.didMove(toParent: self)
        
        NSLayoutConstraint.activate([
            pageController.view.topAnchor.constraint(equalTo: heroContainer.topAnchor),
            pageController.view.bottomAnchor.constraint(equalTo: heroContainer.bottomAnchor),
            pageController.view.leadingAnchor.constraint(equalTo: heroContainer.leadingAnchor),
            pageController.view.trailingAnchor.constraint(equalTo: heroContainer.trailingAnchor)
        ])
        
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        logoImageView.contentMode = .scaleAspectFit
        logoImageView.image = UIImage(named: "doas2")
        heroContainer.addSubview(logoImageView)
        
        NSLayoutConstraint.activate([
            logoImageView.topAnchor.constraint(equalTo: heroContainer.topAnchor, constant: 16),
            logoImageView.leadingAnchor.constraint(equalTo: heroContainer.leadingAnchor, constant: 16),
            logoImageView.widthAnchor.constraint(equalToConstant: 100),
            logoImageView.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        gradientView.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        gradientView.translatesAutoresizingMaskIntoConstraints = false
        gradientView.isUserInteractionEnabled = false
        heroContainer.addSubview(gradientView)
        
        NSLayoutConstraint.activate([
            gradientView.topAnchor.constraint(equalTo: heroContainer.topAnchor),
            gradientView.bottomAnchor.constraint(equalTo: heroContainer.bottomAnchor),
            gradientView.leadingAnchor.constraint(equalTo: heroContainer.leadingAnchor),
            gradientView.trailingAnchor.constraint(equalTo: heroContainer.trailingAnchor)
        ])
        
        titleStack.axis = .vertical
        titleStack.spacing = 4
        titleStack.translatesAutoresizingMaskIntoConstraints = false
        
        tvJudul.textColor = .white
        tvJudul.font = .boldSystemFont(ofSize: 22)
        
        tvIsi.textColor = .white
        tvIsi.font = .systemFont(ofSize: 14)
        
        titleStack.addArrangedSubview(tvJudul)
        titleStack.addArrangedSubview(tvIsi)
        
        heroContainer.addSubview(titleStack)
        
        NSLayoutConstraint.activate([
            titleStack.leadingAnchor.constraint(equalTo: heroContainer.leadingAnchor, constant: 24),
            titleStack.bottomAnchor.constraint(equalTo: heroContainer.bottomAnchor, constant: -24)
        ])
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.ambilAbsen()
        print("Hero height status: ", heroContainer.frame.height)

    }
    func showAlert(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    func ambilAbsen() {
        AuthManager(endpoint: "api/ambil_absen").checkAuth(
            
            params: [:],
            
            onSuccess: { json in
                
                guard let status = json["status"] as? String, status == "ok" else { return }
                
                _ = json["pulang"] as? String ?? ""
                _ = json["jamserver"] as? String ?? ""
                
                do {
                    
                    let aesKey = json["aes_key"] as? String ?? ""
                    
                    // MARK: DATA ABSEN
                    
                    
                    // MARK: BERITA
                    var listBerita: [BeritaItem] = []
                    
                    if let beritaArray = json["berita"] as? [[String: Any]] {
                        
                        for obj in beritaArray {
                            
                            let item = BeritaItem(
                                id: obj["id"] as? String ?? "",
                                judul: CryptoAES.decrypt(obj["judul"] as? String ?? "", aesKey),
                                isi: CryptoAES.decrypt(obj["isi"] as? String ?? "", aesKey),
                                tanggal: obj["tanggal"] as? String ?? "",
                                foto: CryptoAES.decrypt(obj["foto"] as? String ?? "", aesKey),
                                pdf: CryptoAES.decrypt(obj["pdf"] as? String ?? "", aesKey)
                            )
                            
                            listBerita.append(item)
                        }
                    }
                    
                    // MARK: APPLY KE BANNER
                    DispatchQueue.main.async {
                        
                        if !listBerita.isEmpty {
                            
                            self.bannerSlider.setItems(listBerita)
                            
                            let first = listBerita[0]
                            self.tvJudul.text = first.judul
                            self.tvIsi.text = first.isi.hendry_htmlToPlain()
                        }
                    }
                    
                } catch {
                    print(error)
                }
            },
            
            onLogout: { message in
                
                DispatchQueue.main.async {
                    
                    if message == "__TIMEOUT__" || message == "__NO_INTERNET__" {
                        
                        self.showAlert("Connection Time Out Error")
                        
                        let vc = Home()
                        vc.modalPresentationStyle = .fullScreen
                        self.present(vc, animated: false)
                        
                    } else if message.contains("Verification failed") ||
                                message.contains("Checking Device") {
                        
                        let vc = Home()
                        vc.modalPresentationStyle = .fullScreen
                        self.present(vc, animated: false)
                        
                    } else {
                        
                        let vc = Home()
                        vc.modalPresentationStyle = .fullScreen
                        self.present(vc, animated: false)
                        
                        self.showAlert(message)
                    }
                }
            },
            
            onLoading: { loading in
                
                DispatchQueue.main.async {
                    
                    if loading {
                        self.showLoading()
                    } else {
                        self.hideLoading()
                    }
                }
            }
        )
    }
}
