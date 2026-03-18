//
//  BeritaDetailActivity.swift
//  Doas
//
//  Created by Admin on 06/03/26.
//

import UIKit

// MARK: - BeritaDetailActivity
// Porting dari: BeritaDetailActivity.kt + activity_berita_detail.xml
// CoordinatorLayout + CollapsingToolbarLayout → UIScrollView + stretchy header
class BeritaDetailActivity: UIViewController {

    // MARK: - Data (setara intent.getStringExtra di Android)
    var beritaId:      String = ""
    var beritaJudul:   String = ""
    var beritaIsi:     String = ""
    var beritaTanggal: String = ""
    var beritaFoto:    String = ""
    var beritaPdf:     String = ""

    // MARK: - Constants
    private let heroMaxH: CGFloat = 300   // AppBarLayout height="300dp"
    private let heroMinH: CGFloat = 90    // collapsed = actionBarSize

    // MARK: - Views
    // CollapsingToolbarLayout → stretchy hero header
    private let scrollView     = UIScrollView()
    private let contentView    = UIView()

    // Hero (setara CollapsingToolbarLayout + ImageView)
    private let heroContainer  = UIView()
    private let ivDetailFoto   = UIImageView()
    private let gradientView   = UIView()
    private var heroHeightConstraint: NSLayoutConstraint!

    // Back button (setara toolbar navigationIcon)
    private let btnBack        = UIButton(type: .system)

    // Content (setara LinearLayout padding="20dp")
    private let tvDetailJudul   = UILabel()
    private let tvDetailTanggal = UILabel()
    private let divider         = UIView()
    private let tvDetailIsi     = UITextView()
    private let btnDownloadPdf  = UIButton(type: .system)

