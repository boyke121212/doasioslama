//
//  Berita.swift
//  Doas
//
//  Created by Admin on 06/03/26.
//

import UIKit

// MARK: - BeritaListItem
struct BeritaListItem {
    let id:      String
    let judul:   String
    let isi:     String
    let tanggal: String
    let foto:    String
    let pdf:     String
}

// MARK: - SelfSizingTableView
class SelfSizingTableView: UITableView {
    override var intrinsicContentSize: CGSize {
        layoutIfNeeded()
        return CGSize(width: UIView.noIntrinsicMetric, height: contentSize.height)
    }
    override func reloadData() {
        super.reloadData()
        invalidateIntrinsicContentSize()
        setNeedsLayout()
    }
    override func insertRows(at indexPaths: [IndexPath], with animation: UITableView.RowAnimation) {
        super.insertRows(at: indexPaths, with: animation)
        invalidateIntrinsicContentSize()
        setNeedsLayout()
    }
}

// MARK: - BeritaListCell
class BeritaListCell: UITableViewCell {

    static let reuseId = "BeritaListCell"

    let cardView     = UIView()
    let ivFoto       = UIImageView()
    let contentStack = UIStackView()
    let tvJudul      = UILabel()
    let tvIsi        = UILabel()
    let btDownload   = UIButton(type: .system)

    var onTapCard:     (() -> Void)?
    var onTapDownload: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle  = .none
        backgroundColor = .clear
        setupCell()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setupCell() {
        cardView.translatesAutoresizingMaskIntoConstraints = false
        cardView.backgroundColor     = .white
        cardView.layer.cornerRadius  = 12
        cardView.layer.borderWidth   = 1
        cardView.layer.borderColor   = UIColor(hex: "#E5E7EB").cgColor
        cardView.layer.shadowColor   = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.08
        cardView.layer.shadowRadius  = 4
        cardView.layer.shadowOffset  = CGSize(width: 0, height: 2)
        cardView.layer.masksToBounds = false

        contentView.addSubview(cardView)
        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8)
        ])

        let pembungkus = UIStackView()
        pembungkus.axis = .horizontal; pembungkus.spacing = 12; pembungkus.alignment = .top
        pembungkus.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(pembungkus)
        NSLayoutConstraint.activate([
            pembungkus.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 12),
            pembungkus.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -12),
            pembungkus.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),
            pembungkus.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -12)
        ])

        ivFoto.translatesAutoresizingMaskIntoConstraints = false
        ivFoto.contentMode = .scaleAspectFill; ivFoto.clipsToBounds = true
        ivFoto.layer.cornerRadius = 10
        ivFoto.image = UIImage(named: "doas2"); ivFoto.backgroundColor = .systemGray5
        NSLayoutConstraint.activate([
            ivFoto.widthAnchor.constraint(equalToConstant: 90),
            ivFoto.heightAnchor.constraint(equalToConstant: 90)
        ])
        pembungkus.addArrangedSubview(ivFoto)

        contentStack.axis = .vertical; contentStack.spacing = 4; contentStack.alignment = .leading
        pembungkus.addArrangedSubview(contentStack)

        tvJudul.font = .boldSystemFont(ofSize: 14)
        tvJudul.textColor = UIColor(hex: "#111827"); tvJudul.numberOfLines = 0
        contentStack.addArrangedSubview(tvJudul)

        tvIsi.font = .systemFont(ofSize: 12)
        tvIsi.textColor = UIColor(hex: "#4B5563"); tvIsi.numberOfLines = 3
        tvIsi.lineBreakMode = .byTruncatingTail
        contentStack.addArrangedSubview(tvIsi)
        contentStack.setCustomSpacing(4, after: tvJudul)

        btDownload.setTitle("Download PDF", for: .normal)
        btDownload.titleLabel?.font = .boldSystemFont(ofSize: 12)
        btDownload.setTitleColor(.white, for: .normal)
        btDownload.backgroundColor = UIColor(hex: "#2563EB")
        btDownload.layer.cornerRadius = 8
        btDownload.contentEdgeInsets = UIEdgeInsets(top: 6, left: 14, bottom: 6, right: 14)
        contentStack.addArrangedSubview(btDownload)
        contentStack.setCustomSpacing(8, after: tvIsi)
        btDownload.addTarget(self, action: #selector(tapDownload), for: .touchUpInside)

        let tap = UITapGestureRecognizer(target: self, action: #selector(tapCard))
        cardView.addGestureRecognizer(tap)
        cardView.isUserInteractionEnabled = true
    }

    @objc private func tapCard()     { onTapCard?() }
    @objc private func tapDownload() { onTapDownload?() }

    override func prepareForReuse() {
        super.prepareForReuse()
        ivFoto.cancelImageLoad()
        ivFoto.image = UIImage(named: "doas2")
        onTapCard = nil; onTapDownload = nil
    }

    func bind(_ item: BeritaListItem) {
        tvJudul.text        = item.judul
        tvIsi.text          = RenderHtml.htmlPreviewClean(item.isi)
        btDownload.isHidden = item.pdf.isEmpty
        let token  = SecurePrefs().getAccessToken() ?? ""
        let urlStr = AppConfig.BASE_URL + "api/media/berita/" + item.foto
        if let url = URL(string: urlStr) {
            ivFoto.loadImage(url: url, token: token, placeholder: UIImage(named: "doas2"))
        }
    }
}

