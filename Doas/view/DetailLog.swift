//
//  DetailLog.swift
//  Doas
//
//  Created by Admin on 07/03/26.
//

import UIKit

class DetailLog: UIViewController {

    // MARK: - Data (diset dari History sebelum present)
    var tanggal:     String = ""
    var masuk:       String = ""
    var pulang:      String = ""
    var keterangan:  String = ""
    var statusmasuk: String = ""
    var statuspulang:String = ""
    var ketam:       String = ""
    var ketpul:      String = ""
    var foto:        String = ""
    var foto2:       String = ""
    var fotopulang:  String = ""
    var fotopulang2: String = ""
    var lat:         String = ""
    var lng:         String = ""
    var latpulang:   String = ""
    var lonpulang:   String = ""
    var subdit:      String = ""
    var nip:         String = ""
    var pangkat:     String = ""
    var jabatan:     String = ""
    var nama:        String = ""

    // MARK: - UI
    private let scrollView  = UIScrollView()
    private let contentView = UIView()

    // Card utama
    private let card         = UIView()
    private let tvTanggal    = UILabel()
    private let tvKet        = UILabel()   // chip status
    private let tvSubdit     = UILabel()
    private let divider1     = UIView()

    // Masuk
    private let tvJamLabel   = UILabel()
    private let tvJam        = UILabel()
    private let imgFoto      = UIImageView()
    private let imgFoto2     = UIImageView()
    private let tvKetamLabel = UILabel()
    private let tvKetam      = UILabel()
    private let divider2     = UIView()

    // Pulang
    private let tvPulangLabel  = UILabel()
    private let tvPulang       = UILabel()
    private let layoutThumbPulang = UIStackView()
    private let imgFotoPulang  = UIImageView()
    private let imgFotoPulang2 = UIImageView()
    private let tvLabelKRP     = UILabel()
    private let tvKepul        = UILabel()

    // Lokasi
    private let lokasiBox      = UIView()
    private let tvLat          = UILabel()
    private let tvAlamat       = UILabel()
    private let dividerLokasi  = UIView()
    private let tvLatPulang    = UILabel()
    private let tvAlamatPulang = UILabel()

