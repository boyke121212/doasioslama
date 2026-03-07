import UIKit

final class AbsenHadir: Boyke, UITextViewDelegate {
    let tvKeterangan = UILabel()
    let inputCard = UIView()
    
    private let cutiOptions = ["Cuti Tahunan", "Cuti Istimewa", "Cuti Ibadah Keagamaan", "Cuti Melahirkan"]
    private var selectedCutiIndex: Int = 0
    let jenisCutiChevron = UIImageView(image: UIImage(systemName: "chevron.down"))

    private var absensiManager: AbsensiManager!
    var jamserver:String?
    var ket:String?
    var kehadiran:String?
    var bataspulang:String?
    var statuspulang:String = ""
    var dari=""
    var ketam=""
    let requirementMap: [String: String] = [
        "ADL": "Persyaratan: Ambil minimal 2 foto",
        "DIK": "Persyaratan: Ambil minimal 2 foto. 1 foto surat Keterangan DIK, 1 lagi foto Absensi",
        "CUTI": "Persyaratan: Ambil minimal 2 foto. 1 foto surat Keterangan Cuti, 1 lagi foto Absensi",
        "BKO": "Persyaratan: Ambil minimal 2 foto. 1 foto surat Keterangan BKO, 1 lagi foto Absensi",
        "SAKIT": "Persyaratan: Ambil minimal 2 foto. 1 foto surat Keterangan Sakit, 1 lagi foto Absensi",
        "PULANG": "Persyaratan: Ambil minimal 2 foto."
    ]
    
    let AlasanMap: [String: String] = [
        "ADL": "Jelaskan Kenapa Anda Dinas Luar",
        "DIK": "Tuliskan Gambaran Tugas DIK anda",
        "CUTI": "Tuliskan Alasan Kenapa Anda Cuti",
        "BKO":  "Tuliskan Gambaran Tugas BKO anda",
        "SAKIT": "Jelaskan Kondisi Kesehatan kamu"
    ]
    
    let keteranganMap: [String: String] = [
        "ADL": "Keterangan Dinas Luar",
        "DIK": "Keterangan DIK",
        "CUTI": "Keterangan Cuti",
        "BKO":  "Keterangan BKO",
        "SAKIT": "Keterangan Sakit"
    ]
    private var menu = "mulai"
    private var timer: Timer?
    
    // UI
    private let previewView = UIView()
    private let resultImage = UIImageView()
    private let thumbStack = UIStackView()
    
    private let tvLiveTime = UILabel()
    private let tvGpsStatus = UILabel()
    
    private let btMulai = UIButton(type: .system)
    private let btKirim = UIButton(type: .system)
    private let btnSwitch = UIButton(type: .system)
    private let btnBack = UIButton(type: .system)
    private let etAlasan = UITextView()
    private let jenisCutiButton = UIButton(type: .system)
    