// MARK: - Berita ViewController
class Berita: Boyke, UIScrollViewDelegate {

    let scrollView   = UIScrollView()
    let contentView  = UIView()
    let tbMenuStack  = UIStackView()
    private var bannerSlider: BannerSlider!

    let btAbsen   = MenuItemView(title: "Absen",   iconName: "ic_fingerprint")
    let btStatus  = MenuItemView(title: "Status",  iconName: "ic_status")
    let btInfo    = MenuItemView(title: "Berita",  iconName: "ic_news", active: true)
    let btLog     = MenuItemView(title: "Log",     iconName: "ic_log")
    let btProfile = MenuItemView(title: "Profile", iconName: "ic_person")
    let btDoas    = MenuItemView(title: "DOAS",    iconName: "ic_about")

    // MARK: - Hero
    let heroContainer    = UIView()
    let floatingMenuCard = UIView()
    let logoImageView    = UIImageView()
    let gradientView     = UIView()
    let titleStack       = UIStackView()
    let tvJudul          = UILabel()
    let tvIsi            = UILabel()

    private let headerMaxHeight: CGFloat = 280
    private let headerMinHeight: CGFloat = 140
    private var headerHeightConstraint: NSLayoutConstraint!

    let pageController = UIPageViewController(
        transitionStyle: .scroll,
        navigationOrientation: .horizontal
    )

    private var listBerita: [BeritaListItem] = []
    private var lastId     = ""
    private var isLoading  = false
    private var isLastPage = false

    let rvHistory      = SelfSizingTableView()
    // ✅ SATU refreshControl, dipasang ke scrollView
    let refreshControl = UIRefreshControl()

    // MARK: - viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLayout()

        let empty = UIViewController()
        empty.view.backgroundColor = .clear
        pageController.setViewControllers([empty], direction: .forward, animated: false)
        bannerSlider = BannerSlider(parent: self, container: heroContainer)

        btAbsen.addTarget(self,   action: #selector(ontapMe),     for: .touchUpInside)
        btStatus.addTarget(self,  action: #selector(ontapInfo),   for: .touchUpInside)
        btDoas.addTarget(self,    action: #selector(ontapDoas),   for: .touchUpInside)
        btLog.addTarget(self,     action: #selector(ontapLog),    for: .touchUpInside)
        btProfile.addTarget(self, action: #selector(bukaprofile), for: .touchUpInside)
    }

    @objc private func bukaprofile() { let vc = ProfileActivity(); vc.modalPresentationStyle = .fullScreen; present(vc, animated: false) }
    @objc private func ontapInfo()   { openPage(Statuses()) }
    @objc private func ontapDoas()   { openPage(Doas()) }
    @objc private func ontapLog()    { openPage(History()) }
    @objc private func ontapMe()     { openPage(Home()) }

    // MARK: - Collapsing header saat scroll
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let y         = scrollView.contentOffset.y
        let newHeight = max(headerMinHeight, headerMaxHeight - y)
        headerHeightConstraint.constant = newHeight
        let progress  = min(max((headerMaxHeight - newHeight) / (headerMaxHeight - headerMinHeight), 0), 1)
        tvJudul.alpha = 1 - 0.25 * progress
        tvIsi.alpha   = 1 - 0.60 * progress

        let contentH = scrollView.contentSize.height
        let offsetY  = scrollView.contentOffset.y
        let frameH   = scrollView.frame.height
        if !isLoading && !isLastPage && (offsetY + frameH) >= contentH - 200 {
            loadBerita()
        }
    }

    // MARK: - Layout
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

        // ✅ refreshControl di scrollView — bukan rvHistory yang isScrollEnabled=false
        refreshControl.addTarget(self, action: #selector(onRefresh), for: .valueChanged)
        scrollView.refreshControl = refreshControl

        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)

        let cg = scrollView.contentLayoutGuide
        let fg = scrollView.frameLayoutGuide
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: cg.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: cg.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: cg.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: cg.trailingAnchor),
            contentView.widthAnchor.constraint(equalTo: fg.widthAnchor)
        ])

