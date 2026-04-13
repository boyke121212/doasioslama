import UIKit

import DGCharts
import Network

final class Home: Boyke, UIScrollViewDelegate {
    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "InternetMonitor")
    // MARK: - Scroll Structure
    let lineChartView = LineChartView()
    let scrollView = UIScrollView()
    let contentView = UIView()
    
    // MARK: - HERO SECTION
    
    let heroContainer = UIView()

    let logoImageView = UIImageView()
    let gradientView = UIView()
    let titleStack = UIStackView()
    let tvJudul = UILabel()
    let tvIsi = UILabel()
    
    // MARK: - FLOATING MENU CARD
    
    let floatingMenuCard = UIView()
    let tbMenuStack = UIStackView()
    
    let btAbsen = MenuItemView(title: "Absen", iconName: "ic_fingerprint", active: true)
    let btStatus = MenuItemView(title: "Status", iconName: "ic_status")
    let btInfo = MenuItemView(title: "Berita", iconName: "ic_news")
    let btLog = MenuItemView(title: "Log", iconName: "ic_log")
    let btProfile = MenuItemView(title: "Profile", iconName: "ic_person")
    let btDoas = MenuItemView(title: "DOAS", iconName: "ic_about")
    
    // MARK: - PRESENSI CARD
    
    let presensiCard = UIView()
    let btHadir = UIButton()
    
    // MARK: - GRID MENU
    
    let gridContainer = UIStackView()
    let btDik = UIButton()
    let btCuti = UIButton()
    let btSakit = UIButton()
    let btBko = UIButton()
    
    // MARK: - DOCTOR CARD
    
    let doctorCard = UIView()
    
    // MARK: - DASHBOARD CARD
    
    let dashboardCard = UIView()
    let tvTahunAktif = UILabel()
    let tvBulanAwal = UILabel()
    let chartPlaceholder = UIView()
    
    // 🔥 GANTI COLLECTIONVIEW → STACKVIEW
    let summaryContainer = UIStackView()
    let userContainer = UIStackView()
    
    // MARK: - STATE
    
    var isRequestRunning = false
    let authManager = AuthManager(endpoint: "api/auth-check")
    var beritaItems: [BeritaItem] = []
    var currentIndex = 0
    var rawDashboardJSON: [String: Any]?

    // Custom legend container (vertical stack of rows)
    private let customLegend = UIStackView()

    // Collapsing header
    private let headerMaxHeight: CGFloat = 280
    private let headerMinHeight: CGFloat = 140
    private var headerHeightConstraint: NSLayoutConstraint!
    
    let pageController = UIPageViewController(
        transitionStyle: .scroll,
        navigationOrientation: .horizontal
    )

    // =========================================================
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLayout()
        pageController.dataSource = self
        pageController.delegate = self
        setupChartStyle()   // ⬅️ TAMBAHKAN INI
        setupAbsenMenu()
        btInfo.addTarget(self, action: #selector(ontapInfo), for: .touchUpInside)
        btDoas.addTarget(self, action: #selector(ontapDoas), for: .touchUpInside)
        btLog.addTarget(self, action: #selector(ontapLog), for: .touchUpInside)
        self.monitorInternet()
        btProfile.addTarget(self, action: #selector(bukaprofile), for: .touchUpInside)
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
      openPage(Doas())
    }
    @objc private func ontapLog() {
     openPage(History())
    }
    
    @objc private func onTapDokter() {
        openPage(DoctorListActivity())
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        refreshData()

    }
    
    
    // =========================================================
    // MARK: - LAYOUT SETUP
    // =========================================================
    
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
        setupPresensiCard()
        setupGridMenu()
        setupDoctorCard()      // ⬅️ TAMBAHKAN INI
        setupDashboardCard()
    }
    
    // =========================================================
    // HERO
    // =========================================================
    
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
    
    private func setupAbsenMenu() {

        let mapAbsen: [UIControl: String] = [
            btStatus: "status",
            btDik: "dik",
            btSakit: "sakit",
            btBko: "bko",
            btCuti: "cuti"
        ]

        for (button, value) in mapAbsen {

            button.accessibilityIdentifier = value

            button.addTarget(
                self,
                action: #selector(onTapMenuAbsen(_:)),
                for: .touchUpInside
            )
        }
        btHadir.addTarget(self, action: #selector(onTapHadir), for: .touchUpInside)
    }
    @objc private func onTapHadir() {
        go()
    }
    // =========================================================
    // FLOATING MENU
    // =========================================================
    
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
            floatingMenuCard.heightAnchor.constraint(equalToConstant: 64)
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
    }
    
    // =========================================================
    // PRESENSI
    // =========================================================
    
    private func setupPresensiCard() {
        
        presensiCard.translatesAutoresizingMaskIntoConstraints = false
        presensiCard.backgroundColor = .white
        presensiCard.layer.cornerRadius = 20
        presensiCard.layer.shadowColor = UIColor.black.cgColor
        presensiCard.layer.shadowOpacity = 0.1
        presensiCard.layer.shadowRadius = 6
        presensiCard.layer.shadowOffset = CGSize(width: 0, height: 4)
        
        contentView.addSubview(presensiCard)
        
        NSLayoutConstraint.activate([
            presensiCard.topAnchor.constraint(equalTo: floatingMenuCard.bottomAnchor, constant: 16),
            presensiCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            presensiCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])
        
        let innerStack = UIStackView()
        innerStack.axis = .vertical
        innerStack.spacing = 14
        innerStack.translatesAutoresizingMaskIntoConstraints = false
        
        presensiCard.addSubview(innerStack)
        
        NSLayoutConstraint.activate([
            innerStack.topAnchor.constraint(equalTo: presensiCard.topAnchor, constant: 22),
            innerStack.bottomAnchor.constraint(equalTo: presensiCard.bottomAnchor, constant: -22),
            innerStack.leadingAnchor.constraint(equalTo: presensiCard.leadingAnchor, constant: 22),
            innerStack.trailingAnchor.constraint(equalTo: presensiCard.trailingAnchor, constant: -22)
        ])
        
        let titleLabel = UILabel()
        titleLabel.text = "Presensi Hari Ini"
        titleLabel.font = UIFont.systemFont(ofSize: 13)
        titleLabel.textColor = UIColor.systemGray
        
        btHadir.setTitle("ABSEN DINAS LUAR", for: .normal)
        btHadir.setTitleColor(.white, for: .normal)
        btHadir.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        btHadir.backgroundColor = UIColor.systemBlue
        btHadir.layer.cornerRadius = 12
        btHadir.heightAnchor.constraint(equalToConstant: 60).isActive = true
        
        innerStack.addArrangedSubview(titleLabel)
        innerStack.addArrangedSubview(btHadir)
    }
    
    // =========================================================
    // GRID MENU
    // =========================================================
    
    private func setupGridMenu() {
        
        gridContainer.axis = .vertical
        gridContainer.spacing = 12
        gridContainer.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(gridContainer)
        
        NSLayoutConstraint.activate([
            gridContainer.topAnchor.constraint(equalTo: presensiCard.bottomAnchor, constant: 16),
            gridContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            gridContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])
        
        let row1 = UIStackView()
        row1.axis = .horizontal
        row1.spacing = 12
        row1.distribution = .fillEqually
        
        let row2 = UIStackView()
        row2.axis = .horizontal
        row2.spacing = 12
        row2.distribution = .fillEqually
        
        configureGridButton(btDik, title: "DIK")
        configureGridButton(btCuti, title: "Cuti")
        configureGridButton(btSakit, title: "Sakit")
        configureGridButton(btBko, title: "BKO")
        
        row1.addArrangedSubview(btDik)
        row1.addArrangedSubview(btCuti)
        
        row2.addArrangedSubview(btSakit)
        row2.addArrangedSubview(btBko)
        
        gridContainer.addArrangedSubview(row1)
        gridContainer.addArrangedSubview(row2)
    }
    
    // =========================================================
    // DOCTOR CARD  ⬅️ BARU
    // =========================================================
    
    private func setupDoctorCard() {
        
        doctorCard.translatesAutoresizingMaskIntoConstraints = false
        doctorCard.backgroundColor = .white
        doctorCard.layer.cornerRadius = 16
        doctorCard.layer.shadowColor = UIColor.black.cgColor
        doctorCard.layer.shadowOpacity = 0.08
        doctorCard.layer.shadowRadius = 6
        doctorCard.layer.shadowOffset = CGSize(width: 0, height: 3)
        
        contentView.addSubview(doctorCard)
        
        NSLayoutConstraint.activate([
            doctorCard.topAnchor.constraint(equalTo: gridContainer.bottomAnchor, constant: 16),
            doctorCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            doctorCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            doctorCard.heightAnchor.constraint(equalToConstant: 72)
        ])
        
        // ── Left icon circle ──
        let iconCircle = UIView()
        iconCircle.translatesAutoresizingMaskIntoConstraints = false
        iconCircle.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.12)
        iconCircle.layer.cornerRadius = 22
        
        let personIcon = UIImageView()
        personIcon.translatesAutoresizingMaskIntoConstraints = false
        personIcon.image = UIImage(systemName: "person.fill")
        personIcon.tintColor = .systemBlue
        personIcon.contentMode = .scaleAspectFit
        
        iconCircle.addSubview(personIcon)
        doctorCard.addSubview(iconCircle)
        
        NSLayoutConstraint.activate([
            iconCircle.leadingAnchor.constraint(equalTo: doctorCard.leadingAnchor, constant: 16),
            iconCircle.centerYAnchor.constraint(equalTo: doctorCard.centerYAnchor),
            iconCircle.widthAnchor.constraint(equalToConstant: 44),
            iconCircle.heightAnchor.constraint(equalToConstant: 44),
            
            personIcon.centerXAnchor.constraint(equalTo: iconCircle.centerXAnchor),
            personIcon.centerYAnchor.constraint(equalTo: iconCircle.centerYAnchor),
            personIcon.widthAnchor.constraint(equalToConstant: 22),
            personIcon.heightAnchor.constraint(equalToConstant: 22)
        ])
        
        // ── Text stack ──
        let textStack = UIStackView()
        textStack.axis = .vertical
        textStack.spacing = 3
        textStack.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLbl = UILabel()
        titleLbl.text = "Konsultasi Kesehatan"
        titleLbl.font = UIFont.boldSystemFont(ofSize: 15)
        titleLbl.textColor = .label
        
        let subtitleLbl = UILabel()
        subtitleLbl.text = "Chat langsung dengan dokter"
        subtitleLbl.font = UIFont.systemFont(ofSize: 13)
        subtitleLbl.textColor = .secondaryLabel
        
        textStack.addArrangedSubview(titleLbl)
        textStack.addArrangedSubview(subtitleLbl)
        doctorCard.addSubview(textStack)
        
        NSLayoutConstraint.activate([
            textStack.leadingAnchor.constraint(equalTo: iconCircle.trailingAnchor, constant: 14),
            textStack.centerYAnchor.constraint(equalTo: doctorCard.centerYAnchor),
            textStack.trailingAnchor.constraint(lessThanOrEqualTo: doctorCard.trailingAnchor, constant: -56)
        ])
        
        // ── Right chevron/doc icon ──
        let rightIcon = UIImageView()
        rightIcon.translatesAutoresizingMaskIntoConstraints = false
        rightIcon.image = UIImage(systemName: "doc.text")
        rightIcon.tintColor = UIColor.systemGray3
        rightIcon.contentMode = .scaleAspectFit
        
        doctorCard.addSubview(rightIcon)
        
        NSLayoutConstraint.activate([
            rightIcon.trailingAnchor.constraint(equalTo: doctorCard.trailingAnchor, constant: -16),
            rightIcon.centerYAnchor.constraint(equalTo: doctorCard.centerYAnchor),
            rightIcon.widthAnchor.constraint(equalToConstant: 22),
            rightIcon.heightAnchor.constraint(equalToConstant: 22)
        ])
        
        // ── Tap gesture ──
        let tap = UITapGestureRecognizer(target: self, action: #selector(onTapDokter))
        doctorCard.addGestureRecognizer(tap)
        doctorCard.isUserInteractionEnabled = true
        
        // ── Highlight effect on press ──
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(doctorCardHighlight(_:)))
        longPress.minimumPressDuration = 0.05
        doctorCard.addGestureRecognizer(longPress)
        tap.require(toFail: longPress)
    }
    
    @objc private func doctorCardHighlight(_ gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            UIView.animate(withDuration: 0.1) {
                self.doctorCard.transform = CGAffineTransform(scaleX: 0.97, y: 0.97)
                self.doctorCard.alpha = 0.85
            }
        case .ended, .cancelled, .failed:
            UIView.animate(withDuration: 0.15) {
                self.doctorCard.transform = .identity
                self.doctorCard.alpha = 1.0
            }
            openPage(DoctorListActivity())
        default:
            break
        }
    }
    
    // =========================================================
    // DASHBOARD (STACKVIEW VERSION - 1:1 ANDROID)
    // =========================================================
    
    private func setupDashboardCard() {
        
        dashboardCard.translatesAutoresizingMaskIntoConstraints = false
        dashboardCard.backgroundColor = .white
        dashboardCard.layer.cornerRadius = 16
        dashboardCard.layer.shadowColor = UIColor.black.cgColor
        dashboardCard.layer.shadowOpacity = 0.1
        dashboardCard.layer.shadowRadius = 6
        dashboardCard.layer.shadowOffset = CGSize(width: 0, height: 4)
        
        contentView.addSubview(dashboardCard)
        
        NSLayoutConstraint.activate([
            // ⬅️ DIUBAH: top sekarang mengacu ke doctorCard, bukan gridContainer
            dashboardCard.topAnchor.constraint(equalTo: doctorCard.bottomAnchor, constant: 16),
            dashboardCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            dashboardCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            dashboardCard.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24)
        ])
        
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        dashboardCard.addSubview(stack)
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: dashboardCard.topAnchor, constant: 16),
            stack.bottomAnchor.constraint(equalTo: dashboardCard.bottomAnchor, constant: -16),
            stack.leadingAnchor.constraint(equalTo: dashboardCard.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: dashboardCard.trailingAnchor, constant: -16)
        ])
        
        let dashboardTitle = UILabel()
    
        dashboardTitle.text = "Dashboard Anggaran"
        dashboardTitle.font = UIFont.boldSystemFont(ofSize: 16)
        
        tvTahunAktif.font = UIFont.systemFont(ofSize: 14)
        tvBulanAwal.font = UIFont.systemFont(ofSize: 14)
        
        let summaryTitle = UILabel()
        summaryTitle.text = "Summary Subdit"
        summaryTitle.font = UIFont.boldSystemFont(ofSize: 14)
        
        summaryContainer.axis = .vertical
        summaryContainer.spacing = 12
        
        let chartTitle = UILabel()
        chartTitle.text = "Grafik Subdit"
        chartTitle.font = UIFont.boldSystemFont(ofSize: 14)
        
        // Insert chartTitle BEFORE lineChartView
        stack.addArrangedSubview(chartTitle)
        
        lineChartView.translatesAutoresizingMaskIntoConstraints = false
        lineChartView.heightAnchor.constraint(equalToConstant: 220).isActive = true

        stack.addArrangedSubview(lineChartView)
        
        // Custom legend below the chart
        customLegend.axis = .vertical
        customLegend.spacing = 6
        customLegend.alignment = .fill
        customLegend.distribution = .fill
        stack.addArrangedSubview(customLegend)

        // Add top spacing before dashboard title without extra view
        stack.setCustomSpacing(30, after: customLegend)
        
        stack.addArrangedSubview(dashboardTitle)
        stack.addArrangedSubview(tvTahunAktif)
        stack.addArrangedSubview(tvBulanAwal)
        stack.addArrangedSubview(summaryTitle)
        stack.addArrangedSubview(summaryContainer)
        
        // Add label "5 user terakhir" before userContainer
        let lastUsersTitle = UILabel()
        lastUsersTitle.text = "5 user terakhir"
        lastUsersTitle.font = UIFont.boldSystemFont(ofSize: 14)
        stack.addArrangedSubview(lastUsersTitle)
        // Card wrapper untuk userContainer
        let userCard = UIView()
        userCard.backgroundColor = UIColor.systemGray6
        userCard.layer.cornerRadius = 12
        userCard.layer.borderWidth = 1
        userCard.layer.borderColor = UIColor.separator.cgColor
        userCard.translatesAutoresizingMaskIntoConstraints = false

        userContainer.axis = .vertical
        userContainer.spacing = 8
        userContainer.alignment = .fill
        userContainer.distribution = .fill
        userContainer.translatesAutoresizingMaskIntoConstraints = false

        userCard.addSubview(userContainer)

        NSLayoutConstraint.activate([
            userContainer.topAnchor.constraint(equalTo: userCard.topAnchor, constant: 12),
            userContainer.bottomAnchor.constraint(equalTo: userCard.bottomAnchor, constant: -12),
            userContainer.leadingAnchor.constraint(equalTo: userCard.leadingAnchor, constant: 12),
            userContainer.trailingAnchor.constraint(equalTo: userCard.trailingAnchor, constant: -12)
        ])

        stack.addArrangedSubview(userCard)
    }
    
    // MARK: - Collapsing Header
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let y = scrollView.contentOffset.y
        // Calculate new height clamped between min and max
        let newHeight = max(headerMinHeight, headerMaxHeight - y)
        headerHeightConstraint.constant = newHeight

        // Progress 0..1 (0 = expanded, 1 = collapsed)
        let progress = min(max((headerMaxHeight - newHeight) / (headerMaxHeight - headerMinHeight), 0), 1)

        // Subtle fade for title and subtitle
        tvJudul.alpha = 1 - 0.25 * progress
        tvIsi.alpha = 1 - 0.6 * progress

        // Layout immediately for smoothness
        view.layoutIfNeeded()
    }
    
    // =========================================================
    // DATA
    // =========================================================

    func refreshData() {
        if isRequestRunning { return }
        isRequestRunning = true
        dos()
    }

    func renderDashboard(_ data: DashboardData?) {

        guard let data = data else { return }

        tvTahunAktif.text = "Tahun Aktif: \(data.tahunAktif)"
        tvBulanAwal.text = "Bulan Awal: \(data.bulanAwal)"

        // CLEAR OLD
        for view in summaryContainer.arrangedSubviews {
            summaryContainer.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        for view in userContainer.arrangedSubviews {
            userContainer.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        // SUMMARY SUBDIT (1:1 Android LinearLayout)
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "."

        for (key, value) in data.summarySubdit.sorted(by: { $0.key < $1.key }) {

            let row = SummaryRowView()

            let diajukan = formatter.string(from: NSNumber(value: Double(value.diajukan) ?? 0)) ?? "0"
            let terserap = formatter.string(from: NSNumber(value: Double(value.terserap) ?? 0)) ?? "0"

            row.configure(
                title: key,
                diajukan: diajukan,
                terserap: terserap,
                persen: value.persen
            )

            summaryContainer.addArrangedSubview(row)
        }

        // USER TERAKHIR
        for user in data.userTerakhir {
            let row = UserRowView()
            row.configure(user: user)
            userContainer.addArrangedSubview(row)
        }
        renderChartFromRawJSON()
    }

    func showAlert(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func setupChartStyle() {

        lineChartView.chartDescription.enabled = false
        lineChartView.backgroundColor = .white

        lineChartView.setScaleEnabled(false)
        lineChartView.pinchZoomEnabled = false

        // ===== LEGEND =====
        let legend = lineChartView.legend
        legend.enabled = false

        lineChartView.extraBottomOffset = 12

        // ===== X AXIS =====
        let xAxis = lineChartView.xAxis
        xAxis.labelPosition = .bottom
        xAxis.drawGridLinesEnabled = true
        xAxis.granularity = 1
        xAxis.labelFont = .systemFont(ofSize: 10)

        // ===== LEFT AXIS =====
        let leftAxis = lineChartView.leftAxis
        leftAxis.axisMinimum = 0
        leftAxis.drawGridLinesEnabled = true
        leftAxis.labelFont = .systemFont(ofSize: 10)

        // ===== RIGHT AXIS =====
        let rightAxis = lineChartView.rightAxis
        rightAxis.enabled = false

        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "."

        leftAxis.valueFormatter = DefaultAxisValueFormatter(formatter: formatter)
    }
    
    private func colorFromHex(_ hex: String) -> UIColor? {
        var cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if cleaned.hasPrefix("#") { cleaned.removeFirst() }
        var alpha: CGFloat = 1.0
        var rgb: UInt64 = 0
        guard Scanner(string: cleaned).scanHexInt64(&rgb) else { return nil }
        switch cleaned.count {
        case 6:
            return UIColor(
                red: CGFloat((rgb & 0xFF0000) >> 16) / 255.0,
                green: CGFloat((rgb & 0x00FF00) >> 8) / 255.0,
                blue: CGFloat(rgb & 0x0000FF) / 255.0,
                alpha: alpha
            )
        case 8:
            alpha = CGFloat((rgb & 0xFF000000) >> 24) / 255.0
            return UIColor(
                red: CGFloat((rgb & 0x00FF0000) >> 16) / 255.0,
                green: CGFloat((rgb & 0x0000FF00) >> 8) / 255.0,
                blue: CGFloat(rgb & 0x000000FF) / 255.0,
                alpha: alpha
            )
        default:
            return nil
        }
    }
    
    private func configureGridButton(_ button: UIButton, title: String) {

        button.setTitle(title, for: .normal)
        button.setTitleColor(.systemBlue, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)

        button.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.08)
        button.layer.cornerRadius = 14
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.systemBlue.cgColor

        button.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            button.heightAnchor.constraint(equalToConstant: 56)
        ])
    }
    
  
    
    private func renderChartFromRawJSON() {
        guard let json = rawDashboardJSON,
              let dashboard = json["dashboard"] as? [String: Any] else {
            lineChartView.clear()
            return
        }
        
        // Extract keys from dashboard
        let grafikSubdit = dashboard["grafikSubdit"] as? [String: [String: Any]] ?? [:]
        let warnaSubdit = dashboard["warnaSubdit"] as? [String: String] ?? [:]
        let subditList = dashboard["subditList"] as? [String] ?? []
        let bulanUrut = dashboard["bulanUrut"] as? [String: String] ?? [:]
        let bulanAwalRaw = dashboard["bulanAwal"]
        let bulanAwal: Int
        if let ba = bulanAwalRaw as? Int {
            bulanAwal = ba
        } else if let baStr = bulanAwalRaw as? String, let baInt = Int(baStr) {
            bulanAwal = baInt
        } else {
            bulanAwal = 1
        }

        // Build monthKeys and labels
        var monthKeys: [String] = []
        var labels: [String] = []
        if !bulanUrut.isEmpty {
            let sortedKeys = bulanUrut.keys.compactMap { Int($0) }.sorted()
            for keyInt in sortedKeys {
                let keyStr = String(keyInt)
                monthKeys.append(keyStr)
                if let label = bulanUrut[keyStr] {
                    labels.append(label)
                } else {
                    labels.append(keyStr)
                }
            }
        } else {
            // fallback
            let monthNames = ["Jan","Feb","Mar","Apr","Mei","Jun","Jul","Agu","Sep","Okt","Nov","Des"]
            for i in 0..<12 {
                let monthNumber = ((bulanAwal - 1 + i) % 12) + 1
                monthKeys.append(String(monthNumber))
                labels.append(monthNames[(monthNumber - 1) % 12])
            }
        }

        // Determine orderedSubdits
        let orderedSubdits: [String]
        if !subditList.isEmpty {
            orderedSubdits = subditList
        } else {
            orderedSubdits = grafikSubdit.keys.sorted()
        }

        // Default color palette
        let defaultColors: [UIColor] = [.blue, .red, .green, .magenta, .cyan, UIColor(red: 1, green: 0.596, blue: 0, alpha: 1)]

        var dataSets: [LineChartDataSet] = []

        for (i, subdit) in orderedSubdits.enumerated() {
            var entries: [ChartDataEntry] = []

            for (index, monthKey) in monthKeys.enumerated() {
                let rawValue = grafikSubdit[subdit]?[monthKey]

                var yValue: Double = 0
                if let val = rawValue as? Double {
                    yValue = val
                } else if let val = rawValue as? NSNumber {
                    yValue = val.doubleValue
                } else if let valStr = rawValue as? String {
                    yValue = Double(valStr) ?? 0
                }

                entries.append(ChartDataEntry(x: Double(index), y: yValue))
            }

            let dataSet = LineChartDataSet(entries: entries, label: subdit)

            // Set colors
            if let hexColor = warnaSubdit[subdit], let color = colorFromHex(hexColor) {
                dataSet.colors = [color]
                dataSet.circleColors = [color]
            } else {
                let color = defaultColors[i % defaultColors.count]
                dataSet.colors = [color]
                dataSet.circleColors = [color]
            }

            dataSet.lineWidth = 2.5
            dataSet.circleRadius = 3.5
            dataSet.drawValuesEnabled = false
            dataSet.mode = .linear

            dataSets.append(dataSet)
        }

        let lineData = LineChartData(dataSets: dataSets)
        lineChartView.data = lineData

        // Configure axes
        let leftAxis = lineChartView.leftAxis
        leftAxis.axisMinimum = 0
        leftAxis.axisMaximum = 100
        leftAxis.granularity = 20
        leftAxis.labelCount = 6
        leftAxis.forceLabelsEnabled = false

        let percentFormatter = NumberFormatter()
        percentFormatter.numberStyle = .percent
        percentFormatter.maximumFractionDigits = 1
        percentFormatter.multiplier = 1
        leftAxis.valueFormatter = DefaultAxisValueFormatter(formatter: percentFormatter)

        let rightAxis = lineChartView.rightAxis
        rightAxis.enabled = false

        // Configure xAxis
        let xAxis = lineChartView.xAxis
        xAxis.labelPosition = .bottom
        xAxis.granularity = 1
        xAxis.axisMinimum = -0.5
        xAxis.axisMaximum = Double(labels.count) - 0.5
        xAxis.labelCount = labels.count
        xAxis.drawGridLinesEnabled = true
        xAxis.valueFormatter = IndexAxisValueFormatter(values: labels)

        // Configure legend
        let legend = lineChartView.legend
        legend.enabled = true
        legend.wordWrapEnabled = true
        legend.verticalAlignment = .bottom
        legend.horizontalAlignment = .center
        legend.orientation = .horizontal
        legend.drawInside = false
        legend.yOffset = 5

        // Misc
        lineChartView.extraBottomOffset = 10
        lineChartView.setScaleEnabled(true)
        lineChartView.pinchZoomEnabled = true

        lineChartView.animate(xAxisDuration: 1.0)
        lineChartView.notifyDataSetChanged()
    }
    
    
    
    @objc private func onTapMenuAbsen(_ sender: UIControl) {

        guard let dari = sender.accessibilityIdentifier else { return }

        cekabsen(dari: dari)
    }

    func setBerita(_ items: [BeritaItem]) {

        beritaItems = items

        guard let first = items.first else { return }

        let firstVC = BannerPageVC(item: first)

        pageController.setViewControllers(
            [firstVC],
            direction: .forward,
            animated: false
        )

        tvJudul.text = first.judul
        tvIsi.text = first.isi.hendry_htmlToPlain()

        startAutoSlide()
    }
    
    
    private var slideTimer: Timer?

    private func startAutoSlide() {

        slideTimer?.invalidate()

        slideTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in
            guard self.beritaItems.count > 1,
                  let currentVC = self.pageController.viewControllers?.first as? BannerPageVC,
                  let index = self.beritaItems.firstIndex(where: { $0.id == currentVC.item.id })
            else { return }

            let nextIndex = (index + 1) % self.beritaItems.count
            let nextVC = BannerPageVC(item: self.beritaItems[nextIndex])

            self.pageController.setViewControllers(
                [nextVC],
                direction: .forward,
                animated: true
            )

            self.tvJudul.text = nextVC.item.judul
            self.tvIsi.text = nextVC.item.isi.hendry_htmlToPlain()
        }
    }
    func monitorInternet() {

        monitor.pathUpdateHandler = { path in

            if path.status == .satisfied {

                DispatchQueue.main.async {

                    self.refreshData()
                }
            }
        }

        monitor.start(queue: monitorQueue)
    }
 
    override func viewDidDisappear(_ animated: Bool) {
        monitor.cancel()
    }
}

