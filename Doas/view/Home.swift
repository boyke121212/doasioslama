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
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        refreshData()
        print("Hero height home: ", heroContainer.frame.height)

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
        
//        btAbsen.addTarget(self, action: #selector(onTapAbsen), for: .touchUpInside)
//        btStatus.addTarget(self, action: #selector(onTapStatus), for: .touchUpInside)
//        btInfo.addTarget(self, action: #selector(onTapInfo), for: .touchUpInside)
//        btLog.addTarget(self, action: #selector(onTapLog), for: .touchUpInside)
//        btProfile.addTarget(self, action: #selector(onTapProfile), for: .touchUpInside)
//        btDoas.addTarget(self, action: #selector(onTapDoas), for: .touchUpInside)
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
            dashboardCard.topAnchor.constraint(equalTo: gridContainer.bottomAnchor, constant: 16),
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
        stack.addArrangedSubview(chartTitle)
        stack.addArrangedSubview(chartPlaceholder)
        userContainer.axis = .vertical
        userContainer.spacing = 8
        userContainer.alignment = .fill
        userContainer.distribution = .fill
        stack.addArrangedSubview(userContainer)
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

//        legend.verticalAlignment = .bottom
//        legend.horizontalAlignment = .right   // mentok kanan
//        legend.orientation = .horizontal      // 🔥 horizontal

//        legend.drawInside = false
//        legend.wordWrapEnabled = true

//        legend.form = .circle
//        legend.formSize = 8

//        legend.xEntrySpace = 6
//        legend.yEntrySpace = 3

