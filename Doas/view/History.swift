//
//  History.swift
//  Doas
//
//  Created by Admin on 06/03/26.
//

import UIKit

// MARK: - HistoryModel
struct HistoryModel {
    let id:           String
    let masuk:        String
    let pulang:       String
    let selesai:      String
    let keterangan:   String
    let latitude:     String
    let longitude:    String
    let ketam:        String
    let jabatan:      String
    let pangkat:      String
    let foto:         String
    let foto2:        String
    let statusmasuk:  String
    let statuspulang: String
    let fotopulang:   String
    let fotopulang2:  String
    let subdit:       String
    let tanggal:      String
    let ketpul:       String
    let latpulang:    String
    let lonpulang:    String
    let nip:          String
    let nama:         String
}

// MARK: - HistoryCell
// Setara item_history.xml
class HistoryCell: UITableViewCell {

    static let reuseId = "HistoryCell"

    let cardView  = UIView()
    let tvTanggal = UILabel()
    let tvJam     = UILabel()
    let tvKetam   = UILabel()
    let tvKetpul  = UILabel()
    let tvStatus  = UILabel()
    let ivFoto    = UIImageView()

    var onTapCard: (() -> Void)?
    weak var hostVC: UIViewController?   // diset dari cellForRowAt untuk loadingFoto tap preview

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle  = .none
        backgroundColor = .clear
        setupCell()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setupCell() {
        // Card
        cardView.translatesAutoresizingMaskIntoConstraints = false
        cardView.backgroundColor     = .white
        cardView.layer.cornerRadius  = 14
        cardView.layer.shadowColor   = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.08
        cardView.layer.shadowRadius  = 4
        cardView.layer.shadowOffset  = CGSize(width: 0, height: 2)
        cardView.layer.masksToBounds = false
        contentView.addSubview(cardView)
        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8)
        ])

        // Horizontal stack: text | foto
        let row = UIStackView()
        row.axis = .horizontal; row.spacing = 10; row.alignment = .center
        row.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(row)
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 12),
            row.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -12),
            row.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),
            row.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -12)
        ])

        // Text column
        let col = UIStackView()
        col.axis = .vertical; col.spacing = 4; col.alignment = .leading
        row.addArrangedSubview(col)

        tvTanggal.font = .boldSystemFont(ofSize: 15)
        tvTanggal.textColor = UIColor(hex: "#222222")
        col.addArrangedSubview(tvTanggal)

        tvJam.font = .systemFont(ofSize: 13)
        tvJam.textColor = UIColor(hex: "#444444")
        tvJam.numberOfLines = 0
        col.addArrangedSubview(tvJam)

        tvKetam.font = .systemFont(ofSize: 12)
        tvKetam.textColor = UIColor(hex: "#777777")
        tvKetam.numberOfLines = 0
        col.addArrangedSubview(tvKetam)

        tvKetpul.font = .systemFont(ofSize: 12)
        tvKetpul.textColor = UIColor(hex: "#777777")
        tvKetpul.numberOfLines = 0
        col.addArrangedSubview(tvKetpul)

        tvStatus.font = .boldSystemFont(ofSize: 12)
        tvStatus.textColor = UIColor(hex: "#129026")
        col.addArrangedSubview(tvStatus)

        // Foto — 64x64
        ivFoto.translatesAutoresizingMaskIntoConstraints = false
        ivFoto.contentMode    = .scaleAspectFill
        ivFoto.clipsToBounds  = true
        ivFoto.backgroundColor = UIColor(hex: "#EEEEEE")
        ivFoto.image = UIImage(named: "doas2")
        NSLayoutConstraint.activate([
            ivFoto.widthAnchor.constraint(equalToConstant: 64),
            ivFoto.heightAnchor.constraint(equalToConstant: 64)
        ])
        row.addArrangedSubview(ivFoto)

        let tap = UITapGestureRecognizer(target: self, action: #selector(tapCard))
        cardView.addGestureRecognizer(tap)
        cardView.isUserInteractionEnabled = true
    }

    @objc private func tapCard() { onTapCard?() }

    override func prepareForReuse() {
        super.prepareForReuse()
        ivFoto.cancelImageLoad()
        ivFoto.image = nil
        onTapCard = nil
    }

    // Setara onBindViewHolder
    func bind(_ d: HistoryModel) {
        tvTanggal.text = d.tanggal

        // Setara SpannableString untuk jam masuk/pulang
        var ket = d.keterangan
        if ket.lowercased() == "dl" { ket = "Dinas Luar" }
        tvStatus.text = ket

        let jamText: String
        if d.pulang.isEmpty {
            jamText = "Masuk : \(d.masuk)(\(d.statusmasuk))\nPulang: -"
        } else {
            jamText = "Masuk : \(d.masuk)(\(d.statusmasuk))\nPulang: \(d.pulang)(\(d.statuspulang))"
        }
        // Setara RelativeSizeSpan(0.8f) untuk status masuk/pulang
        let attr = NSMutableAttributedString(string: jamText)
        let small = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 10.4)]
        if let r1 = jamText.range(of: "(\(d.statusmasuk))") {
            attr.addAttributes(small, range: NSRange(r1, in: jamText))
        }
        if !d.pulang.isEmpty, let r2 = jamText.range(of: "(\(d.statuspulang))") {
            attr.addAttributes(small, range: NSRange(r2, in: jamText))
        }
        tvJam.attributedText = attr

        tvKetam.text = "Keterangan : \(d.ketam)"

        if d.ketpul.isEmpty {
            tvKetpul.isHidden = true
        } else {
            tvKetpul.isHidden = false
            tvKetpul.text = "Keterangan Pulang : \(d.ketpul)"
        }

        // Load foto — setara loadingFoto() di Auto.kt
        // URL: BASE_URL/api/media/absensi?file=tanggal(/-)/foto
        Auto.loadingFoto(imageView: ivFoto, file: d.foto, tanggal: d.tanggal, from: hostVC)
    }
}