extension Home: UIPageViewControllerDataSource, UIPageViewControllerDelegate {

    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerBefore viewController: UIViewController
    ) -> UIViewController? {

        guard let vc = viewController as? BannerPageVC,
              let index = beritaItems.firstIndex(where: { $0.id == vc.item.id }),
              index > 0 else { return nil }

        return BannerPageVC(item: beritaItems[index - 1])
    }

    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerAfter viewController: UIViewController
    ) -> UIViewController? {

        guard let vc = viewController as? BannerPageVC,
              let index = beritaItems.firstIndex(where: { $0.id == vc.item.id }),
              index < beritaItems.count - 1 else { return nil }

        return BannerPageVC(item: beritaItems[index + 1])
    }

    func pageViewController(
        _ pageViewController: UIPageViewController,
        didFinishAnimating finished: Bool,
        previousViewControllers: [UIViewController],
        transitionCompleted completed: Bool
    ) {
        if completed,
           let current = pageController.viewControllers?.first as? BannerPageVC {

            tvJudul.text = current.item.judul
            tvIsi.text = current.item.isi.hendry_htmlToPlain()
        }
    }
}

final class SummaryRowView: UIView {

    private let titleLabel = UILabel()
    private let diajukanLabel = UILabel()
    private let terserapLabel = UILabel()
    private let persenLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {

        let mainStack = UIStackView()
        mainStack.axis = .vertical
        mainStack.spacing = 6
        mainStack.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.font = .boldSystemFont(ofSize: 14)

        let rowStack = UIStackView()
        rowStack.axis = .horizontal
        rowStack.distribution = .equalSpacing

        diajukanLabel.font = .systemFont(ofSize: 13)
        terserapLabel.font = .systemFont(ofSize: 13)
        persenLabel.font = .boldSystemFont(ofSize: 13)

        rowStack.addArrangedSubview(diajukanLabel)
        rowStack.addArrangedSubview(terserapLabel)
        rowStack.addArrangedSubview(persenLabel)

        mainStack.addArrangedSubview(titleLabel)
        mainStack.addArrangedSubview(rowStack)

        addSubview(mainStack)

        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: topAnchor),
            mainStack.bottomAnchor.constraint(equalTo: bottomAnchor),
            mainStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            mainStack.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }

    func configure(title: String, diajukan: String, terserap: String, persen: String) {

        titleLabel.text = title
        diajukanLabel.text = "Diajukan: \(diajukan)"
        terserapLabel.text = "Terserap: \(terserap)"
        persenLabel.text = "\(persen)%"

        if Double(persen) ?? 0 > 0 {
            persenLabel.textColor = .systemGreen
        } else {
            persenLabel.textColor = .systemRed
        }
    }
}
final class UserRowView: UIView {