    // MARK: - viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(hex: "#F1F5F9")
        setupNavbar()
        setupLayout()
        bindData()
    }

    // MARK: - Navbar (setara Toolbar + back button)
    private func setupNavbar() {
        let navBar = UIView()
        navBar.translatesAutoresizingMaskIntoConstraints = false
        navBar.backgroundColor = .clear
        view.addSubview(navBar)
        NSLayoutConstraint.activate([
            navBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            navBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            navBar.heightAnchor.constraint(equalToConstant: 56)
        ])

        let btnBack = UIButton(type: .system)
        btnBack.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        btnBack.tintColor = UIColor(hex: "#111827")
        btnBack.translatesAutoresizingMaskIntoConstraints = false
        btnBack.addTarget(self, action: #selector(onBack), for: .touchUpInside)
        navBar.addSubview(btnBack)
        NSLayoutConstraint.activate([
            btnBack.leadingAnchor.constraint(equalTo: navBar.leadingAnchor, constant: 16),
            btnBack.centerYAnchor.constraint(equalTo: navBar.centerYAnchor)
        ])

        let tvTitle = UILabel()
        tvTitle.text = "Detail Log Absensi"
        tvTitle.font = .boldSystemFont(ofSize: 17)
        tvTitle.textColor = UIColor(hex: "#111827")
        tvTitle.translatesAutoresizingMaskIntoConstraints = false
        navBar.addSubview(tvTitle)
        NSLayoutConstraint.activate([
            tvTitle.centerXAnchor.constraint(equalTo: navBar.centerXAnchor),
            tvTitle.centerYAnchor.constraint(equalTo: navBar.centerYAnchor)
        ])

        // Hero gradient bg — setara <View background="@drawable/hero_gradient" height=300dp>
        let heroBg = UIView()
        heroBg.translatesAutoresizingMaskIntoConstraints = false
        heroBg.backgroundColor = UIColor(hex: "#2563EB")
        view.insertSubview(heroBg, at: 0)
        NSLayoutConstraint.activate([
            heroBg.topAnchor.constraint(equalTo: view.topAnchor),
            heroBg.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            heroBg.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            heroBg.heightAnchor.constraint(equalToConstant: 300)
        ])
    }

    @objc private func onBack() { dismiss(animated: true) }

    // MARK: - Layout
    private func setupLayout() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 56),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

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

        setupCard()
    }

    private func setupCard() {
        // Card utama — setara MaterialCardView cornerRadius=20
        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor    = .white
        card.layer.cornerRadius = 20
        card.layer.shadowColor  = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.08
        card.layer.shadowRadius  = 6
        card.layer.shadowOffset  = CGSize(width: 0, height: 2)
        card.layer.borderWidth   = 1
        card.layer.borderColor   = UIColor(hex: "#E2E8F0").cgColor
        contentView.addSubview(card)
        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -32)
        ])

        let inner = UIStackView()
        inner.axis = .vertical; inner.spacing = 0
        inner.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(inner)
        NSLayoutConstraint.activate([
            inner.topAnchor.constraint(equalTo: card.topAnchor, constant: 20),
            inner.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -20),
            inner.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            inner.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20)
        ])

        // --- Row: Tanggal + Chip Status ---
        let rowTop = UIStackView()
        rowTop.axis = .horizontal; rowTop.alignment = .center
        inner.addArrangedSubview(rowTop)
        inner.setCustomSpacing(16, after: rowTop)

        tvTanggal.font = .boldSystemFont(ofSize: 16)
        tvTanggal.textColor = UIColor(hex: "#111827")
        tvTanggal.setContentHuggingPriority(.defaultLow, for: .horizontal)
        rowTop.addArrangedSubview(tvTanggal)

        // UIStackView punya intrinsicContentSize — chip tidak stretching
        let chipBg = UIStackView()
        chipBg.axis = .horizontal
        chipBg.layoutMargins = UIEdgeInsets(top: 4, left: 12, bottom: 4, right: 12)
        chipBg.isLayoutMarginsRelativeArrangement = true
        chipBg.backgroundColor    = UIColor(hex: "#E8F5E9")
        chipBg.layer.cornerRadius = 8
        chipBg.setContentHuggingPriority(.required, for: .horizontal)
        chipBg.setContentCompressionResistancePriority(.required, for: .horizontal)

        tvKet.font = .boldSystemFont(ofSize: 12)
        tvKet.textColor = UIColor(hex: "#2E7D32")
        chipBg.addArrangedSubview(tvKet)
        rowTop.addArrangedSubview(chipBg)

        // Subdit
        tvSubdit.font = .boldSystemFont(ofSize: 13)
        tvSubdit.textColor = UIColor(hex: "#2563EB")
        tvSubdit.numberOfLines = 0
        inner.addArrangedSubview(tvSubdit)
        inner.setCustomSpacing(20, after: tvSubdit)

        // Divider
        makeDivider(divider1)
        inner.addArrangedSubview(divider1)
        inner.setCustomSpacing(20, after: divider1)

        // --- MASUK SECTION ---
        inner.addArrangedSubview(makeSectionHeader(label: "Absen Masuk", color: UIColor(hex: "#2563EB")))
        inner.setCustomSpacing(12, after: inner.arrangedSubviews.last!)

        // Foto masuk row
        let fotoMasukRow = makeFotoRow(img1: imgFoto, img2: imgFoto2)
        inner.addArrangedSubview(fotoMasukRow)
        inner.setCustomSpacing(12, after: fotoMasukRow)

        makeLabel(tvKetamLabel, text: "Keterangan Masuk", size: 12, color: UIColor(hex: "#6B7280"))
        inner.addArrangedSubview(tvKetamLabel)
        inner.setCustomSpacing(4, after: tvKetamLabel)

        tvKetam.font = .systemFont(ofSize: 13)
        tvKetam.textColor = UIColor(hex: "#64748B")
        tvKetam.numberOfLines = 0
        tvKetam.backgroundColor = UIColor(hex: "#F8FAFC")
        tvKetam.layer.cornerRadius = 6
        tvKetam.clipsToBounds = true
        // padding via wrapper
        let ketamWrap = padded(tvKetam, padding: 12)
        inner.addArrangedSubview(ketamWrap)
        inner.setCustomSpacing(24, after: ketamWrap)

        makeDivider(divider2)
        inner.addArrangedSubview(divider2)
        inner.setCustomSpacing(24, after: divider2)

        // --- PULANG SECTION ---
        inner.addArrangedSubview(makeSectionHeader(label: "Absen Pulang", color: UIColor(hex: "#F59E0B")))
        inner.setCustomSpacing(12, after: inner.arrangedSubviews.last!)

        // layoutThumbPulang — hidden kalau belum pulang
        layoutThumbPulang.axis = .horizontal; layoutThumbPulang.spacing = 12
        layoutThumbPulang.alignment = .leading
        layoutThumbPulang.isHidden = true
        [imgFotoPulang, imgFotoPulang2].forEach { iv in
            iv.contentMode   = .scaleAspectFill
            iv.clipsToBounds = true
            iv.layer.cornerRadius = 12
            iv.backgroundColor = UIColor(hex: "#EEEEEE")
            iv.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                iv.widthAnchor.constraint(equalToConstant: 100),
                iv.heightAnchor.constraint(equalToConstant: 100)
            ])
            layoutThumbPulang.addArrangedSubview(iv)
        }
        // Spacer agar foto tidak stretch — sama seperti makeFotoRow
        let spacerPulang = UIView()
        spacerPulang.setContentHuggingPriority(.defaultLow, for: .horizontal)
        layoutThumbPulang.addArrangedSubview(spacerPulang)
        inner.addArrangedSubview(layoutThumbPulang)
        inner.setCustomSpacing(12, after: layoutThumbPulang)

        tvLabelKRP.font = .systemFont(ofSize: 12)
        tvLabelKRP.textColor = UIColor(hex: "#6B7280")
        tvLabelKRP.text = "Keterangan Pulang"
        tvLabelKRP.isHidden = true
        inner.addArrangedSubview(tvLabelKRP)
        inner.setCustomSpacing(4, after: tvLabelKRP)

        tvKepul.font = .systemFont(ofSize: 13)
        tvKepul.textColor = UIColor(hex: "#6B7280")
        tvKepul.numberOfLines = 0
        tvKepul.backgroundColor = UIColor(hex: "#F8FAFC")
        tvKepul.layer.cornerRadius = 6
        tvKepul.clipsToBounds = true
        tvKepul.isHidden = true
        let kepulWrap = padded(tvKepul, padding: 12)
        kepulWrap.isHidden = true
        inner.addArrangedSubview(kepulWrap)
        inner.setCustomSpacing(24, after: kepulWrap)

        // --- LOKASI SECTION ---
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

        // Lokasi Masuk
        let lokasiMasukRow = makeLokasiRow(
            title: "Lokasi Absen Masuk",
            coordLabel: tvLat,
            alamatLabel: tvAlamat,
            color: UIColor(hex: "#2563EB")
        )
        lokasiStack.addArrangedSubview(lokasiMasukRow)
        lokasiStack.setCustomSpacing(12, after: lokasiMasukRow)

        makeDivider(dividerLokasi)
        lokasiStack.addArrangedSubview(dividerLokasi)
        lokasiStack.setCustomSpacing(12, after: dividerLokasi)

        // Lokasi Pulang
        let lokasiPulangRow = makeLokasiRow(
            title: "Lokasi Absen Pulang",
            coordLabel: tvLatPulang,
            alamatLabel: tvAlamatPulang,
            color: UIColor(hex: "#F59E0B")
        )
        lokasiStack.addArrangedSubview(lokasiPulangRow)

        inner.addArrangedSubview(lokasiBox)
    }

    // MARK: - bindData
    private func bindData() {
        tvTanggal.text = tanggal
        tvKet.text     = keterangan.uppercased() == "DL" ? "Dinas Luar" : keterangan.uppercased()
        tvSubdit.text  = "Nama : \(nama)\nSubdit : \(subdit)\nNIP : \(nip)\nJabatan : \(jabatan)\nPangkat : \(pangkat)"
        tvKetam.text   = ketam

        // Jam masuk
        tvJam.text = "\(masuk) (\(statusmasuk))"

        // Pulang
        if pulang.isEmpty {
            tvPulang.text = "Belum Absen"
        } else {
            tvPulang.text = "\(pulang) (\(statuspulang))"
            layoutThumbPulang.isHidden = false
            tvLabelKRP.isHidden = false
            if !ketpul.isEmpty {
                tvKepul.text = ketpul
                // unhide kepulWrap
                if let wrap = tvKepul.superview {
                    wrap.isHidden = false
                }
                tvKepul.isHidden = false
            }
        }

        // Lokasi Masuk
        if !lat.isEmpty && !lng.isEmpty {
            tvLat.text = "Koordinat: \(lat), \(lng)"
            Auto.getAddressFromLatLng(lat: Double(lat) ?? 0, lon: Double(lng) ?? 0) { [weak self] alamat in
                self?.tvAlamat.text = alamat
            }
        } else {
            tvLat.text = "Koordinat: -"
            tvAlamat.text = "-"
        }

        // Lokasi Pulang
        if !latpulang.isEmpty && !lonpulang.isEmpty {
            tvLatPulang.text = "Koordinat: \(latpulang), \(lonpulang)"
            Auto.getAddressFromLatLng(lat: Double(latpulang) ?? 0, lon: Double(lonpulang) ?? 0) { [weak self] alamat in
                self?.tvAlamatPulang.text = alamat
            }
        } else {
            tvLatPulang.text = "Koordinat: -"
            tvAlamatPulang.text = "-"
        }

        // Foto Masuk — hide kalau kosong, setara visibility=gone di Android
        if foto.isEmpty {
            imgFoto.isHidden = true
        } else {
            Auto.loadingFoto(imageView: imgFoto, file: foto, tanggal: tanggal, from: self)
        }
        if foto2.isEmpty {
            imgFoto2.isHidden = true
        } else {
            Auto.loadingFoto(imageView: imgFoto2, file: foto2, tanggal: tanggal, from: self)
        }

        // Foto Pulang
        // Foto Pulang — hide kalau kosong
        if fotopulang.isEmpty {
            imgFotoPulang.isHidden = true
        } else {
            Auto.loadingFoto(imageView: imgFotoPulang, file: fotopulang, tanggal: tanggal, from: self)
        }
        if fotopulang2.isEmpty {
            imgFotoPulang2.isHidden = true
        } else {
            Auto.loadingFoto(imageView: imgFotoPulang2, file: fotopulang2, tanggal: tanggal, from: self)
        }
    }

    // MARK: - Helpers

    private func makeDivider(_ v: UIView) {
        v.backgroundColor = UIColor(hex: "#E2E8F0")
        v.translatesAutoresizingMaskIntoConstraints = false
        v.heightAnchor.constraint(equalToConstant: 1).isActive = true
    }

    private func makeLabel(_ label: UILabel, text: String, size: CGFloat, color: UIColor) {
        label.text = text; label.font = .systemFont(ofSize: size); label.textColor = color
    }

    // Section header: garis warna vertikal + label jam
    private func makeSectionHeader(label: String, color: UIColor) -> UIView {
        let row = UIStackView()
        row.axis = .horizontal; row.spacing = 12; row.alignment = .center

        let bar = UIView()
        bar.backgroundColor = color
        bar.translatesAutoresizingMaskIntoConstraints = false
        bar.widthAnchor.constraint(equalToConstant: 4).isActive = true
        bar.heightAnchor.constraint(equalToConstant: 40).isActive = true
        row.addArrangedSubview(bar)

        let col = UIStackView()
        col.axis = .vertical; col.spacing = 2
        row.addArrangedSubview(col)

        let lbl = UILabel()
        lbl.text = label; lbl.font = .systemFont(ofSize: 12); lbl.textColor = UIColor(hex: "#6B7280")
        col.addArrangedSubview(lbl)

        // reuse tvJam / tvPulang berdasarkan label
        let ismasuk = label.contains("Masuk")
        let tvTime = ismasuk ? tvJam : tvPulang
        tvTime.font = .boldSystemFont(ofSize: 18)
        tvTime.textColor = UIColor(hex: "#111827")
        col.addArrangedSubview(tvTime)

        return row
    }

    private func makeFotoRow(img1: UIImageView, img2: UIImageView) -> UIView {
        let row = UIStackView()
        row.axis = .horizontal; row.spacing = 12; row.alignment = .leading
        [img1, img2].forEach { iv in
            iv.contentMode   = .scaleAspectFill
            iv.clipsToBounds = true
            iv.layer.cornerRadius = 12
            iv.backgroundColor = UIColor(hex: "#EEEEEE")
            iv.image = UIImage(named: "doas2")
            iv.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                iv.widthAnchor.constraint(equalToConstant: 100),
                iv.heightAnchor.constraint(equalToConstant: 100)
            ])
            row.addArrangedSubview(iv)
        }
        // Spacer agar dua foto tidak stretch memenuhi lebar card
        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        row.addArrangedSubview(spacer)
        return row
    }

    private func makeLokasiRow(title: String, coordLabel: UILabel, alamatLabel: UILabel, color: UIColor) -> UIView {
        let row = UIStackView()
        row.axis = .horizontal; row.spacing = 8; row.alignment = .top

        let icon = UIImageView(image: UIImage(systemName: "location.fill"))
        icon.tintColor = color
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.widthAnchor.constraint(equalToConstant: 16).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 16).isActive = true
        row.addArrangedSubview(icon)

        let col = UIStackView()
        col.axis = .vertical; col.spacing = 2
        row.addArrangedSubview(col)

        let tvTitle = UILabel()
        tvTitle.text = title; tvTitle.font = .boldSystemFont(ofSize: 11); tvTitle.textColor = UIColor(hex: "#111827")
        col.addArrangedSubview(tvTitle)

        coordLabel.font = .systemFont(ofSize: 10); coordLabel.textColor = UIColor(hex: "#6B7280")
        coordLabel.numberOfLines = 0
        col.addArrangedSubview(coordLabel)

        alamatLabel.font = .systemFont(ofSize: 10); alamatLabel.textColor = UIColor(hex: "#6B7280")
        alamatLabel.numberOfLines = 0
        alamatLabel.text = "Mencari alamat..."
        col.addArrangedSubview(alamatLabel)

        return row
    }

    // Bungkus label dengan padding — setara android:padding
    private func padded(_ label: UILabel, padding: CGFloat) -> UIView {
        let wrap = UIView()
        wrap.backgroundColor    = label.backgroundColor
        wrap.layer.cornerRadius = label.layer.cornerRadius
        wrap.clipsToBounds      = true
        label.translatesAutoresizingMaskIntoConstraints = false
        label.backgroundColor = .clear
        wrap.addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: wrap.topAnchor, constant: padding),
            label.bottomAnchor.constraint(equalTo: wrap.bottomAnchor, constant: -padding),
            label.leadingAnchor.constraint(equalTo: wrap.leadingAnchor, constant: padding),
            label.trailingAnchor.constraint(equalTo: wrap.trailingAnchor, constant: -padding)
        ])
        return wrap
    }
}