        setupHeroSection()
        setupFloatingMenu()
        setupHistoryList()
    }

    // MARK: - Floating Menu
    private func setupFloatingMenu() {
        floatingMenuCard.translatesAutoresizingMaskIntoConstraints = false
        floatingMenuCard.backgroundColor     = .white
        floatingMenuCard.layer.cornerRadius  = 16
        floatingMenuCard.layer.shadowColor   = UIColor.black.cgColor
        floatingMenuCard.layer.shadowOpacity = 0.15
        floatingMenuCard.layer.shadowRadius  = 6
        floatingMenuCard.layer.shadowOffset  = CGSize(width: 0, height: 4)

        contentView.addSubview(floatingMenuCard)
        NSLayoutConstraint.activate([
            floatingMenuCard.topAnchor.constraint(equalTo: heroContainer.bottomAnchor, constant: -26),
            floatingMenuCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            floatingMenuCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            floatingMenuCard.heightAnchor.constraint(equalToConstant: 64)
        ])

        tbMenuStack.axis = .horizontal; tbMenuStack.distribution = .fillEqually
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
    }

    // MARK: - List
    private func setupHistoryList() {
        rvHistory.translatesAutoresizingMaskIntoConstraints = false
        rvHistory.isScrollEnabled    = false
        rvHistory.separatorStyle     = .none
        rvHistory.backgroundColor    = .clear
        rvHistory.rowHeight          = UITableView.automaticDimension
        rvHistory.estimatedRowHeight = 120
        rvHistory.register(BeritaListCell.self, forCellReuseIdentifier: BeritaListCell.reuseId)
        rvHistory.dataSource = self
        rvHistory.delegate   = self

        let footer = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 80))
        rvHistory.tableFooterView = footer

        contentView.addSubview(rvHistory)
        NSLayoutConstraint.activate([
            rvHistory.topAnchor.constraint(equalTo: floatingMenuCard.bottomAnchor, constant: 12),
            rvHistory.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            rvHistory.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            rvHistory.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    // MARK: - Hero Section
    private func setupHeroSection() {
        heroContainer.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(heroContainer)
        NSLayoutConstraint.activate([
            heroContainer.topAnchor.constraint(equalTo: contentView.topAnchor),
            heroContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            heroContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
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
        logoImageView.image       = UIImage(named: "doas2")
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

        titleStack.axis = .vertical; titleStack.spacing = 4
        titleStack.translatesAutoresizingMaskIntoConstraints = false
        tvJudul.textColor = .white; tvJudul.font = .boldSystemFont(ofSize: 22)
        tvIsi.textColor   = .white; tvIsi.font   = .systemFont(ofSize: 14)
        titleStack.addArrangedSubview(tvJudul)
        titleStack.addArrangedSubview(tvIsi)
        heroContainer.addSubview(titleStack)
        NSLayoutConstraint.activate([
            titleStack.leadingAnchor.constraint(equalTo: heroContainer.leadingAnchor, constant: 24),
            titleStack.bottomAnchor.constraint(equalTo: heroContainer.bottomAnchor, constant: -24)
        ])
    }

    // MARK: - viewDidAppear
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        ambilBanner()
        if listBerita.isEmpty { loadBerita() }
    }

    // MARK: - Refresh
    @objc private func onRefresh() {
        lastId = ""; isLastPage = false; isLoading = false
        listBerita.removeAll()
        rvHistory.reloadData()
        ambilBanner()
        loadBerita()
        refreshControl.endRefreshing()
    }

    func showAlert(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    // MARK: - ambilBanner
    func ambilBanner() {
        AuthManager(endpoint: "api/ambil_absen").checkAuth(
            params: [:],
            onSuccess: { [weak self] json in
                guard let self else { return }
                guard (json["status"] as? String) == "ok" else { return }
                let aesKey = json["aes_key"] as? String ?? ""
                var items: [BeritaItem] = []
                if let arr = json["berita"] as? [[String: Any]] {
                    for obj in arr {
                        items.append(BeritaItem(
                            id:      obj["id"]      as? String ?? "",
                            judul:   CryptoAES.decrypt(obj["judul"]   as? String ?? "", aesKey),
                            isi:     CryptoAES.decrypt(obj["isi"]     as? String ?? "", aesKey),
                            tanggal: obj["tanggal"] as? String ?? "",
                            foto:    CryptoAES.decrypt(obj["foto"]    as? String ?? "", aesKey),
                            pdf:     CryptoAES.decrypt(obj["pdf"]     as? String ?? "", aesKey)
                        ))
                    }
                }
                DispatchQueue.main.async {
                    guard !items.isEmpty else { return }
                    self.bannerSlider.setItems(items)
                    self.tvJudul.text = items[0].judul
                    self.tvIsi.text   = items[0].isi.hendry_htmlToPlain()
                }
            },
            onLogout: { _ in }, onLoading: { _ in }
        )
    }

    // MARK: - loadBerita
    private func loadBerita() {
        guard !isLoading, !isLastPage else { return }
        isLoading = true

        AuthManager(endpoint: "api/berita").checkAuth(
            params: ["lastId": lastId],
            onSuccess: { [weak self] json in
                guard let self else { return }
                let aesKey = json["aes_key"] as? String ?? ""
                let jumlah = json["jumlah"]  as? Int    ?? 0

                guard jumlah > 0, let arr = json["data"] as? [[String: Any]] else {
                    DispatchQueue.main.async {
                        self.isLastPage = true
                        self.isLoading  = false
                    }
                    return
                }

                let startPos = self.listBerita.count
                for obj in arr {
                    self.listBerita.append(BeritaListItem(
                        id:      obj["id"]      as? String ?? "",
                        judul:   CryptoAES.decrypt(obj["judul"]   as? String ?? "", aesKey),
                        isi:     CryptoAES.decrypt(obj["isi"]     as? String ?? "", aesKey),
                        tanggal: obj["tanggal"] as? String ?? "",
                        foto:    CryptoAES.decrypt(obj["foto"]    as? String ?? "", aesKey),
                        pdf:     CryptoAES.decrypt(obj["pdf"]     as? String ?? "", aesKey)
                    ))
                }
                self.lastId = json["last_id"] as? String ?? self.lastId

                DispatchQueue.main.async {
                    let idxs = (startPos ..< self.listBerita.count).map { IndexPath(row: $0, section: 0) }
                    self.rvHistory.insertRows(at: idxs, with: .none)
                    self.isLoading = false
                }
            },
            onLogout: { [weak self] message in
                DispatchQueue.main.async {
                    guard let self else { return }
                    self.isLoading = false
                    self.refreshControl.endRefreshing()
                    if message == "__TIMEOUT__" || message == "__NO_INTERNET__" {
                        self.showAlert("Connection Time Out Error")
                    } else if !message.contains("Verification failed") && !message.contains("Checking Device") {
                        let vc = Home(); vc.modalPresentationStyle = .fullScreen; self.present(vc, animated: false)
                    }
                }
            },
            onLoading: { loading in
                DispatchQueue.main.async {
                    if loading { self.showLoading() } else { self.hideLoading() }
                }
            }
        )
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate
extension Berita: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        listBerita.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: BeritaListCell.reuseId, for: indexPath
        ) as! BeritaListCell

        let item = listBerita[indexPath.row]
        cell.bind(item)

        cell.onTapCard = { [weak self] in
            guard let self else { return }
            let vc = BeritaDetailActivity()
            vc.beritaId      = item.id
            vc.beritaJudul   = item.judul
            vc.beritaIsi     = item.isi
            vc.beritaTanggal = item.tanggal
            vc.beritaFoto    = item.foto
            vc.beritaPdf     = item.pdf
            vc.modalPresentationStyle = .fullScreen
            self.present(vc, animated: true)
        }

        cell.onTapDownload = { [weak self] in
            guard let self else { return }
            guard NetworkHelper.isInternetAvailable() else {
                self.showAlert("Tidak ada koneksi internet"); return
            }
            let token  = SecurePrefs().getAccessToken() ?? ""
            let urlPdf = AppConfig.BASE_URL + "api/media/pdf/" + item.pdf
            PdfDownloader.download(url: urlPdf, filename: item.pdf, token: token, from: self)
        }

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - UIColor hex helper
extension UIColor {
    convenience init(hex: String) {
        var h = hex.trimmingCharacters(in: .alphanumerics.inverted)
        if h.count == 6 { h = "FF" + h }
        var val: UInt64 = 0
        Scanner(string: h).scanHexInt64(&val)
        self.init(
            red:   CGFloat((val & 0xFF0000) >> 16) / 255,
            green: CGFloat((val & 0x00FF00) >>  8) / 255,
            blue:  CGFloat( val & 0x0000FF        ) / 255,
            alpha: CGFloat((val & 0xFF000000) >> 24) / 255
        )
    }
}