    // MARK: - viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupScrollView()
        setupHero()
        setupBackButton()
        setupContent()
        bindData()
    }

    // MARK: - Setup ScrollView
    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.delegate                    = self
        scrollView.contentInsetAdjustmentBehavior = .never  // penting agar hero mulai dari top
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
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
    }

    // MARK: - Hero (CollapsingToolbarLayout + ImageView + gradient)
    private func setupHero() {
        heroContainer.translatesAutoresizingMaskIntoConstraints = false
        heroContainer.clipsToBounds = true
        contentView.addSubview(heroContainer)

        heroHeightConstraint = heroContainer.heightAnchor.constraint(equalToConstant: heroMaxH)
        NSLayoutConstraint.activate([
            heroContainer.topAnchor.constraint(equalTo: contentView.topAnchor),
            heroContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            heroContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            heroHeightConstraint
        ])

        // ivDetailFoto — setara ImageView scaleType="centerCrop"
        ivDetailFoto.translatesAutoresizingMaskIntoConstraints = false
        ivDetailFoto.contentMode  = .scaleAspectFill
        ivDetailFoto.clipsToBounds = true
        ivDetailFoto.image         = UIImage(named: "doas2")
        ivDetailFoto.backgroundColor = .darkGray
        heroContainer.addSubview(ivDetailFoto)
        NSLayoutConstraint.activate([
            ivDetailFoto.topAnchor.constraint(equalTo: heroContainer.topAnchor),
            ivDetailFoto.bottomAnchor.constraint(equalTo: heroContainer.bottomAnchor),
            ivDetailFoto.leadingAnchor.constraint(equalTo: heroContainer.leadingAnchor),
            ivDetailFoto.trailingAnchor.constraint(equalTo: heroContainer.trailingAnchor)
        ])

        // Gradient bawah hero — setara @drawable/hero_gradient, height=120dp
        gradientView.translatesAutoresizingMaskIntoConstraints = false
        gradientView.isUserInteractionEnabled = false
        heroContainer.addSubview(gradientView)
        NSLayoutConstraint.activate([
            gradientView.bottomAnchor.constraint(equalTo: heroContainer.bottomAnchor),
            gradientView.leadingAnchor.constraint(equalTo: heroContainer.leadingAnchor),
            gradientView.trailingAnchor.constraint(equalTo: heroContainer.trailingAnchor),
            gradientView.heightAnchor.constraint(equalToConstant: 120)
        ])

        let grad        = CAGradientLayer()
        grad.colors     = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.6).cgColor]
        grad.locations  = [0, 1]
        gradientView.layer.addSublayer(grad)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Update gradient frame setelah layout selesai
        gradientView.layer.sublayers?.first?.frame = gradientView.bounds
    }

    // MARK: - Back button (setara toolbar.setNavigationOnClickListener { finish() })
    private func setupBackButton() {
        btnBack.translatesAutoresizingMaskIntoConstraints = false
        let img = UIImage(systemName: "chevron.left")?
            .withConfiguration(UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold))
        btnBack.setImage(img, for: .normal)
        btnBack.tintColor  = .white
        btnBack.backgroundColor = UIColor.black.withAlphaComponent(0.35)
        btnBack.layer.cornerRadius = 18
        btnBack.addTarget(self, action: #selector(tapBack), for: .touchUpInside)

        // Tambah di view bukan contentView agar tetap visible saat scroll
        view.addSubview(btnBack)
        NSLayoutConstraint.activate([
            btnBack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            btnBack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            btnBack.widthAnchor.constraint(equalToConstant: 36),
            btnBack.heightAnchor.constraint(equalToConstant: 36)
        ])
    }

    @objc private func tapBack() { dismiss(animated: true) }

    // MARK: - Content (setara LinearLayout padding="20dp")
    private func setupContent() {
        let stack = UIStackView()
        stack.axis      = .vertical
        stack.spacing   = 0
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: heroContainer.bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -32)
        ])

        // tvDetailJudul — textSize="22sp" textStyle="bold"
        tvDetailJudul.font          = .boldSystemFont(ofSize: 22)
        tvDetailJudul.textColor     = .black
        tvDetailJudul.numberOfLines = 0
        stack.addArrangedSubview(tvDetailJudul)
        stack.setCustomSpacing(8, after: tvDetailJudul)

        // tvDetailTanggal — textSize="12sp" textColor="text_muted"
        tvDetailTanggal.font      = .systemFont(ofSize: 12)
        tvDetailTanggal.textColor = UIColor(hex: "#9CA3AF")
        stack.addArrangedSubview(tvDetailTanggal)
        stack.setCustomSpacing(16, after: tvDetailTanggal)

        // Divider — View width="60dp" height="4dp" background=colorPrimary
        divider.translatesAutoresizingMaskIntoConstraints = false
        divider.backgroundColor = UIColor(hex: "#2563EB")
        divider.layer.cornerRadius = 2
        stack.addArrangedSubview(divider)
        NSLayoutConstraint.activate([
            divider.heightAnchor.constraint(equalToConstant: 4),
            divider.widthAnchor.constraint(equalToConstant: 60)
        ])
        stack.setCustomSpacing(20, after: divider)

        // tvDetailIsi — replaced UILabel with UITextView for HTML rendering
        tvDetailIsi.font = .systemFont(ofSize: 16)
        tvDetailIsi.textColor = UIColor(hex: "#333333")
        tvDetailIsi.isEditable = false
        tvDetailIsi.isScrollEnabled = false
        tvDetailIsi.backgroundColor = .clear
        tvDetailIsi.textContainerInset = .zero
        tvDetailIsi.textContainer.lineFragmentPadding = 0
        stack.addArrangedSubview(tvDetailIsi)
        stack.setCustomSpacing(32, after: tvDetailIsi)

        // btnDownloadPdf — height="56dp" cornerRadius="12dp" visibility="gone" default
        btnDownloadPdf.setTitle("Download Lampiran PDF", for: .normal)
        btnDownloadPdf.titleLabel?.font   = .boldSystemFont(ofSize: 16)
        btnDownloadPdf.setTitleColor(.white, for: .normal)
        btnDownloadPdf.backgroundColor    = UIColor(hex: "#2563EB")
        btnDownloadPdf.layer.cornerRadius = 12
        btnDownloadPdf.contentEdgeInsets  = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        btnDownloadPdf.isHidden           = true   // visibility="gone" default
        btnDownloadPdf.addTarget(self, action: #selector(tapDownloadPdf), for: .touchUpInside)
        stack.addArrangedSubview(btnDownloadPdf)
        NSLayoutConstraint.activate([
            btnDownloadPdf.heightAnchor.constraint(equalToConstant: 56)
        ])
        stack.setCustomSpacing(32, after: btnDownloadPdf)

        // Initial placeholder for tvDetailIsi (empty attributed string with paragraph style)
        let placeholderHtml = ""
        if let data = placeholderHtml.data(using: .utf8),
           let attributed = try? NSAttributedString(
               data: data,
               options: [
                   .documentType: NSAttributedString.DocumentType.html,
                   .characterEncoding: String.Encoding.utf8.rawValue
               ],
               documentAttributes: nil
           ) {
            tvDetailIsi.attributedText = attributed
        } else {
            tvDetailIsi.text = ""
        }
    }

    // MARK: - Bind data (setara onCreate intent.getStringExtra)
    private func bindData() {
        // tvDetailJudul.text = judul
        tvDetailJudul.text   = beritaJudul
        tvDetailTanggal.text = beritaTanggal

        // Html.fromHtml(isi) — iOS pakai NSAttributedString dengan html documentType
        if let data = beritaIsi.data(using: .utf8),
           let attributed = try? NSAttributedString(
               data: data,
               options: [
                   .documentType: NSAttributedString.DocumentType.html,
                   .characterEncoding: String.Encoding.utf8.rawValue
               ],
               documentAttributes: nil
           ) {
            tvDetailIsi.attributedText = attributed
        } else {
            tvDetailIsi.text = beritaIsi
        }

        // Load foto — setara Coil load dengan header Authorization
        let token  = SecurePrefs().getAccessToken() ?? ""
        let urlStr = AppConfig.BASE_URL + "api/media/berita/" + beritaFoto
        if let url = URL(string: urlStr) {
            ivDetailFoto.loadImage(url: url, token: token, placeholder: UIImage(named: "doas2"))
        }

        // btnDownloadPdf visibility — setara if (pdf.isNotEmpty())
        btnDownloadPdf.isHidden = beritaPdf.isEmpty
    }

    // MARK: - Download PDF
    // Setara: Auto.downloadPdfVolley(this, urlPdf, pdf, token)
    @objc private func tapDownloadPdf() {
        guard NetworkHelper.isInternetAvailable() else {
            let alert = UIAlertController(title: nil, message: "Tidak ada koneksi internet", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        let token  = SecurePrefs().getAccessToken() ?? ""
        let urlPdf = AppConfig.BASE_URL + "api/media/pdf/" + beritaPdf
        PdfDownloader.download(url: urlPdf, filename: beritaPdf, token: token, from: self)
    }
}

// MARK: - Collapsing toolbar saat scroll
// Setara: CollapsingToolbarLayout app:layout_scrollFlags="scroll|exitUntilCollapsed"
extension BeritaDetailActivity: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let y        = scrollView.contentOffset.y
        let newH     = max(heroMinH, heroMaxH - y)
        heroHeightConstraint.constant = newH

        // Parallax effect — setara app:layout_collapseMode="parallax"
        if y > 0 {
            ivDetailFoto.transform = CGAffineTransform(translationX: 0, y: y * 0.5)
        } else {
            // Stretch saat pull down
            ivDetailFoto.transform = .identity
            heroHeightConstraint.constant = heroMaxH + (-y)
        }

        // Back button selalu visible, tapi tint ikut collapse
        let progress = min(max((heroMaxH - newH) / (heroMaxH - heroMinH), 0), 1)
        btnBack.backgroundColor = progress > 0.7
            ? UIColor(hex: "#2563EB").withAlphaComponent(0.9)
            : UIColor.black.withAlphaComponent(0.35)
    }
}
