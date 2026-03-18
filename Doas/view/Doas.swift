//
//  Doas.swift
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

class Doas: Boyke,UIScrollViewDelegate {
    let scrollView = UIScrollView()
    let contentView = UIView()
    let tbMenuStack = UIStackView()
    let gridContainer = UIStackView()
    let doasContainer = UIView()

    let tvAtas = UILabel()
    let scrollText = UIScrollView()
    let tvDoas = UITextView()

    let btDownload = UIButton(type: .system)
    private var bannerSlider: BannerSlider!
    let btAbsen = MenuItemView(title: "Absen", iconName: "ic_fingerprint")
    let btStatus = MenuItemView(title: "Status", iconName: "ic_status")
    let btInfo = MenuItemView(title: "Berita", iconName: "ic_news")
    let btLog = MenuItemView(title: "Log", iconName: "ic_log")
    let btProfile = MenuItemView(title: "Profile", iconName: "ic_person")
    let btDoas = MenuItemView(title: "DOAS", iconName: "ic_about",active: true)
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
        btInfo.addTarget(self, action: #selector(ontapInfo), for: .touchUpInside)
        btStatus.addTarget(self, action: #selector(ontapDoas), for: .touchUpInside)
        btLog.addTarget(self, action: #selector(ontapLog), for: .touchUpInside)
        btProfile.addTarget(self, action: #selector(bukaprofile), for: .touchUpInside)
        callApi()

    }
    
    @objc private func bukaprofile() {
        let vc = ProfileActivity()
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: false)
    }
    @objc private func ontapInfo() {
      openPage(Berita())
    }
    @objc private func ontapDoas() {
      openPage(Statuses())
    }
    @objc private func ontapLog() {
     openPage(History())
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
    
    private func callApi(){
        AuthManager(endpoint: "api/getdoas").checkAuth(
            params: [:],
            onSuccess: { json in
                guard let aesKey = json["aes_key"] as? String,
                      let status = json["status"] as? String,
                      status == "ok" else { return }

                // MARK: BERITA
                var listBerita: [BeritaItem] = []

                if let beritaArray = json["berita"] as? [[String: Any]] {
                    for obj in beritaArray {
                        let item = BeritaItem(
                            id:      obj["id"]      as? String ?? "",
                            judul:   CryptoAES.decrypt(obj["judul"]   as? String ?? "", aesKey),
                            isi:     CryptoAES.decrypt(obj["isi"]     as? String ?? "", aesKey),
                            tanggal: obj["tanggal"] as? String ?? "",
                            foto:    CryptoAES.decrypt(obj["foto"]    as? String ?? "", aesKey),
                            pdf:     CryptoAES.decrypt(obj["pdf"]     as? String ?? "", aesKey)
                        )
                        listBerita.append(item)
                    }
                }

                DispatchQueue.main.async {
                    // MARK: KONTEN DOAS
                    let judul = CryptoAES.decrypt(json["judul"] as? String ?? "", aesKey)
                    let isi   = CryptoAES.decrypt(json["isi"]   as? String ?? "", aesKey)
                    let pdf   = CryptoAES.decrypt(json["pdf"]   as? String ?? "", aesKey)

                    self.tvAtas.text = judul
                    self.setHTML(isi, to: self.tvDoas)

                    // MARK: DOWNLOAD PDF
                    self.btDownload.addAction(UIAction { _ in
                        let token = SecurePrefs().getAccessToken()
                        let url   = AppConfig.BASE_URL + "api/media/pdf/" + pdf
                        self.downloadPdfVolley(url: url, filename: pdf, token: token ?? "")
                    }, for: .touchUpInside)
                }
            },
            onLogout: { message in
                DispatchQueue.main.async {
                    if message == "__TIMEOUT__" || message == "__NO_INTERNET__" {
                        self.showAlert("Connection Time Out Error")
                        self.openPage(Home())
                    } else if message.contains("Verification failed") ||
                              message.contains("Checking Device") {
                        self.openPage(Home())
                    } else {
                        self.openPage(Home())
                        self.showAlert(message)
                    }
                }
            },
            onLoading: { loading in
                if loading {
                    self.showLoading()
                } else {
                    self.hideLoading()
                }
            }
        )
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
        setupDoasContent()
        
    }
    
    
    private func setupDoasContent() {

        doasContainer.translatesAutoresizingMaskIntoConstraints = false
        doasContainer.backgroundColor = .white

        // ✅ Tambahkan semua subview DULU sebelum constraint
        contentView.addSubview(doasContainer)
        doasContainer.addSubview(tvAtas)
        doasContainer.addSubview(tvDoas)
        doasContainer.addSubview(btDownload)  // ← ini yang menyebabkan crash, harus addSubview dulu

        // Config views
        tvAtas.translatesAutoresizingMaskIntoConstraints = false
        tvAtas.text = "Latar Belakang Aplikasi DOAS"
        tvAtas.font = UIFont.boldSystemFont(ofSize: 18)
        tvAtas.textAlignment = .center
        tvAtas.numberOfLines = 0

        tvDoas.translatesAutoresizingMaskIntoConstraints = false
        tvDoas.font = UIFont.systemFont(ofSize: 14)
        tvDoas.textColor = .black
        tvDoas.isEditable = false
        tvDoas.isScrollEnabled = false
        tvDoas.backgroundColor = .clear
        // Default placeholder content as attributed string
        let defaultHTML = "<p>isi<br>isi<br>isi</p>"
        setHTML(defaultHTML, to: tvDoas)

        btDownload.translatesAutoresizingMaskIntoConstraints = false
        btDownload.setTitle("Download PDF", for: .normal)
        btDownload.backgroundColor = .systemBlue
        btDownload.setTitleColor(.white, for: .normal)
        btDownload.layer.cornerRadius = 8

        // ✅ Semua constraint setelah semua addSubview selesai
        NSLayoutConstraint.activate([

            // doasContainer
            doasContainer.topAnchor.constraint(equalTo: floatingMenuCard.bottomAnchor, constant: 8),
            doasContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            doasContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            doasContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            // tvAtas
            tvAtas.topAnchor.constraint(equalTo: doasContainer.topAnchor, constant: 16),
            tvAtas.leadingAnchor.constraint(equalTo: doasContainer.leadingAnchor, constant: 16),
            tvAtas.trailingAnchor.constraint(equalTo: doasContainer.trailingAnchor, constant: -16),

            // tvDoas
            tvDoas.topAnchor.constraint(equalTo: tvAtas.bottomAnchor, constant: 12),
            tvDoas.leadingAnchor.constraint(equalTo: doasContainer.leadingAnchor, constant: 16),
            tvDoas.trailingAnchor.constraint(equalTo: doasContainer.trailingAnchor, constant: -16),
            tvDoas.bottomAnchor.constraint(equalTo: btDownload.topAnchor, constant: -20),

            // btDownload
            btDownload.leadingAnchor.constraint(equalTo: doasContainer.leadingAnchor, constant: 16),
            btDownload.trailingAnchor.constraint(equalTo: doasContainer.trailingAnchor, constant: -16),
            btDownload.heightAnchor.constraint(equalToConstant: 44),
            btDownload.bottomAnchor.constraint(equalTo: doasContainer.bottomAnchor, constant: -24),
        ])
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
            // ❌ HAPUS BARIS INI — ini yang menyebabkan doasContainer tidak muncul
            // floatingMenuCard.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24)
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

    // MARK: - Download PDF
    // Setara fun downloadPdfVolley() di Android/Kotlin

    func downloadPdfVolley(url: String, filename: String, token: String) {

        // CEK INTERNET DULU
        guard Auto.isInternetAvailable() else {
            showToast("Tidak ada koneksi internet")
            return
        }

        guard let requestURL = URL(string: url) else {
            showToast("URL tidak valid")
            return
        }

        // MARK: BUILD REQUEST (setara getHeaders())
        var request = URLRequest(url: requestURL)
        request.httpMethod = "GET"
        request.timeoutInterval = 15

        let timestamp = String(Int(Date().timeIntervalSince1970))
        let nonce     = UUID().uuidString

        request.setValue("Bearer \(token)",                          forHTTPHeaderField: "Authorization")
        request.setValue("application/json",                         forHTTPHeaderField: "Accept")
        request.setValue(DeviceSecurityHelper.getDeviceHash(),       forHTTPHeaderField: "X-Device-Hash")
        request.setValue(DeviceSecurityHelper.getAppSignatureHash(), forHTTPHeaderField: "X-App-Signature")
        request.setValue("ios",                                      forHTTPHeaderField: "Platform")
        request.setValue(timestamp,                                  forHTTPHeaderField: "X-Request-Timestamp")
        request.setValue(nonce,                                      forHTTPHeaderField: "X-Request-Nonce")

        // MARK: EXECUTE (setara VolleySingleton.addToRequestQueue)
        let task = URLSession.shared.dataTask(with: request) { data, response, error in

            DispatchQueue.main.async {

                // MARK: ERROR HANDLING (setara ErrorListener di Volley)
                if let error = error as NSError? {
                    let message: String
                    switch error.code {
                    case NSURLErrorNotConnectedToInternet:  message = "Tidak ada koneksi internet"
                    case NSURLErrorTimedOut:                message = "Koneksi timeout"
                    case NSURLErrorUserAuthenticationRequired: message = "Akses ditolak"
                    default:                                message = "Download gagal"
                    }
                    self.showToast(message)
                    return
                }

                guard let data = data, !data.isEmpty else {
                    self.showToast("File kosong atau gagal diunduh")
                    return
                }

                // MARK: SIMPAN FILE (setara deliverResponse)
                do {
                    let tempDir  = FileManager.default.temporaryDirectory
                    let fileURL  = tempDir.appendingPathComponent(filename)

                    try data.write(to: fileURL)

                    // MARK: BUKA PDF (setara openPdf())
                    self.openPdf(fileURL: fileURL)

                } catch {
                    self.showToast("Gagal menyimpan file")
                }
            }
        }

        // MARK: RETRY 1x (setara DefaultRetryPolicy)
        task.resume()
        DispatchQueue.global().asyncAfter(deadline: .now() + 15) {
            if task.state == .running {
                task.cancel()
                DispatchQueue.main.async {
                    self.showToast("Koneksi timeout")
                }
            }
        }
    }

    // MARK: - Buka PDF
    // Setara fun openPdf() di Android
    func openPdf(fileURL: URL) {
        guard let topVC = UIApplication.shared.windows.first?.rootViewController else { return }

        let activityVC = UIActivityViewController(
            activityItems: [fileURL],
            applicationActivities: nil
        )

        // iPad support
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = topVC.view
            popover.sourceRect = CGRect(
                x: topVC.view.bounds.midX,
                y: topVC.view.bounds.midY,
                width: 0, height: 0
            )
            popover.permittedArrowDirections = []
        }

        topVC.present(activityVC, animated: true)
    }

    // MARK: - Toast helper
    // Setara Toast.makeText() di Android
    func showToast(_ message: String) {
        guard let window = UIApplication.shared.windows.first else { return }

        let toast = UILabel()
        toast.text             = message
        toast.textColor        = .white
        toast.backgroundColor  = UIColor.black.withAlphaComponent(0.75)
        toast.textAlignment    = .center
        toast.font             = UIFont.systemFont(ofSize: 14)
        toast.numberOfLines    = 0
        toast.layer.cornerRadius = 8
        toast.clipsToBounds    = true
        toast.alpha            = 0
        toast.translatesAutoresizingMaskIntoConstraints = false

        window.addSubview(toast)

        NSLayoutConstraint.activate([
            toast.leadingAnchor.constraint(equalTo: window.leadingAnchor, constant: 32),
            toast.trailingAnchor.constraint(equalTo: window.trailingAnchor, constant: -32),
            toast.bottomAnchor.constraint(equalTo: window.safeAreaLayoutGuide.bottomAnchor, constant: -32),
        ])

        UIView.animate(withDuration: 0.3, animations: {
            toast.alpha = 1
        }) { _ in
            UIView.animate(withDuration: 0.3, delay: 2.0, animations: {
                toast.alpha = 0
            }) { _ in
                toast.removeFromSuperview()
            }
        }
    }

    // MARK: - Helper to set HTML string to UITextView safely
    private func setHTML(_ html: String, to textView: UITextView) {
        guard let data = html.data(using: .utf8) else {
            textView.text = html
            return
        }
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]
        do {
            let attributedString = try NSMutableAttributedString(data: data, options: options, documentAttributes: nil)
            // Removed setting the font for entire string to preserve HTML formatting
            textView.attributedText = attributedString
            if textView == tvDoas {
                applyJustify(to: textView)
            }
        } catch {
            textView.text = html
        }
    }
    
    // MARK: - Helper to apply justified alignment on UITextView's attributedText
    func applyJustify(to textView: UITextView) {
        guard let attributedText = textView.attributedText else { return }
        let mutableAttributedText = NSMutableAttributedString(attributedString: attributedText)
        let fullRange = NSRange(location: 0, length: mutableAttributedText.length)
        
        // Enumerate through paragraphs and set paragraph style alignment to justified
        mutableAttributedText.enumerateAttribute(.paragraphStyle, in: fullRange, options: []) { (value, range, _) in
            let paragraphStyle = (value as? NSMutableParagraphStyle) ?? NSMutableParagraphStyle()
            let newParagraphStyle = NSMutableParagraphStyle()
            newParagraphStyle.setParagraphStyle(paragraphStyle)
            newParagraphStyle.alignment = .justified
            mutableAttributedText.addAttribute(.paragraphStyle, value: newParagraphStyle, range: range)
        }
        
        textView.attributedText = mutableAttributedText
    }
}