// MARK: - History ViewController
class History: Boyke, UIScrollViewDelegate {

    let scrollView   = UIScrollView()
    let contentView  = UIView()
    let tbMenuStack  = UIStackView()
    private var bannerSlider: BannerSlider!

    let btAbsen   = MenuItemView(title: "Absen",   iconName: "ic_fingerprint")
    let btStatus  = MenuItemView(title: "Status",  iconName: "ic_status")
    let btInfo    = MenuItemView(title: "Berita",  iconName: "ic_news")
    let btLog     = MenuItemView(title: "Log",     iconName: "ic_log", active: true)
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

    // MARK: - Filter bar
    let filterBar = UIView()
    let btFilter  = UIButton(type: .system)

    // MARK: - Data
    private var listHistory:    [HistoryModel] = []
    private var lastId          = ""
    private var isLoading       = false
    private var isLastPage      = false
    private var currentFilter   = [String: String]()  // status, tanggal

    let rvHistory      = SelfSizingTableView()
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
        btInfo.addTarget(self,    action: #selector(ontapBerita), for: .touchUpInside)
        btLog.addTarget(self,     action: #selector(ontapLog),    for: .touchUpInside)
        btProfile.addTarget(self, action: #selector(bukaprofile), for: .touchUpInside)
        btFilter.addTarget(self,  action: #selector(onTapFilter), for: .touchUpInside)
    }

    @objc private func bukaprofile() { let vc = ProfileActivity(); vc.modalPresentationStyle = .fullScreen; present(vc, animated: false) }
    @objc private func ontapInfo()   { openPage(Statuses()) }
    @objc private func ontapDoas()   { openPage(Doas()) }
    @objc private func ontapBerita() { openPage(Berita()) }
    @objc private func ontapLog()    { openPage(History()) }
    @objc private func ontapMe()     { openPage(Home()) }

    // MARK: - Collapsing header
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let y         = scrollView.contentOffset.y
        let newHeight = max(headerMinHeight, headerMaxHeight - y)
        headerHeightConstraint.constant = newHeight
        let progress  = min(max((headerMaxHeight - newHeight) / (headerMaxHeight - headerMinHeight), 0), 1)
        tvJudul.alpha = 1 - 0.25 * progress
        tvIsi.alpha   = 1 - 0.60 * progress

        // Infinite scroll
        let contentH = scrollView.contentSize.height
        let offsetY  = scrollView.contentOffset.y
        let frameH   = scrollView.frame.height
        if !isLoading && !isLastPage && (offsetY + frameH) >= contentH - 200 {
            loadHistory()
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
        scrollView.alwaysBounceVertical = true

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
        setupFilterBar()
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

    // MARK: - Filter Bar
    // Setara layoutFilterBar di XML
    private func setupFilterBar() {
        filterBar.translatesAutoresizingMaskIntoConstraints = false
        filterBar.backgroundColor = .white
        contentView.addSubview(filterBar)
        NSLayoutConstraint.activate([
            filterBar.topAnchor.constraint(equalTo: floatingMenuCard.bottomAnchor, constant: 8),
            filterBar.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            filterBar.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            filterBar.heightAnchor.constraint(equalToConstant: 48)
        ])

        btFilter.translatesAutoresizingMaskIntoConstraints = false
        if let img = UIImage(named: "ic_filter") {
            btFilter.setImage(img, for: .normal)
        } else {
            // Fallback: SF Symbol kalau ic_filter tidak ada
            btFilter.setImage(UIImage(systemName: "line.3.horizontal.decrease.circle"), for: .normal)
        }
        btFilter.tintColor = UIColor(hex: "#2563EB")
        filterBar.addSubview(btFilter)
        NSLayoutConstraint.activate([
            btFilter.leadingAnchor.constraint(equalTo: filterBar.leadingAnchor, constant: 8),
            btFilter.centerYAnchor.constraint(equalTo: filterBar.centerYAnchor),
            btFilter.widthAnchor.constraint(equalToConstant: 40),
            btFilter.heightAnchor.constraint(equalToConstant: 40)
        ])
    }

    // MARK: - History List
    private func setupHistoryList() {
        rvHistory.translatesAutoresizingMaskIntoConstraints = false
        rvHistory.isScrollEnabled    = false
        rvHistory.separatorStyle     = .none
        rvHistory.backgroundColor    = .clear
        rvHistory.rowHeight          = UITableView.automaticDimension
        rvHistory.estimatedRowHeight = 120
        rvHistory.register(HistoryCell.self, forCellReuseIdentifier: HistoryCell.reuseId)
        rvHistory.dataSource = self
        rvHistory.delegate   = self

        let footer = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 80))
        rvHistory.tableFooterView = footer

        contentView.addSubview(rvHistory)
        NSLayoutConstraint.activate([
            rvHistory.topAnchor.constraint(equalTo: filterBar.bottomAnchor, constant: 4),
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
        if listHistory.isEmpty { loadHistory() }
    }

    // MARK: - Refresh
    // Setara swipe.setOnRefreshListener
    @objc private func onRefresh() {
        guard !isLoading else { refreshControl.endRefreshing(); return }
        lastId = ""; isLastPage = false; isLoading = false
        currentFilter.removeAll()
        listHistory.removeAll()
        rvHistory.reloadData()
        ambilBanner()
        loadHistory()
        refreshControl.endRefreshing()
    }

    // MARK: - Filter
    // Setara btFilter.setOnClickListener + BottomSheetDialog
    @objc private func onTapFilter() {
        var selectedStatus  = ""
        var selectedTanggal = ""

        let sheet = UIAlertController(title: "Filter", message: nil, preferredStyle: .actionSheet)

        // Status options — setara RadioButton
        let statuses = [("Semua", ""), ("Dinas Luar", "DL"), ("Cuti", "CUTI"),
                        ("Sakit", "SAKIT"), ("BKO", "BKO"), ("DIK", "DIK")]
        for (label, value) in statuses {
            sheet.addAction(UIAlertAction(title: label, style: .default) { [weak self] _ in
                guard let self else { return }
                selectedStatus = value
                self.applyFilter(status: selectedStatus, tanggal: selectedTanggal)
            })
        }

        // Pilih tanggal — setara btTanggal DatePickerDialog
        sheet.addAction(UIAlertAction(title: "Pilih Tanggal...", style: .default) { [weak self] _ in
            guard let self else { return }
            self.showDatePicker { dateStr in
                selectedTanggal = dateStr
                self.applyFilter(status: selectedStatus, tanggal: selectedTanggal)
            }
        })

        sheet.addAction(UIAlertAction(title: "Batal", style: .cancel))
        present(sheet, animated: true)
    }

    private func showDatePicker(completion: @escaping (String) -> Void) {
        let alert = UIAlertController(title: "Pilih Tanggal", message: "\n\n\n\n\n\n\n\n\n", preferredStyle: .alert)
        let picker = UIDatePicker()
        picker.datePickerMode = .date
        picker.preferredDatePickerStyle = .wheels
        picker.translatesAutoresizingMaskIntoConstraints = false
        alert.view.addSubview(picker)
        NSLayoutConstraint.activate([
            picker.topAnchor.constraint(equalTo: alert.view.topAnchor, constant: 50),
            picker.centerXAnchor.constraint(equalTo: alert.view.centerXAnchor)
        ])
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            let fmt = DateFormatter(); fmt.dateFormat = "yyyy-MM-dd"
            completion(fmt.string(from: picker.date))
        })
        alert.addAction(UIAlertAction(title: "Batal", style: .cancel))
        present(alert, animated: true)
    }

    private func applyFilter(status: String, tanggal: String) {
        guard !isLoading else { return }
        currentFilter.removeAll()
        if !status.isEmpty  { currentFilter["status"]  = status }
        if !tanggal.isEmpty { currentFilter["tanggal"] = tanggal }
        lastId = ""; isLastPage = false; isLoading = false
        listHistory.removeAll()
        rvHistory.reloadData()
        loadHistory()
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

    // MARK: - loadHistory
    // Setara private fun loadHistory(filterParams) di Kotlin
    private func loadHistory() {
        guard !isLoading, !isLastPage else { return }
        isLoading = true

        var params = ["lastId": lastId]
        for (k, v) in currentFilter { params[k] = v }

        AuthManager(endpoint: "api/sejarah").checkAuth(
            params: params,
            onSuccess: { [weak self] json in
                guard let self else { return }
                let aesKey = json["aes_key"] as? String ?? ""

                guard let arr = json["data"] as? [[String: Any]], !arr.isEmpty else {
                    DispatchQueue.main.async {
                        self.isLastPage = true
                        self.isLoading  = false
                    }
                    return
                }

                let startPos = self.listHistory.count
                for obj in arr {
                    let id = obj["id"] as? String ?? ""
                    self.listHistory.append(HistoryModel(
                        id:           id,
                        masuk:        CryptoAES.decrypt(obj["masuk"]        as? String ?? "", aesKey),
                        pulang:       CryptoAES.decrypt(obj["pulang"]       as? String ?? "", aesKey),
                        selesai:      CryptoAES.decrypt(obj["selesai"]      as? String ?? "", aesKey),
                        keterangan:   CryptoAES.decrypt(obj["keterangan"]   as? String ?? "", aesKey),
                        latitude:     CryptoAES.decrypt(obj["latitude"]     as? String ?? "", aesKey),
                        longitude:    CryptoAES.decrypt(obj["longitude"]    as? String ?? "", aesKey),
                        ketam:        CryptoAES.decrypt(obj["ketam"]        as? String ?? "", aesKey),
                        jabatan:      CryptoAES.decrypt(obj["jabatan"]      as? String ?? "", aesKey),
                        pangkat:      CryptoAES.decrypt(obj["pangkat"]      as? String ?? "", aesKey),
                        foto:         CryptoAES.decrypt(obj["foto"]         as? String ?? "", aesKey),
                        foto2:        CryptoAES.decrypt(obj["foto2"]        as? String ?? "", aesKey),
                        statusmasuk:  CryptoAES.decrypt(obj["statusmasuk"]  as? String ?? "", aesKey),
                        statuspulang: CryptoAES.decrypt(obj["statuspulang"] as? String ?? "", aesKey),
                        fotopulang:   CryptoAES.decrypt(obj["fotopulang"]   as? String ?? "", aesKey),
                        fotopulang2:  CryptoAES.decrypt(obj["fotopulang2"]  as? String ?? "", aesKey),
                        subdit:       CryptoAES.decrypt(obj["subdit"]       as? String ?? "", aesKey),
                        tanggal:      CryptoAES.decrypt(obj["tanggal"] as? String ?? "", aesKey),
                        ketpul:       CryptoAES.decrypt(obj["ketpul"]       as? String ?? "", aesKey),
                        latpulang:    CryptoAES.decrypt(obj["latpulang"]    as? String ?? "", aesKey),
                        lonpulang:    CryptoAES.decrypt(obj["lonpulang"]    as? String ?? "", aesKey),
                        nip:          CryptoAES.decrypt(obj["nip"]          as? String ?? "", aesKey),
                        nama:         CryptoAES.decrypt(obj["nama"]         as? String ?? "", aesKey)
                    ))
                    self.lastId = id
                }

                DispatchQueue.main.async {
                    let idxs = (startPos ..< self.listHistory.count).map { IndexPath(row: $0, section: 0) }
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
extension History: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        listHistory.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: HistoryCell.reuseId, for: indexPath
        ) as! HistoryCell

        let item = listHistory[indexPath.row]
        cell.hostVC = self   // untuk tap foto → PreviewFotoActivity
        cell.bind(item)

        // Setara pembungkus.setOnClickListener → startActivity(DetailLog)
        cell.onTapCard = { [weak self] in
            guard let self else { return }
            let vc = DetailLog()
            vc.tanggal      = item.tanggal
            vc.masuk        = item.masuk
            vc.pulang       = item.pulang
            vc.keterangan   = item.keterangan
            vc.statusmasuk  = item.statusmasuk
            vc.statuspulang = item.statuspulang
            vc.ketam        = item.ketam
            vc.ketpul       = item.ketpul
            vc.foto         = item.foto
            vc.foto2        = item.foto2
            vc.fotopulang   = item.fotopulang
            vc.fotopulang2  = item.fotopulang2
            vc.lat          = item.latitude
            vc.lng          = item.longitude
            vc.latpulang    = item.latpulang
            vc.lonpulang    = item.lonpulang
            vc.subdit       = item.subdit
            vc.nip          = item.nip
            vc.pangkat      = item.pangkat
            vc.jabatan      = item.jabatan
            vc.nama         = item.nama
            vc.modalPresentationStyle = .fullScreen
            self.present(vc, animated: true)
        }

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
