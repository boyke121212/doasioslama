// DoctorListActivity.swift
// Porting dari DoctorListActivity.kt

import UIKit

class DoctorListActivity: Boyke {

    // MARK: - Model
    struct Doctor {
        let id: String
        let name: String
        let specialty: String
        let aesKey: String
        var unreadCount: Int
    }

    // MARK: - Properties
    private var doctors: [Doctor] = []
    private let headerView = UIView()
    private let backButton = UIButton()
    // MARK: - UI Components
    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.backgroundColor = .clear
        tv.separatorStyle = .none
        tv.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        tv.register(DoctorCell.self, forCellReuseIdentifier: DoctorCell.reuseId)
        tv.dataSource = self
        tv.delegate = self
        return tv
    }()

    private lazy var loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        return indicator
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        monitorInternet()
        setupNavigation()
        setupHeader()
        setupUI()
       
    }

    private func setupHeader() {
        
        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.backgroundColor = .white
        
        view.addSubview(headerView)
        
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 56)
        ])
        
        // Shadow biar mirip navbar
        headerView.layer.shadowColor = UIColor.black.cgColor
        headerView.layer.shadowOpacity = 0.08
        headerView.layer.shadowOffset = CGSize(width: 0, height: 2)
        headerView.layer.shadowRadius = 4
        
        // BACK BUTTON
        backButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Icon + Text
        let image = UIImage(systemName: "chevron.left")
        backButton.setImage(image, for: .normal)
        backButton.setTitle(" Kembali", for: .normal)
        
        backButton.setTitleColor(.systemBlue, for: .normal)
        backButton.tintColor = .systemBlue
        backButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        
        backButton.contentHorizontalAlignment = .leading
        
        headerView.addSubview(backButton)
        
        NSLayoutConstraint.activate([
            backButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            backButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor)
        ])
        
        backButton.addTarget(self, action: #selector(onBack), for: .touchUpInside)
    }
    @objc private func onBack() {
        openPage(Home())
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        monitorInternet()
        fetchDoctors(showProgress: true)
    }

    // MARK: - Setup
    private func setupNavigation() {
        title = "Chat Dokter"
        navigationController?.navigationBar.tintColor = .white
        navigationController?.navigationBar.barTintColor = UIColor(named: "brand_primary")
        navigationController?.navigationBar.titleTextAttributes = [
            .foregroundColor: UIColor.white
        ]
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(handleBack)
        )
    }

    private func setupUI() {
        view.backgroundColor = UIColor(named: "bg_app") ?? .systemGroupedBackground

        view.addSubview(tableView)
        view.addSubview(loadingIndicator)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: headerView.bottomAnchor),         tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    // MARK: - Actions
    @objc private func handleBack() {
        navigationController?.popViewController(animated: true)
    }

    // MARK: - Loading State
 

    // MARK: - Navigation to Chat
    private func openChat(with doctor: Doctor) {
        let chatVC = ChatActivity()
        chatVC.doctorId   = doctor.id
        chatVC.doctorName = doctor.name
        chatVC.aesKey     = doctor.aesKey
        let nav = UINavigationController(rootViewController: chatVC)
        nav.modalPresentationStyle = .fullScreen

        openPage(nav)
    }

    // MARK: - Fetch Doctors
    private func fetchDoctors(showProgress: Bool = true) {
        let params: [String: String] = ["roleId": "9"]

        AuthManager(endpoint: "api/dokters").checkAuth(
            params: params,
            onSuccess: { [weak self] json in
                guard let self = self else { return }

                let aesKey    = json["aes_key"] as? String ?? ""
                let dataArray = json["data"] as? [[String: Any]] ?? []

                // Simpan posisi scroll sebelum update
                let offset = self.tableView.contentOffset

                self.doctors = dataArray.compactMap { obj in
                    let unread     = obj["unread_count"] as? Int ?? 0
                    let rawName    = obj["name"] as? String ?? ""
                    let rawJabatan = obj["jabatan"] as? String ?? ""
                    let userId     = obj["userId"] as? String ?? ""

                    return Doctor(
                        id:          userId,
                        name:        CryptoAES.decrypt(rawName, aesKey),
                        specialty:   CryptoAES.decrypt(rawJabatan, aesKey),
                        aesKey:      aesKey,
                        unreadCount: unread
                    )
                }

                self.tableView.reloadData()

                // Restore posisi scroll
                self.tableView.setContentOffset(offset, animated: false)
            },
            onLogout: { _ in },
            onLoading: { [weak self] isLoading in
                guard let self = self else { return }
                if showProgress {
                    isLoading ? self.showLoading() : self.hideLoading()
                }
            }
        )
    }
}