//        legend.font = UIFont.systemFont(ofSize: 9)  // 🔥 kecilkan font
//        legend.maxSizePercent = 1.0

        lineChartView.extraBottomOffset = 12   // 🔥 margin dari chart ke legend       // 🔥 penting supaya tidak potong chart

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

        guard
            let json = rawDashboardJSON,
            let dashboard = json["dashboard"] as? [String: Any],
            let dataMap = dashboard["dataMap"] as? [String: Any]
        else {
            lineChartView.clear()
            return
        }

        var dataSets: [LineChartDataSet] = []
        var globalMaxY: Double = 0

        let colors: [UIColor] = [
            UIColor.blue,      // Color.BLUE
            UIColor.red,       // Color.RED
            UIColor.green,     // Color.GREEN
            UIColor.magenta,   // Color.MAGENTA
            UIColor.cyan       // Color.CYAN
        ]

        var colorIndex = 0

        // LOOP SUBDIT
        for (subdit, monthsValue) in dataMap {

            guard let months = monthsValue as? [String: Any] else { continue }

            var entries: [ChartDataEntry] = []

            // LOOP BULAN
            for (bulanStr, detailValue) in months {

                guard
                    let xValue = Double(bulanStr),
                    let detail = detailValue as? [String: Any],
                    let terserapStr = detail["anggaran_terserap"] as? String,
                    let terserap = Double(terserapStr)
                else { continue }

                entries.append(
                    ChartDataEntry(
                        x: xValue,
                        y: terserap
                    )
                )

                if terserap > globalMaxY {
                    globalMaxY = terserap
                }
            }

            entries.sort { $0.x < $1.x }

            if !entries.isEmpty {

                let dataSet = LineChartDataSet(
                    entries: entries,
                    label: subdit
                )

                let color = colors[colorIndex % colors.count]

                dataSet.colors = [color]
                dataSet.circleColors = [color]
                dataSet.lineWidth = 2
                dataSet.circleRadius = 4
                dataSet.drawValuesEnabled = false
                dataSet.mode = .linear

                dataSets.append(dataSet)
                colorIndex += 1
            }
        }

        let lineData = LineChartData(dataSets: dataSets)
        lineChartView.data = lineData

        // Build custom legend (ordered rows, left-aligned)
        lineChartView.legend.enabled = false

        // Clear old legend rows
        customLegend.arrangedSubviews.forEach { row in
            customLegend.removeArrangedSubview(row)
            row.removeFromSuperview()
        }

        // Make spacing a bit larger so rows aren't too tight
        customLegend.spacing = 10

        // Helper: create a legend item view
        func makeLegendItem(color: UIColor, text: String) -> UIView {
            let dot = UIView()
            dot.translatesAutoresizingMaskIntoConstraints = false
            dot.backgroundColor = color
            dot.layer.cornerRadius = 4
            NSLayoutConstraint.activate([
                dot.widthAnchor.constraint(equalToConstant: 8),
                dot.heightAnchor.constraint(equalToConstant: 8)
            ])

            let label = UILabel()
            label.font = UIFont.systemFont(ofSize: 11)
            label.textColor = .darkGray
            label.text = text

            let h = UIStackView(arrangedSubviews: [dot, label])
            h.axis = .horizontal
            h.alignment = .center
            h.spacing = 6
            return h
        }

        // Map dataset by label for quick lookup
        var dataSetByLabel: [String: LineChartDataSet] = [:]
        for set in dataSets {
            if let label = set.label { dataSetByLabel[label] = set }
        }

        // Desired ordering per row
        let row1Labels = ["Subdit 1", "Subdit 2", "Subdit 3", "Subdit 4", "Subdit 5"]
        let row2Labels = ["Subdit Staff", "Pimpinan"]

        func makeRow(with labels: [String]) -> UIStackView {
            let row = UIStackView()
            row.axis = .horizontal
            row.alignment = .center
            row.spacing = 12
            row.distribution = .fill
            for label in labels {
                if let set = dataSetByLabel[label] {
                    let color = set.colors.first ?? .label
                    let item = makeLegendItem(color: color, text: label)
                    row.addArrangedSubview(item)
                }
            }
            return row
        }

        // Add rows to customLegend
        let row1 = makeRow(with: row1Labels)
        let row2 = makeRow(with: row2Labels)
        customLegend.addArrangedSubview(row1)
        customLegend.addArrangedSubview(row2)

        // If there are any remaining datasets not covered by the two rows, add them as a third row (optional fallback)
        let covered = Set(row1Labels + row2Labels)
        let remaining = dataSets.compactMap { $0.label }.filter { !covered.contains($0) }
        if !remaining.isEmpty {
            let row3 = UIStackView()
            row3.axis = .horizontal
            row3.alignment = .center
            row3.spacing = 12
            row3.distribution = .fill
            for label in remaining {
                if let set = dataSetByLabel[label] {
                    let color = set.colors.first ?? .label
                    let item = makeLegendItem(color: color, text: label)
                    row3.addArrangedSubview(item)
                }
            }
            customLegend.addArrangedSubview(row3)
        }

        // AUTO SCALE
        lineChartView.leftAxis.axisMinimum = 0
        lineChartView.leftAxis.axisMaximum = globalMaxY * 1.2
        lineChartView.leftAxis.labelCount = 5
        lineChartView.leftAxis.forceLabelsEnabled = false

        // BULAN
        lineChartView.xAxis.labelPosition = .top
        lineChartView.xAxis.granularity = 1
        lineChartView.xAxis.axisMinimum = 1
        lineChartView.xAxis.axisMaximum = 12
        lineChartView.xAxis.valueFormatter = MonthValueFormatter()
        lineChartView.xAxis.drawGridLinesEnabled = true

        // ===== LEGEND =====
//        let legend = lineChartView.legend
//        legend.enabled = true

//        legend.verticalAlignment = .bottom
//        legend.horizontalAlignment = .right   // mentok kanan
//        legend.orientation = .horizontal      // 🔥 horizontal

//        legend.drawInside = false
//        legend.wordWrapEnabled = true

//        legend.form = .circle
//        legend.formSize = 8

//        legend.xEntrySpace = 6
//        legend.yEntrySpace = 3

//        legend.font = UIFont.systemFont(ofSize: 9)  // 🔥 kecilkan font
//        legend.maxSizePercent = 1.0

        lineChartView.extraBottomOffset = 20
        // STYLE
        lineChartView.rightAxis.enabled = false

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


