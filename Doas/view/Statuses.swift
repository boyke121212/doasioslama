//
//  Statuses.swift
//  Doas
//
//  Created by Admin on 03/03/26.
//

import UIKit

class Statuses: Boyke, UIScrollViewDelegate {

    let scrollView    = UIScrollView()
    let contentView   = UIView()
    let tbMenuStack   = UIStackView()
    let gridContainer = UIStackView()
    var jamserver: String?
    var pulang: String?
    private var bannerSlider: BannerSlider!

    let btAbsen   = MenuItemView(title: "Absen",   iconName: "ic_fingerprint")
    let btStatus  = MenuItemView(title: "Status",  iconName: "ic_status", active: true)
    let btInfo    = MenuItemView(title: "Berita",  iconName: "ic_news")
    let btLog     = MenuItemView(title: "Log",     iconName: "ic_log")
    let btProfile = MenuItemView(title: "Profile", iconName: "ic_person")
    let btDoas    = MenuItemView(title: "DOAS",    iconName: "ic_about")

    // MARK: - HERO
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

    // MARK: - CARD STATUS — semua binding setara activity_statuses.xml
    var cardStatusHariIni  = UIView()
    var tvTanggal          = UILabel()
    var tvKet              = UILabel()
    var tvSubdit           = UILabel()
    var tvJam              = UILabel()
    var imgFoto            = UIImageView()
    var imgFoto2           = UIImageView()
    var tvLabelKR          = UILabel()
    var tvKetam            = UILabel()
    var tvLabelR           = UILabel()
    var tvPulang           = UILabel()
    var layoutThumbPulang  = UIStackView()
    var imgFotoPulang      = UIImageView()
    var imgFotoPulang2     = UIImageView()
    var tvLabelKRP         = UILabel()
    var tvKepul            = UILabel()
    var btnPulang          = UIButton(type: .system)
    var tvLat              = UILabel()
    var tvAlamat           = UILabel()
    var tvLatPulang        = UILabel()
    var tvAlamatPulang     = UILabel()

    // Callback btnPulang — diset oleh Auto.renderAbsensi
    var onTapBtnPulang: (() -> Void)?
    @objc func didTapBtnPulang() { onTapBtnPulang?() }

    // MARK: - viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLayout()

        let empty = UIViewController()
        empty.view.backgroundColor = .clear
        pageController.setViewControllers([empty], direction: .forward, animated: false)
        bannerSlider = BannerSlider(parent: self, container: heroContainer)