    // MARK: - Cek Batas Pulang
    // Setara cekBatasPulang() di Android — dipakai saat dari == "PULANG"
    func cekBatasPulang() -> String {
        guard let batas = bataspulang, !batas.isEmpty,
              let jam   = jamserver,   !jam.isEmpty else { return "-" }
        func toMinutes(_ t: String) -> Int {
            let p = t.split(separator: ":").map { Int($0) ?? 0 }
            guard p.count >= 2 else { return 0 }
            return p[0] * 60 + p[1]
        }
        let batasMenit  = toMinutes(batas)
        let serverMenit = toMinutes(jam)
        if serverMenit < batasMenit        { return "PULANG CEPAT" }
        else if serverMenit <= batasMenit + 5 { return "TEPAT WAKTU"  }
        else                               { return "OVERTIME"     }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        absensiManager.updatePreviewFrame()
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        absensiManager.updatePreviewFrame()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        absensiManager = AbsensiManager(
            activity: self,
            previewView: previewView
        )
        setupUI()
        
        updateButtonState(false)
        
        tvLiveTime.isHidden = true
        
        absensiManager.prepare()
        
        startClock()
        
        absensiManager.onGpsStatusChanged = { [weak self] acc in
            guard let self else { return }
            DispatchQueue.main.async {
                let gpsReady = acc != nil && acc! <= 120 && self.absensiManager.lat != nil && self.absensiManager.lon != nil
                if !gpsReady {
                    self.updateButtonState(false)
                    self.tvGpsStatus.text = acc == nil ? "Mencari posisi..." : "Akurasi rendah (\(Int(acc!))m)..."
                } else {
                    self.updateButtonState(true)
                    self.tvGpsStatus.text = "Lokasi terdeteksi"
                }
            }
        }
        
        btnBack.addTarget(self, action: #selector(onBackPressed), for: .touchUpInside)
        btMulai.addTarget(self, action: #selector(onMulaiPressed), for: .touchUpInside)
        btnSwitch.addTarget(self, action: #selector(onSwitchCamera), for: .touchUpInside)
        btKirim.addTarget(self, action: #selector(onKirim), for: .touchUpInside)
        
        switch dari {
        case "DIK", "BKO", "SAKIT":
            etAlasan.isHidden = false
            jenisCutiButton.isHidden = true
            jenisCutiChevron.isHidden=true
            let trimmed = ketam.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                etAlasan.text = trimmed
                etAlasan.textColor = .label
            } else {
                etAlasan.text = AlasanMap[dari]
                etAlasan.textColor = .systemGray3
            }
        case "CUTI":
            etAlasan.isHidden = true
            jenisCutiButton.isHidden = false
            jenisCutiChevron.isHidden=false
            let trimmed = ketam.trimmingCharacters(in: .whitespacesAndNewlines)
            if let idx = cutiOptions.firstIndex(of: trimmed), !trimmed.isEmpty {
                selectedCutiIndex = idx
                if var cfg = jenisCutiButton.configuration {
                    cfg.title = trimmed
                    jenisCutiButton.configuration = cfg
                } else {
                    jenisCutiButton.setTitle(trimmed, for: .normal)
                }
            } else {
                if var cfg = jenisCutiButton.configuration {
                    cfg.title = "Pilih Jenis Cuti"
                    jenisCutiButton.configuration = cfg
                } else {
                    jenisCutiButton.setTitle("Pilih Jenis Cuti", for: .normal)
                }
            }
        case "PULANG":
            // Setara when(kepulangan) di Android AbsenPulang
            statuspulang = cekBatasPulang()
            switch statuspulang {
            case "OVERTIME":
                inputCard.isHidden = false
                tvKeterangan.text  = "Jelaskan Alasan Anda Pulang Lewat Waktu"
                etAlasan.text      = ""
                etAlasan.textColor = .label
            case "TEPAT WAKTU":
                inputCard.isHidden = true
            case "PULANG CEPAT":
                inputCard.isHidden = false
                tvKeterangan.text  = "Jelaskan Alasan Anda Pulang Cepat"
                etAlasan.text      = ""
                etAlasan.textColor = .label
            default:
                inputCard.isHidden = true
            }
            etAlasan.isHidden      = false
            jenisCutiButton.isHidden = true
            jenisCutiChevron.isHidden = true
        default:
            etAlasan.isHidden = false
            jenisCutiButton.isHidden = true
            jenisCutiChevron.isHidden = true
            let trimmed = ketam.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                etAlasan.text = trimmed
                etAlasan.textColor = .label
            } else {
                etAlasan.text = AlasanMap[dari]
                etAlasan.textColor = .systemGray3
            }
        }
    }
    
    private func startClock() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss"
            self.tvLiveTime.text = formatter.string(from: Date())
        }
    }
    
    private func updateButtonState(_ enabled: Bool) {
        btMulai.isEnabled = enabled
        btMulai.alpha = enabled ? 1.0 : 0.5
    }
    
