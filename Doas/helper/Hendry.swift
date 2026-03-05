import UIKit

// ======================================================
// MARK: - AUTH & DASHBOARD + BERITA
// ======================================================

extension Home {

    func dos() {

        authManager.checkAuth(

            onSuccess: { json in
                self.hideLoading()

                DispatchQueue.main.async {

                    self.rawDashboardJSON = json
                    self.isRequestRunning = false

                    guard let aesKey = json["aes_key"] as? String else { return }

                    if let dashboard = json["dashboard"] as? [String: Any] {
                        let data = DashboardData.from(json: dashboard)
                        self.renderDashboard(data)
                    }

                    if let beritaArray = json["berita"] as? [[String: Any]] {

                        var list: [BeritaItem] = []

                        for obj in beritaArray {

                            let berita = BeritaItem(
                                id: obj["id"] as? String ?? "",
                                judul: CryptoAES.decrypt(obj["judul"] as? String ?? "", aesKey),
                                isi: CryptoAES.decrypt(obj["isi"] as? String ?? "", aesKey),
                                tanggal: obj["tanggal"] as? String ?? "",
                                foto: CryptoAES.decrypt(obj["foto"] as? String ?? "", aesKey),
                                pdf: CryptoAES.decrypt(obj["pdf"] as? String ?? "", aesKey)
                            )

                            list.append(berita)
                        }

                        self.applyBeritaItems(list)
                    }
                }
            },

            onLogout: { message in
                DispatchQueue.main.async {
                    self.isRequestRunning = false
                    self.hideLoading()
                    self.showAlert(message)
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


// ======================================================
// MARK: - BERITA PAGER
// ======================================================

extension Home {

    func applyBeritaItems(_ items: [BeritaItem]) {

        beritaItems = items
        currentIndex = 0

        guard !items.isEmpty else { return }

        let firstVC = BannerPageVC(item: items[0])

        pageController.dataSource = pageHelper
        pageController.delegate = pageHelper

        pageController.setViewControllers(
            [firstVC],
            direction: .forward,
            animated: false
        )

        // Sync currentIndex with the actually displayed VC
        if let shown = pageController.viewControllers?.first as? BannerPageVC,
           let idx = beritaItems.firstIndex(where: { $0.id == shown.item.id }) {
            currentIndex = idx
        } else {
            currentIndex = 0
        }

        onBeritaChanged(items[0])
        startBeritaAutoSlide()
    }

    func onBeritaChanged(_ berita: BeritaItem) {
        titleLabel?.text = berita.judul
        if let attr = hendry_makeHTMLAttributed(berita.isi, baseFontSize: 14) {
            subtitleLabel?.attributedText = attr
        } else {
            // Fallback to plain text (strip HTML)
            subtitleLabel?.text = berita.isi.hendry_htmlToPlain()
        }
        // Make sure labels don't capture gestures
        titleLabel?.isUserInteractionEnabled = false
        subtitleLabel?.isUserInteractionEnabled = false
    }
    
    // Auto slide support
    func startBeritaAutoSlide(interval: TimeInterval = 4.0) {
        stopBeritaAutoSlide()
        let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            guard self.beritaItems.count > 1 else { return }
            let nextIndex = (self.currentIndex + 1) % self.beritaItems.count
            let vc = BannerPageVC(item: self.beritaItems[nextIndex])
            self.pageController.setViewControllers([vc], direction: .forward, animated: true) { finished in
                if finished {
                    self.currentIndex = nextIndex
                    self.onBeritaChanged(self.beritaItems[self.currentIndex])
                }
            }
        }
        beritaAutoSlideTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    func stopBeritaAutoSlide() {
        beritaAutoSlideTimer?.invalidate()
        beritaAutoSlideTimer = nil
    }
}


// ======================================================
// MARK: - PAGE VIEW CONTROLLER (SWIPE SUPPORT)
// ======================================================

private final class HomePageDataSourceDelegate: NSObject, UIPageViewControllerDataSource, UIPageViewControllerDelegate {

    weak var owner: Home?

    init(owner: Home) {
        self.owner = owner
    }

    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerBefore viewController: UIViewController
    ) -> UIViewController? {
        guard let owner = owner, let vc = viewController as? BannerPageVC else { return nil }
        guard let currentIdx = owner.beritaItems.firstIndex(where: { $0.id == vc.item.id }) else { return nil }
        let prev = currentIdx - 1
        let targetIdx = (prev >= 0) ? prev : (owner.beritaItems.isEmpty ? nil : owner.beritaItems.count - 1)
        guard let idx = targetIdx, owner.beritaItems.indices.contains(idx) else { return nil }
        return BannerPageVC(item: owner.beritaItems[idx])
    }

    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerAfter viewController: UIViewController
    ) -> UIViewController? {
        guard let owner = owner, let vc = viewController as? BannerPageVC else { return nil }
        guard let currentIdx = owner.beritaItems.firstIndex(where: { $0.id == vc.item.id }) else { return nil }
        let next = currentIdx + 1
        let targetIdx = (next < owner.beritaItems.count) ? next : (owner.beritaItems.isEmpty ? nil : 0)
        guard let idx = targetIdx, owner.beritaItems.indices.contains(idx) else { return nil }
        return BannerPageVC(item: owner.beritaItems[idx])
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard completed, let owner = owner, let currentVC = pageViewController.viewControllers?.first as? BannerPageVC else { return }
        if let idx = owner.beritaItems.firstIndex(where: { $0.id == currentVC.item.id }) {
            owner.currentIndex = idx
            owner.onBeritaChanged(owner.beritaItems[idx])
        }
    }
}

extension Home {
    // Keep a single instance to avoid redeclarations elsewhere
    private static var _pageHelperKey: UInt8 = 0

    private var pageHelper: HomePageDataSourceDelegate {
        if let existing = objc_getAssociatedObject(self, &Home._pageHelperKey) as? HomePageDataSourceDelegate {
            return existing
        }
        let helper = HomePageDataSourceDelegate(owner: self)
        objc_setAssociatedObject(self, &Home._pageHelperKey, helper, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return helper
    }
}

extension Home {
    private static var _beritaTimerKey: UInt8 = 0

    fileprivate var beritaAutoSlideTimer: Timer? {
        get { objc_getAssociatedObject(self, &Home._beritaTimerKey) as? Timer }
        set { objc_setAssociatedObject(self, &Home._beritaTimerKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
}


// ======================================================
// MARK: - UI OUTLETS PLACEHOLDERS (to satisfy references)
// ======================================================

extension Home {
    // If these are already defined as IBOutlets in another file, you can remove this placeholder.
    // They are optional to avoid impacting runtime if not connected here.
    @objc dynamic var titleLabel: UILabel? {
        get { objc_getAssociatedObject(self, UnsafeRawPointer(bitPattern: 0x1001)!) as? UILabel }
        set { objc_setAssociatedObject(self, UnsafeRawPointer(bitPattern: 0x1001)!, newValue, .OBJC_ASSOCIATION_ASSIGN) }
    }

    @objc dynamic var subtitleLabel: UILabel? {
        get { objc_getAssociatedObject(self, UnsafeRawPointer(bitPattern: 0x1002)!) as? UILabel }
        set { objc_setAssociatedObject(self, UnsafeRawPointer(bitPattern: 0x1002)!, newValue, .OBJC_ASSOCIATION_ASSIGN) }
    }
}


// ======================================================
// MARK: - KONFIRMASI APEL (go)
// ======================================================

extension Home {

    func go() {

        let alert = UIAlertController(
            title: "Konfirmasi Apel",
            message: "Anda Wajib Apel, Kami Akan Cek Kehadiran Apel Anda",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Setuju", style: .default) { _ in

            AuthManager(endpoint: "api/cekabsen").checkAuth(

                params: nil,

                onSuccess: { json in

                    DispatchQueue.main.async {

                        self.hideLoading()

                        let absen = json["absen"] as? String ?? ""

                        if absen.lowercased() == "belum" {

                            let vc = AbsenHadir()
                            vc.dari = "ADL"
                            vc.modalPresentationStyle = .fullScreen
                            self.present(vc, animated: true)

                        } else {

                            self.showAlert(absen)
                        }
                    }
                },

                onLogout: { message in

                    DispatchQueue.main.async {
                        self.hideLoading()
                        self.showAlert(message)
                    }
                },

                onLoading: { loading in

                    DispatchQueue.main.async {
                        loading ? self.showLoading() : self.hideLoading()
                    }
                }
            )
        })

        alert.addAction(UIAlertAction(title: "Tidak", style: .cancel))

        // ⬅️ JANGAN pakai DispatchQueue di sini
        present(alert, animated: true)
    }
}


// ======================================================
// MARK: - CEK ABSEN (Menu Lainnya)
// ======================================================

extension Home {

    func cekabsen(dari: String) {

        var params: [String: String] = [:]

        switch dari.lowercased() {
        case "dik": params["jenis"] = "DIK"
        case "sakit": params["jenis"] = "SAKIT"
        case "bko": params["jenis"] = "BKO"
        case "cuti": params["jenis"] = "CUTI"
        default:  params["jenis"] = ""
        }

        AuthManager(endpoint: "api/cekabsen").checkAuth(
            params: params,

            onSuccess: { json in

                self.hideLoading()

                DispatchQueue.main.async {

                    let absen = json["absen"] as? String ?? ""
                    let ketam = json["ketam"] as? String ?? ""
                    if(dari=="status"){
                        self.startStatus(absen: absen, ketam: ketam)
                    }else{
                        let dar = dari.uppercased()
                        self.startAbsen(absen: absen, target: AbsenHadir.self, ketam: ketam,dari:dar)
                    }
                  
                }
            },

            onLogout: { message in
                DispatchQueue.main.async {
                    SecurePrefs().clear()
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
            },

            onLoading: { loading in
                DispatchQueue.main.async {
                    loading ? self.showLoading() : self.hideLoading()
                }
            }
        )
    }
}


// ======================================================
// MARK: - START STATUS
// ======================================================

extension Home {

    func startStatus(absen: String, ketam: String) {

        if absen.lowercased() == "belum" {
            showAlert("Anda Belum Absen")
        } else {
            let vc = Statuses()
            vc.modalPresentationStyle = .fullScreen
            present(vc, animated: false)
        }
    }
}


// ======================================================
// MARK: - START ABSEN
// ======================================================

extension Home {

    func startAbsen(absen: String, target: UIViewController.Type, ketam: String,dari:String) {

        if absen.lowercased() == "belum" {

            let vc = AbsenHadir()
            vc.dari = dari.uppercased()
            vc.ketam = ketam
            vc.modalPresentationStyle = .fullScreen
            self.present(vc, animated: true)
            present(vc, animated: true)

        } else {
            showAlert(absen)
        }
    }
}


// ======================================================
// MARK: - PROTOCOL
// ======================================================

protocol HasKetam {
    var ketam: String? { get set }
}


// ======================================================
// MARK: - HTML CLEAN
// ======================================================

extension String {

    func hendry_htmlToPlain() -> String {

        guard let data = data(using: .utf8) else { return self }

        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html
        ]

        if let attributed = try? NSAttributedString(
            data: data,
            options: options,
            documentAttributes: nil
        ) {
            return attributed.string
        }

        return self
    }
}

private func hendry_makeHTMLAttributed(_ html: String, baseFontSize: CGFloat = 14) -> NSAttributedString? {
    let wrapped = """
    <span style=\"font-family: -apple-system, HelveticaNeue; font-size: \(Int(baseFontSize))px; color: #1A1A1A\">\n\(html)\n</span>
    """
    guard let data = wrapped.data(using: .utf8) else { return nil }
    let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
        .documentType: NSAttributedString.DocumentType.html,
        .characterEncoding: String.Encoding.utf8.rawValue
    ]
    return try? NSAttributedString(data: data, options: options, documentAttributes: nil)
}