        btAbsen.addTarget(self,   action: #selector(ontapMe),     for: .touchUpInside)
        btInfo.addTarget(self,    action: #selector(ontapInfo),   for: .touchUpInside)
        btDoas.addTarget(self,    action: #selector(ontapDoas),   for: .touchUpInside)
        btLog.addTarget(self,     action: #selector(ontapLog),    for: .touchUpInside)
        btProfile.addTarget(self, action: #selector(bukaprofile), for: .touchUpInside)
    }

    @objc private func bukaprofile() {
        let vc = ProfileActivity(); vc.modalPresentationStyle = .fullScreen; present(vc, animated: false)
    }
    @objc private func ontapInfo() { openPage(Berita()) }
    @objc private func ontapDoas() { openPage(Doas()) }
    @objc private func ontapLog()  { openPage(History()) }
    @objc private func ontapMe()   { openPage(Home()) }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let y = scrollView.contentOffset.y
        let newHeight = max(headerMinHeight, headerMaxHeight - y)
        headerHeightConstraint.constant = newHeight
        let progress = min(max((headerMaxHeight - newHeight) / (headerMaxHeight - headerMinHeight), 0), 1)
        tvJudul.alpha = 1 - 0.25 * progress
        tvIsi.alpha   = 1 - 0.6  * progress
        view.layoutIfNeeded()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        ambilAbsen()
    }

    func showAlert(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    // MARK: - Layout
    private func setupLayout() {
        view.backgroundColor = .systemBackground
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.delegate = self
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
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
        setupHeroSection()
        setupFloatingMenu()
        setupCardStatus()
    }

    // MARK: - Hero
    private func setupHeroSection() {
        heroContainer.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(heroContainer)
        NSLayoutConstraint.activate([
            heroContainer.topAnchor.constraint(equalTo: contentView.topAnchor),
            heroContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            heroContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            {
                let c = heroContainer.heightAnchor.constraint(equalToConstant: headerMaxHeight)
                self.headerHeightConstraint = c; return c
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
            // TIDAK pin bottomAnchor — cardStatus yang anchoring ke bottom
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

    // MARK: - Card Status (1:1 dari activity_statuses.xml)
    private func setupCardStatus() {

        // cardStatusHariIni — MaterialCardView cornerRadius=20 elevation=4
        cardStatusHariIni.translatesAutoresizingMaskIntoConstraints = false
        cardStatusHariIni.backgroundColor     = .white
        cardStatusHariIni.layer.cornerRadius  = 20
        cardStatusHariIni.layer.shadowColor   = UIColor.black.cgColor
        cardStatusHariIni.layer.shadowOpacity = 0.10
        cardStatusHariIni.layer.shadowRadius  = 6
        cardStatusHariIni.layer.shadowOffset  = CGSize(width: 0, height: 2)
        cardStatusHariIni.layer.borderWidth   = 1
        cardStatusHariIni.layer.borderColor   = UIColor(hex: "#E2E8F0").cgColor
        cardStatusHariIni.isHidden            = true
        contentView.addSubview(cardStatusHariIni)
        NSLayoutConstraint.activate([
            cardStatusHariIni.topAnchor.constraint(equalTo: floatingMenuCard.bottomAnchor, constant: 8),
            cardStatusHariIni.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardStatusHariIni.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cardStatusHariIni.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -32)
        ])

        // inner — setara LinearLayout padding=20dp
        let inner = UIStackView()
        inner.axis = .vertical; inner.spacing = 0
        inner.translatesAutoresizingMaskIntoConstraints = false
        cardStatusHariIni.addSubview(inner)
        NSLayoutConstraint.activate([
            inner.topAnchor.constraint(equalTo: cardStatusHariIni.topAnchor, constant: 20),
            inner.bottomAnchor.constraint(equalTo: cardStatusHariIni.bottomAnchor, constant: -20),
            inner.leadingAnchor.constraint(equalTo: cardStatusHariIni.leadingAnchor, constant: 20),
            inner.trailingAnchor.constraint(equalTo: cardStatusHariIni.trailingAnchor, constant: -20)
        ])

        // ── Row: tvTanggal (kiri) + chip tvKet (kanan) ──────────────
        // setara RelativeLayout marginBottom=16dp
        let rowTop = UIStackView()
        rowTop.axis = .horizontal; rowTop.alignment = .center

        tvTanggal.font = .boldSystemFont(ofSize: 16)
        tvTanggal.textColor = UIColor(hex: "#111827")
        tvTanggal.setContentHuggingPriority(.defaultLow, for: .horizontal)
        rowTop.addArrangedSubview(tvTanggal)

        let chipBg = UIStackView()
        chipBg.axis = .horizontal
        chipBg.layoutMargins = UIEdgeInsets(top: 4, left: 12, bottom: 4, right: 12)
        chipBg.isLayoutMarginsRelativeArrangement = true
        chipBg.backgroundColor    = UIColor(hex: "#E8F5E9")
        chipBg.layer.cornerRadius = 8
        chipBg.setContentHuggingPriority(.required, for: .horizontal)
        chipBg.setContentCompressionResistancePriority(.required, for: .horizontal)
        tvKet.font = .boldSystemFont(ofSize: 12); tvKet.textColor = UIColor(hex: "#2E7D32")
        chipBg.addArrangedSubview(tvKet)
        rowTop.addArrangedSubview(chipBg)
        inner.addArrangedSubview(rowTop)
        inner.setCustomSpacing(16, after: rowTop)

        // ── tvSubdit ────────────────────────────────────────────────
        tvSubdit.font = .boldSystemFont(ofSize: 13)
        tvSubdit.textColor = UIColor(hex: "#2563EB")
        tvSubdit.numberOfLines = 0; tvSubdit.isHidden = true
        inner.addArrangedSubview(tvSubdit)
        inner.setCustomSpacing(20, after: tvSubdit)

        // ── Divider ─────────────────────────────────────────────────
        inner.addArrangedSubview(makeDivider())
        inner.setCustomSpacing(20, after: inner.arrangedSubviews.last!)

        // ── MASUK SECTION ───────────────────────────────────────────
        inner.addArrangedSubview(makeSectionHeader(label: "Absen Masuk", timeLabel: tvJam, color: UIColor(hex: "#2563EB")))
        tvJam.font = .boldSystemFont(ofSize: 18); tvJam.textColor = UIColor(hex: "#111827")
        inner.setCustomSpacing(12, after: inner.arrangedSubviews.last!)

        // layoutThumbMasuk
        inner.addArrangedSubview(makeFotoRow(img1: imgFoto, img2: imgFoto2))
        inner.setCustomSpacing(12, after: inner.arrangedSubviews.last!)

        // tvLabelKR
        tvLabelKR.text = "Keterangan Masuk"
        tvLabelKR.font = .systemFont(ofSize: 12); tvLabelKR.textColor = UIColor(hex: "#6B7280")
        tvLabelKR.isHidden = true
        inner.addArrangedSubview(tvLabelKR)
        inner.setCustomSpacing(4, after: tvLabelKR)

        // tvKetam — background #F8FAFC padding=12dp
        tvKetam.font = .systemFont(ofSize: 13); tvKetam.textColor = UIColor(hex: "#64748B")
        tvKetam.numberOfLines = 0; tvKetam.isHidden = true
        inner.addArrangedSubview(padded(tvKetam, bg: UIColor(hex: "#F8FAFC"), padding: 12))
        inner.setCustomSpacing(24, after: inner.arrangedSubviews.last!)

        // ── Divider 2 ───────────────────────────────────────────────
        inner.addArrangedSubview(makeDivider())
        inner.setCustomSpacing(24, after: inner.arrangedSubviews.last!)

        // ── PULANG SECTION ──────────────────────────────────────────
        inner.addArrangedSubview(makeSectionHeader(label: "Absen Pulang", timeLabel: tvPulang, color: UIColor(hex: "#F59E0B")))
        tvPulang.font = .boldSystemFont(ofSize: 18); tvPulang.textColor = UIColor(hex: "#111827")
        tvPulang.isHidden = true
        inner.setCustomSpacing(12, after: inner.arrangedSubviews.last!)

        // layoutThumbPulang — visibility=gone
        layoutThumbPulang.axis = .horizontal; layoutThumbPulang.spacing = 12
        layoutThumbPulang.alignment = .leading; layoutThumbPulang.isHidden = true
        [imgFotoPulang, imgFotoPulang2].forEach { iv in
            iv.contentMode = .scaleAspectFill; iv.clipsToBounds = true
            iv.layer.cornerRadius = 12; iv.backgroundColor = UIColor(hex: "#EEEEEE")
            iv.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                iv.widthAnchor.constraint(equalToConstant: 100),
                iv.heightAnchor.constraint(equalToConstant: 100)
            ])
            layoutThumbPulang.addArrangedSubview(iv)
        }
        let spacerP = UIView(); spacerP.setContentHuggingPriority(.defaultLow, for: .horizontal)
        layoutThumbPulang.addArrangedSubview(spacerP)
        inner.addArrangedSubview(layoutThumbPulang)
        inner.setCustomSpacing(12, after: layoutThumbPulang)

        // tvLabelKRP — visibility=gone
        tvLabelKRP.text = "Keterangan Pulang"
        tvLabelKRP.font = .systemFont(ofSize: 12); tvLabelKRP.textColor = UIColor(hex: "#6B7280")
        tvLabelKRP.isHidden = true
        inner.addArrangedSubview(tvLabelKRP)
        inner.setCustomSpacing(4, after: tvLabelKRP)

        // tvKepul — visibility=gone
        tvKepul.font = .systemFont(ofSize: 13); tvKepul.textColor = UIColor(hex: "#6B7280")
        tvKepul.numberOfLines = 0; tvKepul.isHidden = true
        inner.addArrangedSubview(padded(tvKepul, bg: UIColor(hex: "#F8FAFC"), padding: 12))
        inner.setCustomSpacing(16, after: inner.arrangedSubviews.last!)

        // btnPulang — visibility=gone, setara MaterialButton brand_primary
        btnPulang.setTitle("Lakukan Absen Pulang", for: .normal)
        btnPulang.titleLabel?.font = .boldSystemFont(ofSize: 15)
        btnPulang.setTitleColor(.white, for: .normal)
        btnPulang.backgroundColor    = UIColor(hex: "#2563EB")
        btnPulang.layer.cornerRadius = 14
        btnPulang.isHidden           = true
        btnPulang.translatesAutoresizingMaskIntoConstraints = false
        btnPulang.heightAnchor.constraint(equalToConstant: 56).isActive = true
        btnPulang.addTarget(self, action: #selector(didTapBtnPulang), for: .touchUpInside)
        inner.addArrangedSubview(btnPulang)
        inner.setCustomSpacing(24, after: btnPulang)

        // ── LOKASI SECTION ──────────────────────────────────────────
        // setara LinearLayout background=#F8FAFC padding=12dp marginTop=24dp
        let lokasiBox = UIView()
        lokasiBox.backgroundColor    = UIColor(hex: "#F8FAFC")
        lokasiBox.layer.cornerRadius = 8
        lokasiBox.translatesAutoresizingMaskIntoConstraints = false

        let lokasiStack = UIStackView()
        lokasiStack.axis = .vertical; lokasiStack.spacing = 0
        lokasiStack.translatesAutoresizingMaskIntoConstraints = false
        lokasiBox.addSubview(lokasiStack)
        NSLayoutConstraint.activate([
            lokasiStack.topAnchor.constraint(equalTo: lokasiBox.topAnchor, constant: 12),
            lokasiStack.bottomAnchor.constraint(equalTo: lokasiBox.bottomAnchor, constant: -12),
            lokasiStack.leadingAnchor.constraint(equalTo: lokasiBox.leadingAnchor, constant: 12),
            lokasiStack.trailingAnchor.constraint(equalTo: lokasiBox.trailingAnchor, constant: -12)
        ])

        lokasiStack.addArrangedSubview(makeLokasiRow(
            title: "Lokasi Absen Masuk", coordLabel: tvLat, alamatLabel: tvAlamat,
            color: UIColor(hex: "#2563EB")
        ))
        lokasiStack.setCustomSpacing(12, after: lokasiStack.arrangedSubviews.last!)
        lokasiStack.addArrangedSubview(makeDivider())
        lokasiStack.setCustomSpacing(12, after: lokasiStack.arrangedSubviews.last!)
        lokasiStack.addArrangedSubview(makeLokasiRow(
            title: "Lokasi Absen Pulang", coordLabel: tvLatPulang, alamatLabel: tvAlamatPulang,
            color: UIColor(hex: "#F59E0B")
        ))

        inner.addArrangedSubview(lokasiBox)
    }

    // MARK: - Helpers
    private func makeDivider() -> UIView {
        let v = UIView()
        v.backgroundColor = UIColor(hex: "#E2E8F0")
        v.translatesAutoresizingMaskIntoConstraints = false
        v.heightAnchor.constraint(equalToConstant: 1).isActive = true
        return v
    }

    private func makeSectionHeader(label: String, timeLabel: UILabel, color: UIColor) -> UIView {
        let row = UIStackView(); row.axis = .horizontal; row.spacing = 12; row.alignment = .center
        let bar = UIView(); bar.backgroundColor = color
        bar.translatesAutoresizingMaskIntoConstraints = false
        bar.widthAnchor.constraint(equalToConstant: 4).isActive = true
        bar.heightAnchor.constraint(equalToConstant: 40).isActive = true
        row.addArrangedSubview(bar)
        let col = UIStackView(); col.axis = .vertical; col.spacing = 2
        let lbl = UILabel()
        lbl.text = label; lbl.font = .systemFont(ofSize: 12); lbl.textColor = UIColor(hex: "#6B7280")
        col.addArrangedSubview(lbl)
        col.addArrangedSubview(timeLabel)
        row.addArrangedSubview(col)
        return row
    }

    private func makeFotoRow(img1: UIImageView, img2: UIImageView) -> UIView {
        let row = UIStackView(); row.axis = .horizontal; row.spacing = 12; row.alignment = .leading
        [img1, img2].forEach { iv in
            iv.contentMode = .scaleAspectFill; iv.clipsToBounds = true
            iv.layer.cornerRadius = 12; iv.backgroundColor = UIColor(hex: "#EEEEEE")
            iv.isHidden = true
            iv.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                iv.widthAnchor.constraint(equalToConstant: 100),
                iv.heightAnchor.constraint(equalToConstant: 100)
            ])
            row.addArrangedSubview(iv)
        }
        let spacer = UIView(); spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        row.addArrangedSubview(spacer)
        return row
    }

    private func makeLokasiRow(title: String, coordLabel: UILabel, alamatLabel: UILabel, color: UIColor) -> UIView {
        let row = UIStackView(); row.axis = .horizontal; row.spacing = 8; row.alignment = .top
        let icon = UIImageView(image: UIImage(systemName: "location.fill"))
        icon.tintColor = color
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.widthAnchor.constraint(equalToConstant: 16).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 16).isActive = true
        row.addArrangedSubview(icon)
        let col = UIStackView(); col.axis = .vertical; col.spacing = 2
        let tvTitle = UILabel()
        tvTitle.text = title; tvTitle.font = .boldSystemFont(ofSize: 11); tvTitle.textColor = UIColor(hex: "#111827")
        col.addArrangedSubview(tvTitle)
        coordLabel.font = .systemFont(ofSize: 10); coordLabel.textColor = UIColor(hex: "#6B7280")
        coordLabel.text = "Koordinat: -"; coordLabel.numberOfLines = 0
        col.addArrangedSubview(coordLabel)
        alamatLabel.font = .systemFont(ofSize: 10); alamatLabel.textColor = UIColor(hex: "#6B7280")
        alamatLabel.text = "Mencari alamat..."; alamatLabel.numberOfLines = 0
        col.addArrangedSubview(alamatLabel)
        row.addArrangedSubview(col)
        return row
    }

    private func padded(_ label: UILabel, bg: UIColor, padding: CGFloat) -> UIView {
        let wrap = UIView()
        wrap.backgroundColor = bg; wrap.layer.cornerRadius = 6; wrap.clipsToBounds = true
        label.backgroundColor = .clear
        label.translatesAutoresizingMaskIntoConstraints = false
        wrap.addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: wrap.topAnchor, constant: padding),
            label.bottomAnchor.constraint(equalTo: wrap.bottomAnchor, constant: -padding),
            label.leadingAnchor.constraint(equalTo: wrap.leadingAnchor, constant: padding),
            label.trailingAnchor.constraint(equalTo: wrap.trailingAnchor, constant: -padding)
        ])
        return wrap
    }