    @objc private func onBackPressed() {
        let vc = MainActivity()
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true)
    }
    
    @objc private func onMulaiPressed() {
        tvLiveTime.isHidden = false
        switch menu {
        case "mulai": startFlow()
        case "capture": captureFlow()
        default: break
        }
    }
    
    @objc private func onSwitchCamera() {
        absensiManager.switchCamera()
    }

    private func setupUI() {
        view.backgroundColor = UIColor.systemGroupedBackground
        let headerDecor = UIView()
        headerDecor.translatesAutoresizingMaskIntoConstraints = false
        headerDecor.backgroundColor = UIColor.systemBlue
        view.addSubview(headerDecor)
        btnBack.translatesAutoresizingMaskIntoConstraints = false
        btnBack.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        btnBack.tintColor = .white
        view.addSubview(btnBack)
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        let contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        let tvTitle = UILabel()
        tvTitle.translatesAutoresizingMaskIntoConstraints = false
        tvTitle.font = UIFont.boldSystemFont(ofSize: 24)
        tvTitle.textColor = .white
        let tvSubtitle = UILabel()
        tvSubtitle.translatesAutoresizingMaskIntoConstraints = false
        if dari == "PULANG" {
            tvTitle.text    = "Absensi Kepulangan"
            tvSubtitle.text = "Ambil foto bukti Kepulangan Anda"
        } else {
            tvTitle.text    = "Absensi Kehadiran"
            tvSubtitle.text = "Ambil foto bukti kehadiran Anda"
        }
        tvSubtitle.textColor = UIColor.white.withAlphaComponent(0.8)
        tvSubtitle.font = UIFont.systemFont(ofSize: 14)
        contentView.addSubview(tvTitle)
        contentView.addSubview(tvSubtitle)
        let statusCard = UIView()
        statusCard.translatesAutoresizingMaskIntoConstraints = false
        statusCard.backgroundColor = .white
        statusCard.layer.cornerRadius = 16
        statusCard.layer.shadowOpacity = 0.1
        statusCard.layer.shadowRadius = 6
        contentView.addSubview(statusCard)
        let tvRequirement = UILabel()
        tvRequirement.translatesAutoresizingMaskIntoConstraints = false
        tvRequirement.numberOfLines = 0
        tvRequirement.lineBreakMode = .byWordWrapping
        tvRequirement.text = requirementMap[dari]
        tvRequirement.font = UIFont.boldSystemFont(ofSize: 13)
        tvRequirement.textColor = UIColor.black
        statusCard.addSubview(tvRequirement)
        let divider = UIView()
        divider.translatesAutoresizingMaskIntoConstraints = false
        divider.backgroundColor = UIColor.systemGray4
        statusCard.addSubview(divider)
        let gpsIcon = UIImageView(image: UIImage(systemName: "location.fill"))
        gpsIcon.translatesAutoresizingMaskIntoConstraints = false
        gpsIcon.tintColor = .systemOrange
        statusCard.addSubview(gpsIcon)
        tvGpsStatus.translatesAutoresizingMaskIntoConstraints = false
        tvGpsStatus.text = "Mencari koordinat lokasi..."
        tvGpsStatus.font = UIFont.systemFont(ofSize: 12)
        tvGpsStatus.textColor = UIColor.systemGray
        statusCard.addSubview(tvGpsStatus)
        let cameraCard = UIView()
        cameraCard.translatesAutoresizingMaskIntoConstraints = false
        cameraCard.backgroundColor = .black
        cameraCard.layer.cornerRadius = 24
        cameraCard.layer.borderWidth = 4
        cameraCard.layer.borderColor = UIColor.white.cgColor
        cameraCard.clipsToBounds = true
        contentView.addSubview(cameraCard)
        previewView.translatesAutoresizingMaskIntoConstraints = false
        cameraCard.addSubview(previewView)
        resultImage.translatesAutoresizingMaskIntoConstraints = false
        cameraCard.addSubview(resultImage)
        tvLiveTime.translatesAutoresizingMaskIntoConstraints = false
        cameraCard.addSubview(tvLiveTime)
        btnSwitch.translatesAutoresizingMaskIntoConstraints = false
        btnSwitch.setImage(UIImage(systemName: "arrow.triangle.2.circlepath.camera"), for: .normal)
        btnSwitch.tintColor = .white
        cameraCard.addSubview(btnSwitch)
        let thumbScroll = UIScrollView()
        thumbScroll.translatesAutoresizingMaskIntoConstraints = false
        thumbScroll.showsHorizontalScrollIndicator = false
        contentView.addSubview(thumbScroll)
        thumbStack.translatesAutoresizingMaskIntoConstraints = false
        thumbStack.axis = .horizontal
        thumbStack.spacing = 12
        thumbScroll.addSubview(thumbStack)
        inputCard.translatesAutoresizingMaskIntoConstraints = false
        inputCard.backgroundColor = .white
        inputCard.layer.cornerRadius = 16
        inputCard.layer.borderWidth = 1
        inputCard.layer.borderColor = UIColor.systemGray5.cgColor
        contentView.addSubview(inputCard)
        tvKeterangan.translatesAutoresizingMaskIntoConstraints = false
        tvKeterangan.text = keteranganMap[dari]
        tvKeterangan.font = UIFont.boldSystemFont(ofSize: 14)
        tvKeterangan.textColor = UIColor.black
        contentView.addSubview(tvKeterangan)
        etAlasan.translatesAutoresizingMaskIntoConstraints = false
        etAlasan.font = UIFont.systemFont(ofSize: 14)
        etAlasan.text = AlasanMap[dari]
        etAlasan.textColor = UIColor.systemGray3
        etAlasan.delegate = self
        etAlasan.backgroundColor = .clear
        etAlasan.isScrollEnabled = false
        etAlasan.textAlignment = .left
        etAlasan.textContainer.lineFragmentPadding = 0
        etAlasan.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        etAlasan.contentInset = .zero
        inputCard.addSubview(etAlasan)
        jenisCutiButton.translatesAutoresizingMaskIntoConstraints = false
        var config = UIButton.Configuration.plain()
        config.title = "Pilih Jenis Cuti"
        config.baseForegroundColor = .label
        config.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 12)
        config.background.backgroundColor = UIColor.systemGray6
        config.background.cornerRadius = 8
        jenisCutiButton.configuration = config
        jenisCutiButton.contentHorizontalAlignment = .leading
        jenisCutiButton.addTarget(self, action: #selector(showCutiOptions), for: .touchUpInside)
        inputCard.addSubview(jenisCutiButton)
        jenisCutiChevron.translatesAutoresizingMaskIntoConstraints = false
        jenisCutiChevron.tintColor = .secondaryLabel
        inputCard.addSubview(jenisCutiChevron)
        NSLayoutConstraint.activate([
            jenisCutiChevron.centerYAnchor.constraint(equalTo: jenisCutiButton.centerYAnchor),
            jenisCutiChevron.trailingAnchor.constraint(equalTo: jenisCutiButton.trailingAnchor, constant: -12),
            jenisCutiChevron.widthAnchor.constraint(equalToConstant: 14),
            jenisCutiChevron.heightAnchor.constraint(equalToConstant: 14)
        ])
        inputCard.bringSubviewToFront(jenisCutiChevron)
        btMulai.translatesAutoresizingMaskIntoConstraints = false
        btMulai.setTitle("Mulai", for: .normal)
        btMulai.backgroundColor = .systemBlue
        btMulai.tintColor = .white
        btMulai.layer.cornerRadius = 12
        btKirim.translatesAutoresizingMaskIntoConstraints = false
        btKirim.setTitle("Kirim Absen", for: .normal)
        btKirim.backgroundColor = .systemBlue
        btKirim.tintColor = .white
        btKirim.layer.cornerRadius = 12
        contentView.addSubview(btMulai)
        contentView.addSubview(btKirim)
        let tvDisclaimer = UILabel()
        tvDisclaimer.translatesAutoresizingMaskIntoConstraints = false
        tvDisclaimer.text = "Data lokasi dan foto digunakan untuk validasi kehadiran."
        tvDisclaimer.font = UIFont.systemFont(ofSize: 11)
        tvDisclaimer.textColor = .systemGray
        tvDisclaimer.textAlignment = .center
        view.addSubview(tvDisclaimer)
        let belowAnchor = inputCard.bottomAnchor
        NSLayoutConstraint.activate([
            headerDecor.topAnchor.constraint(equalTo: view.topAnchor),
            headerDecor.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerDecor.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerDecor.heightAnchor.constraint(equalToConstant: 180),
            btnBack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            btnBack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            scrollView.topAnchor.constraint(equalTo: btnBack.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: tvDisclaimer.topAnchor),
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            tvTitle.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            tvTitle.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            tvSubtitle.topAnchor.constraint(equalTo: tvTitle.bottomAnchor),
            tvSubtitle.leadingAnchor.constraint(equalTo: tvTitle.leadingAnchor),
            statusCard.topAnchor.constraint(equalTo: tvSubtitle.bottomAnchor, constant: 24),
            statusCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            statusCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            tvRequirement.topAnchor.constraint(equalTo: statusCard.topAnchor, constant: 16),
            tvRequirement.leadingAnchor.constraint(equalTo: statusCard.leadingAnchor, constant: 16),
            tvRequirement.trailingAnchor.constraint(lessThanOrEqualTo: statusCard.trailingAnchor, constant: -16),
            divider.topAnchor.constraint(equalTo: tvRequirement.bottomAnchor, constant: 12),
            divider.leadingAnchor.constraint(equalTo: statusCard.leadingAnchor, constant: 16),
            divider.trailingAnchor.constraint(equalTo: statusCard.trailingAnchor, constant: -16),
            divider.heightAnchor.constraint(equalToConstant: 1),
            gpsIcon.topAnchor.constraint(equalTo: divider.bottomAnchor, constant: 12),
            gpsIcon.leadingAnchor.constraint(equalTo: statusCard.leadingAnchor, constant: 16),
            gpsIcon.widthAnchor.constraint(equalToConstant: 16),
            gpsIcon.heightAnchor.constraint(equalToConstant: 16),
            tvGpsStatus.centerYAnchor.constraint(equalTo: gpsIcon.centerYAnchor),
            tvGpsStatus.leadingAnchor.constraint(equalTo: gpsIcon.trailingAnchor, constant: 8),
            tvGpsStatus.trailingAnchor.constraint(lessThanOrEqualTo: statusCard.trailingAnchor, constant: -16),
            tvGpsStatus.bottomAnchor.constraint(equalTo: statusCard.bottomAnchor, constant: -16),
            cameraCard.topAnchor.constraint(equalTo: statusCard.bottomAnchor, constant: 20),
            cameraCard.leadingAnchor.constraint(equalTo: statusCard.leadingAnchor),
            cameraCard.trailingAnchor.constraint(equalTo: statusCard.trailingAnchor),
            cameraCard.heightAnchor.constraint(equalTo: cameraCard.widthAnchor, multiplier: 1.25),
            previewView.topAnchor.constraint(equalTo: cameraCard.topAnchor),
            previewView.leadingAnchor.constraint(equalTo: cameraCard.leadingAnchor),
            previewView.trailingAnchor.constraint(equalTo: cameraCard.trailingAnchor),
            previewView.bottomAnchor.constraint(equalTo: cameraCard.bottomAnchor),
            thumbScroll.topAnchor.constraint(equalTo: cameraCard.bottomAnchor, constant: 20),
            thumbScroll.leadingAnchor.constraint(equalTo: cameraCard.leadingAnchor),
            thumbScroll.trailingAnchor.constraint(equalTo: cameraCard.trailingAnchor),
            thumbScroll.heightAnchor.constraint(equalToConstant: 90),
            thumbStack.topAnchor.constraint(equalTo: thumbScroll.topAnchor),
            thumbStack.bottomAnchor.constraint(equalTo: thumbScroll.bottomAnchor),
            thumbStack.leadingAnchor.constraint(equalTo: thumbScroll.leadingAnchor),
            tvKeterangan.topAnchor.constraint(equalTo: thumbScroll.bottomAnchor, constant: 20),
            tvKeterangan.leadingAnchor.constraint(equalTo: cameraCard.leadingAnchor),
            tvKeterangan.trailingAnchor.constraint(lessThanOrEqualTo: cameraCard.trailingAnchor, constant: -16),
            inputCard.topAnchor.constraint(equalTo: tvKeterangan.bottomAnchor, constant: 8),
            inputCard.leadingAnchor.constraint(equalTo: cameraCard.leadingAnchor),
            inputCard.trailingAnchor.constraint(equalTo: cameraCard.trailingAnchor),
            jenisCutiButton.topAnchor.constraint(equalTo: inputCard.topAnchor, constant: 16),
            jenisCutiButton.leadingAnchor.constraint(equalTo: inputCard.leadingAnchor, constant: 12),
            jenisCutiButton.trailingAnchor.constraint(equalTo: inputCard.trailingAnchor, constant: -12),
            jenisCutiButton.heightAnchor.constraint(equalToConstant: 44),
            etAlasan.topAnchor.constraint(equalTo: inputCard.topAnchor, constant: 12),
            etAlasan.leadingAnchor.constraint(equalTo: inputCard.leadingAnchor, constant: 12),
            etAlasan.trailingAnchor.constraint(equalTo: inputCard.trailingAnchor, constant: -12),
            etAlasan.bottomAnchor.constraint(equalTo: inputCard.bottomAnchor, constant: -12),
            btMulai.topAnchor.constraint(equalTo: belowAnchor, constant: 24),
            btMulai.leadingAnchor.constraint(equalTo: inputCard.leadingAnchor),
            btMulai.heightAnchor.constraint(equalToConstant: 56),
            btMulai.widthAnchor.constraint(equalTo: inputCard.widthAnchor, multiplier: 0.48),
            btKirim.topAnchor.constraint(equalTo: belowAnchor, constant: 24),
            btKirim.trailingAnchor.constraint(equalTo: inputCard.trailingAnchor),
            btKirim.heightAnchor.constraint(equalToConstant: 56),
            btKirim.widthAnchor.constraint(equalTo: inputCard.widthAnchor, multiplier: 0.48),
            btKirim.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -32),
            tvDisclaimer.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tvDisclaimer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tvDisclaimer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tvDisclaimer.heightAnchor.constraint(equalToConstant: 40),
            btnSwitch.trailingAnchor.constraint(equalTo: cameraCard.trailingAnchor, constant: -12),
            btnSwitch.widthAnchor.constraint(equalToConstant: 40),
            btnSwitch.heightAnchor.constraint(equalToConstant: 40)
        ])
        previewView.clipsToBounds = true
        previewView.backgroundColor = .black
    }

    private func startFlow() {
        absensiManager.authenticate { [weak self] in
            guard let self else { return }
            self.resultImage.isHidden = true
            self.previewView.isHidden = false
            self.absensiManager.prepare()
            self.absensiManager.startCamera()
            self.menu = "capture"
            self.btMulai.setTitle("Ambil Foto", for: .normal)
            self.btnSwitch.isHidden = false
        }
    }

    private func captureFlow() {
        absensiManager.capture { [weak self] uri, jumlah in
            guard let self else { return }
            let fileBaru = self.absensiManager.capturedFiles.last!
            self.addThumbnail(uri: uri, file: fileBaru)
            if jumlah >= 2 {
                self.btMulai.isEnabled = false
                self.btMulai.setTitle("Selesai", for: .normal)
                self.btMulai.alpha = 0.5
            }
        }
    }

    func showAlert(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func addThumbnail(uri: URL, file: URL) {
        let img = UIImageView()
        img.image = UIImage(contentsOfFile: uri.path)
        img.layer.cornerRadius = 8
        img.clipsToBounds = true
        img.contentMode = .scaleAspectFill
        img.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            img.widthAnchor.constraint(equalToConstant: 80),
            img.heightAnchor.constraint(equalToConstant: 80)
        ])
        img.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(openPreview(_:)))
        img.addGestureRecognizer(tap)
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(deleteThumbnail(_:)))
        img.addGestureRecognizer(longPress)
        img.tag = absensiManager.capturedFiles.count - 1
        thumbStack.addArrangedSubview(img)
    }

    @objc private func openPreview(_ gesture: UITapGestureRecognizer) {
        guard let img = gesture.view as? UIImageView else { return }
        let index = img.tag
        if index < absensiManager.capturedFiles.count {
            let file = absensiManager.capturedFiles[index]
            let vc = PreviewFotoActivity()
            vc.fotoUri = file.path
            vc.modalPresentationStyle = .fullScreen
            present(vc, animated: true)
        }
    }

    @objc private func deleteThumbnail(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        guard let img = gesture.view else { return }
        let index = img.tag
        if index < absensiManager.capturedFiles.count {
            absensiManager.capturedFiles.remove(at: index)
            thumbStack.removeArrangedSubview(img)
            img.removeFromSuperview()
            btMulai.isEnabled = true
            btMulai.alpha = 1.0
            btMulai.setTitle("Ambil Foto", for: .normal)
        }
    }

    @objc private func onKirim() {
        let files = absensiManager.capturedFiles
        if files.count < 2 { showAlert("Minimal 2 foto bukti"); return }

        // Khusus PULANG — setara logic Android AbsenPulang
        if dari == "PULANG" {
            let alasan = statuspulang.uppercased() == "TEPAT WAKTU"
                ? "TEPAT WAKTU"
                : etAlasan.text.trimmingCharacters(in: .whitespaces)
            if alasan.isEmpty {
                showAlert("Alasan wajib diisi"); return
            }
            var params: [String: String] = [
                "menu": dari,
                "ketam": alasan,
                "statuspulang": statuspulang,
                "latitude": "\(absensiManager.lat ?? 0)",
                "longitude": "\(absensiManager.lon ?? 0)",
                "__ts": "\(Int(Date().timeIntervalSince1970))",
                "__nonce": UUID().uuidString
            ]
            AuthManager(endpoint: "api/absen").uploadFoto(
                files: files, params: params,
                onSuccess: { json in
                    let status = json["status"] as? String ?? ""
                    if status == "ok" {
                        let alert = UIAlertController(title: nil, message: "Absensi pulang berhasil terkirim", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in self.dismiss(animated: true) })
                        self.present(alert, animated: true)
                    }
                },
                onError: { message in self.showAlert(message) },
                onLogout: { message in self.showAlert(message) },
                onLoading: { loading in loading ? self.showLoading() : self.hideLoading() }
            )
            return
        }

        var alasan = etAlasan.text.trimmingCharacters(in: .whitespaces)
        if dari == "CUTI" {
            let selectedCuti = cutiOptions[selectedCutiIndex]
            let currentTitle: String = {
                if let cfg = jenisCutiButton.configuration?.title, !cfg.isEmpty { return cfg }
                return jenisCutiButton.title(for: .normal) ?? ""
            }()
            let isDefault = currentTitle.isEmpty || currentTitle == "Pilih Jenis Cuti"
            if isDefault { showAlert("Silahkan pilih jenis cuti"); return }
            alasan = selectedCuti
        }
        if alasan.isEmpty { showAlert(dari == "CUTI" ? "Silahkan pilih jenis cuti" : "Keterangan wajib diisi"); return }
        var params: [String:String]
        if dari == "CUTI" {
            let selectedCuti = cutiOptions[selectedCutiIndex]
            params = ["menu": dari, "ketam": alasan, "jenis_cuti": selectedCuti,
                      "latitude": "\(absensiManager.lat ?? 0)", "longitude": "\(absensiManager.lon ?? 0)"]
        } else {
            params = ["menu": dari, "ketam": alasan,
                      "latitude": "\(absensiManager.lat ?? 0)", "longitude": "\(absensiManager.lon ?? 0)"]
        }
        params["__ts"] = "\(Int(Date().timeIntervalSince1970))"
        params["__nonce"] = UUID().uuidString
        AuthManager(endpoint: "api/absen").uploadFoto(
            files: files, params: params,
            onSuccess: { json in
                let status = json["status"] as? String ?? ""
                if status == "ok" {
                    let alert = UIAlertController(title: nil, message: "Absensi berhasil terkirim", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in self.dismiss(animated: true) })
                    self.present(alert, animated: true)
                }
            },
            onError: { message in self.showAlert(message) },
            onLogout: { message in self.showAlert(message) },
            onLoading: { loading in loading ? self.showLoading() : self.hideLoading() }
        )
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        absensiManager.stop()
        timer?.invalidate()
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView === etAlasan && textView.textColor == UIColor.systemGray3 {
            textView.text = nil; textView.textColor = UIColor.label
            textView.setContentOffset(.zero, animated: false)
        }
    }
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView === etAlasan && (textView.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            textView.text = AlasanMap[dari]; textView.textColor = UIColor.systemGray3
            textView.setContentOffset(.zero, animated: false)
        }
    }
    func textViewDidChange(_ textView: UITextView) {
        if textView === etAlasan { textView.setContentOffset(.zero, animated: false) }
    }

    @objc private func showCutiOptions() {
        let alert = UIAlertController(title: "Pilih Jenis Cuti", message: nil, preferredStyle: .actionSheet)
        for (index, option) in cutiOptions.enumerated() {
            alert.addAction(UIAlertAction(title: option, style: .default, handler: { [weak self] _ in
                self?.selectedCutiIndex = index
                if var cfg = self?.jenisCutiButton.configuration { cfg.title = option; self?.jenisCutiButton.configuration = cfg }
                else { self?.jenisCutiButton.setTitle(option, for: .normal) }
            }))
        }
        alert.addAction(UIAlertAction(title: "Batal", style: .cancel))
        if let pop = alert.popoverPresentationController { pop.sourceView = jenisCutiButton; pop.sourceRect = jenisCutiButton.bounds }
        present(alert, animated: true)
    }
}