    private let nameLabel = UILabel()
    private let detailLabel = UILabel()
    private let dateLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false

        nameLabel.font = .boldSystemFont(ofSize: 14)
        detailLabel.font = .systemFont(ofSize: 13)
        detailLabel.textColor = .darkGray
        dateLabel.font = .systemFont(ofSize: 12)
        dateLabel.textColor = .gray

        stack.addArrangedSubview(nameLabel)
        stack.addArrangedSubview(detailLabel)
        stack.addArrangedSubview(dateLabel)

        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }

    func configure(user: UserTerakhir) {
        nameLabel.text = user.name
        detailLabel.text = "\(user.pangkat) | \(user.jabatan) | \(user.subdit)"
        dateLabel.text = user.createdDtm
    }
}


struct DashboardData {

    let tahunAktif: String
    let bulanAwal: String

    let summarySubdit: [String: SummarySubdit]
    let userTerakhir: [UserTerakhir]

    static func from(json: [String: Any]) -> DashboardData {

        // BASIC
        let tahunAktif = "\(json["tahunAktif"] ?? "")"
        let bulanAwal = "\(json["bulanAwal"] ?? "")"

        // SUMMARY SUBDIT
        var summary: [String: SummarySubdit] = [:]

        if let rawSummary = json["summarySubdit"] as? [String: Any] {

            for (key, value) in rawSummary {

                if let obj = value as? [String: Any] {

                    let diajukan = String(describing: obj["diajukan"] ?? "0")
                    let terserap = String(describing: obj["terserap"] ?? "0")
                    let persen = String(describing: obj["persen"] ?? "0")

                    summary[key] = SummarySubdit(
                        diajukan: diajukan,
                        terserap: terserap,
                        persen: persen
                    )
                }
            }
        }

        // USER TERAKHIR
        var users: [UserTerakhir] = []

        if let rawUsers = json["userTerakhir"] as? [[String: Any]] {

            for obj in rawUsers {

                users.append(
                    UserTerakhir(
                        name: obj["name"] as? String ?? "",
                        pangkat: obj["pangkat"] as? String ?? "",
                        jabatan: obj["jabatan"] as? String ?? "",
                        subdit: obj["subdit"] as? String ?? "",
                        createdDtm: obj["createdDtm"] as? String ?? ""
                    )
                )
            }
        }

        return DashboardData(
            tahunAktif: tahunAktif,
            bulanAwal: bulanAwal,
            summarySubdit: summary,
            userTerakhir: users
        )
    }
}
final class SummarySubditCell: UICollectionViewCell {
    private let titleLabel = UILabel()
    private let valueLabel = UILabel()
    private let stack = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) { super.init(coder: coder); setup() }

    private func setup() {
        stack.axis = .horizontal
        stack.alignment = .fill
        stack.distribution = .fill
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.font = .systemFont(ofSize: 14)
        valueLabel.font = .boldSystemFont(ofSize: 14)
        valueLabel.textAlignment = .right

        contentView.addSubview(stack)
        stack.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(valueLabel)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])
    }

    func configure(title: String, value: String) {
        titleLabel.text = title
        valueLabel.text = value
    }
}

final class UserTerakhirCell: UICollectionViewCell {
    private let nameLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) { super.init(coder: coder); setup() }

    private func setup() {
        nameLabel.font = .systemFont(ofSize: 14)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(nameLabel)
        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            nameLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])
    }

    func configure(name: String) {
        nameLabel.text = name
    }
}

struct SummarySubdit {
    let diajukan: String
    let terserap: String
    let persen: String
}

struct UserTerakhir {
    let name: String
    let pangkat: String
    let jabatan: String
    let subdit: String
    let createdDtm: String
}
class MonthValueFormatter: AxisValueFormatter {
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        return String(Int(value))
    }
}