// MARK: - UITableViewDataSource
extension DoctorListActivity: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return doctors.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: DoctorCell.reuseId,
            for: indexPath
        ) as? DoctorCell else {
            return UITableViewCell()
        }
        cell.configure(with: doctors[indexPath.row])
        return cell
    }
}

// MARK: - UITableViewDelegate
extension DoctorListActivity: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        // 1. Reset unreadCount lokal agar badge langsung hilang
        doctors[indexPath.row].unreadCount = 0
        tableView.reloadRows(at: [indexPath], with: .none)

        // 2. Navigasi ke ChatActivity
        openChat(with: doctors[indexPath.row])
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
}

// MARK: - DoctorCell (setara item_doctor.xml)
final class DoctorCell: UITableViewCell {
    static let reuseId = "DoctorCell"

    // Avatar
    private let avatarImageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 25
        iv.layer.borderWidth  = 1
        iv.layer.borderColor  = UIColor(named: "brand_primary")?.cgColor
        iv.image = UIImage(systemName: "person.fill")
        iv.tintColor = UIColor(named: "brand_primary")
        return iv
    }()

    // Nama dokter
    private let nameLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = .systemFont(ofSize: 16, weight: .bold)
        lbl.textColor = UIColor(named: "text_primary") ?? .label
        lbl.numberOfLines = 1
        return lbl
    }()

    // Spesialis
    private let specialtyLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = .systemFont(ofSize: 14)
        lbl.textColor = UIColor(named: "text_muted") ?? .secondaryLabel
        lbl.numberOfLines = 1
        return lbl
    }()

    // Icon chat
    private let chatIconImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "message.fill")
        iv.tintColor = UIColor(named: "brand_primary")
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    // Badge unread
    private let unreadBadge: UILabel = {
        let lbl = UILabel()
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.font = .systemFont(ofSize: 10, weight: .bold)
        lbl.textColor = .white
        lbl.textAlignment = .center
        lbl.backgroundColor = .red
        lbl.layer.cornerRadius = 10
        lbl.clipsToBounds = true
        lbl.isHidden = true
        return lbl
    }()

    // Card container
    private let cardView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .systemBackground
        v.layer.cornerRadius = 12
        v.layer.shadowColor   = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.08
        v.layer.shadowOffset  = CGSize(width: 0, height: 2)
        v.layer.shadowRadius  = 4
        return v
    }()

    // MARK: - Init
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        backgroundColor = .clear
        selectionStyle  = .none

        contentView.addSubview(cardView)

        let nameStack = UIStackView(arrangedSubviews: [nameLabel, specialtyLabel])
        nameStack.axis    = .vertical
        nameStack.spacing = 2
        nameStack.translatesAutoresizingMaskIntoConstraints = false

        let trailingStack = UIStackView(arrangedSubviews: [chatIconImageView, unreadBadge])
        trailingStack.axis = .horizontal
        trailingStack.alignment = .center
        trailingStack.spacing = 6
        trailingStack.centerYAnchor.constraint(equalTo: cardView.centerYAnchor)
        trailingStack.translatesAutoresizingMaskIntoConstraints = false

        [avatarImageView, nameStack, trailingStack].forEach { cardView.addSubview($0) }

        NSLayoutConstraint.activate([
            // Card
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),

            // Avatar
            avatarImageView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),
            avatarImageView.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: 50),
            avatarImageView.heightAnchor.constraint(equalToConstant: 50),
            avatarImageView.topAnchor.constraint(greaterThanOrEqualTo: cardView.topAnchor, constant: 12),
            avatarImageView.bottomAnchor.constraint(lessThanOrEqualTo: cardView.bottomAnchor, constant: -12),

            // Name stack
            nameStack.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 16),
            nameStack.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            nameStack.trailingAnchor.constraint(equalTo: trailingStack.leadingAnchor, constant: -8),

            // Trailing (icon + badge)
            trailingStack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -12),
            trailingStack.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),

            chatIconImageView.widthAnchor.constraint(equalToConstant: 24),
            chatIconImageView.heightAnchor.constraint(equalToConstant: 24),

            unreadBadge.widthAnchor.constraint(equalToConstant: 20),
            unreadBadge.heightAnchor.constraint(equalToConstant: 20)
        ])
    }

    // MARK: - Configure
    func configure(with doctor: DoctorListActivity.Doctor) {
        nameLabel.text      = doctor.name
        specialtyLabel.text = doctor.specialty

        if doctor.unreadCount > 0 {
            unreadBadge.isHidden = false
            unreadBadge.text = doctor.unreadCount > 99 ? "99+" : "\(doctor.unreadCount)"
        } else {
            unreadBadge.isHidden = true
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        cardView.layer.shadowPath = UIBezierPath(
            roundedRect: cardView.bounds,
            cornerRadius: 12
        ).cgPath
    }
}