    // MARK: - API
    func ambilAbsen() {
        AuthManager(endpoint: "api/ambil_absen").checkAuth(
            params: [:],
            onSuccess: { json in
                guard let status = json["status"] as? String, status == "ok" else { return }

                self.pulang    = json["pulang"]    as? String ?? ""
                self.jamserver = json["jamserver"] as? String ?? ""
                let aesKey     = json["aes_key"]   as? String ?? ""

                if let arr = json["dataabsen"] as? [[String: Any]] {
                    if arr.isEmpty {
                        DispatchQueue.main.async {
                            let alert = UIAlertController(title: nil, message: "Anda Belum Absen Hari ini", preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in self.openPage(Home()) })
                            self.present(alert, animated: true)
                        }
                        return
                    }
                    if let obj = arr.first {
                        Auto.renderAbsensi(vc: self, obj: obj, aesKey: aesKey,
                                           batpul: self.pulang, jamserver: self.jamserver)
                    }
                }

                var listBerita: [BeritaItem] = []
                if let beritaArray = json["berita"] as? [[String: Any]] {
                    for obj in beritaArray {
                        listBerita.append(BeritaItem(
                            id:      obj["id"]      as? String ?? "",
                            judul:   CryptoAES.decrypt(obj["judul"]   as? String ?? "", aesKey),
                            isi:     CryptoAES.decrypt(obj["isi"]     as? String ?? "", aesKey),
                            tanggal: CryptoAES.decrypt(obj["tanggal"]     as? String ?? "", aesKey),
                            foto:    CryptoAES.decrypt(obj["foto"]    as? String ?? "", aesKey),
                            pdf:     CryptoAES.decrypt(obj["pdf"]     as? String ?? "", aesKey)
                        ))
                    }
                }
                DispatchQueue.main.async {
                    if !listBerita.isEmpty {
                        self.bannerSlider.setItems(listBerita)
                        self.tvJudul.text = listBerita[0].judul
                        self.tvIsi.text   = listBerita[0].isi.hendry_htmlToPlain()
                    }
                }
            },
            onLogout: { message in
                DispatchQueue.main.async {
                    if message == "__TIMEOUT__" || message == "__NO_INTERNET__" {
                        self.showAlert("Connection Time Out Error")
                    } else if !message.contains("Verification failed") && !message.contains("Checking Device") {
                        self.showAlert(message)
                    }
                    let vc = Home(); vc.modalPresentationStyle = .fullScreen
                    self.present(vc, animated: false)
                }
            },
            onLoading: { loading in
                DispatchQueue.main.async { loading ? self.showLoading() : self.hideLoading() }
            }
        )
    }
}
