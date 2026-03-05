//
//  ProfileActivity.swift
//  Doas
//
//  Created by Admin on 06/03/26.
//

import UIKit

final class ProfileActivity: Boyke, UIPickerViewDelegate, UIPickerViewDataSource {

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private let stack = UIStackView()

    private let etUsername = UITextField()
    private let etNIP = UITextField()
    private let etRole = UITextField()
    private let etNama = UITextField()
    private let etPangkat = UITextField()
    private let etJabatan = UITextField()

    private let etPassLama = UITextField()
    private let etPassBaru = UITextField()
    private let etPassKonfirmasi = UITextField()

    private let btSimpanProfile = UIButton(type: .system)
    private let btUbahPassword = UIButton(type: .system)

    private let subditPicker = UIPickerView()
    private let subditField = UITextField()

    private let subditList = [
        "Subdit 1",
        "Subdit 2",
        "Subdit 3",
        "Subdit 4",
        "Subdit 5",
        "Staff Pimpinan"
    ]

    private var subdit: String?

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Edit Profile"
        view.backgroundColor = .systemGroupedBackground

     

        setupLayout()
        loadUserData()
        setupNavigation()
    }

    private func setupNavigation() {

        let nav = UINavigationBar()
        nav.translatesAutoresizingMaskIntoConstraints = false

        let item = UINavigationItem(title: "Edit Profile")

        let back = UIBarButtonItem(
            image: UIImage(named: "kembali"),
            style: .plain,
            target: self,
            action: #selector(goBack)
        )

        item.leftBarButtonItem = back
        nav.setItems([item], animated: false)

        view.addSubview(nav)

        NSLayoutConstraint.activate([
            nav.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            nav.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            nav.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    @objc private func goBack() {
        dismiss(animated: true)
    }

    // MARK: Layout

    private func setupLayout() {

        scrollView.translatesAutoresizingMaskIntoConstraints = false
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

        stack.axis = .vertical
        stack.spacing = 24
        stack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])

        stack.addArrangedSubview(createProfileCard())
        stack.addArrangedSubview(createPasswordCard())
    }

    // MARK: Card Profile

    private func createProfileCard() -> UIView {

        let card = createCard()

        let v = UIStackView()
        v.axis = .vertical
        v.spacing = 12

        v.addArrangedSubview(createField("Username", etUsername))
        v.addArrangedSubview(createField("NIP", etNIP))
        v.addArrangedSubview(createField("Role", etRole))
        v.addArrangedSubview(createField("Nama Lengkap", etNama))
        v.addArrangedSubview(createField("Pangkat", etPangkat))
        v.addArrangedSubview(createField("Jabatan", etJabatan))

        subditPicker.delegate = self
        subditPicker.dataSource = self

        subditField.placeholder = "Subdit"
        subditField.borderStyle = .roundedRect
        subditField.inputView = subditPicker

        v.addArrangedSubview(subditField)

        btSimpanProfile.setTitle("Simpan Profile", for: .normal)
        btSimpanProfile.backgroundColor = .systemBlue
        btSimpanProfile.setTitleColor(.white, for: .normal)
        btSimpanProfile.layer.cornerRadius = 8
        btSimpanProfile.heightAnchor.constraint(equalToConstant: 44).isActive = true
        btSimpanProfile.addTarget(self, action: #selector(saveProfile), for: .touchUpInside)

        v.addArrangedSubview(btSimpanProfile)

        card.addSubview(v)
        v.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            v.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            v.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),
            v.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            v.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16)
        ])

        return card
    }

    // MARK: Card Password

    private func createPasswordCard() -> UIView {

        let card = createCard()

        let v = UIStackView()
        v.axis = .vertical
        v.spacing = 12

        etPassLama.isSecureTextEntry = true
        etPassBaru.isSecureTextEntry = true
        etPassKonfirmasi.isSecureTextEntry = true

        v.addArrangedSubview(createField("Password Lama", etPassLama))
        v.addArrangedSubview(createField("Password Baru", etPassBaru))
        v.addArrangedSubview(createField("Konfirmasi Password", etPassKonfirmasi))

        btUbahPassword.setTitle("Ubah Password", for: .normal)
        btUbahPassword.backgroundColor = .systemOrange
        btUbahPassword.setTitleColor(.white, for: .normal)
        btUbahPassword.layer.cornerRadius = 8
        btUbahPassword.heightAnchor.constraint(equalToConstant: 44).isActive = true
        btUbahPassword.addTarget(self, action: #selector(changePassword), for: .touchUpInside)

        v.addArrangedSubview(btUbahPassword)

        card.addSubview(v)

        v.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            v.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            v.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),
            v.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            v.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16)
        ])

        return card
    }

    // MARK: Helpers

    private func createCard() -> UIView {

        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 12
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.1
        v.layer.shadowRadius = 6
        v.layer.shadowOffset = CGSize(width: 0, height: 4)

        return v
    }

    private func createField(_ label: String, _ field: UITextField) -> UIView {

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 4

        let l = UILabel()
        l.text = label
        l.font = .systemFont(ofSize: 13)

        field.borderStyle = .roundedRect

        stack.addArrangedSubview(l)
        stack.addArrangedSubview(field)

        return stack
    }

    // MARK: Picker

    func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        subditList.count
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        subdit = subditList[row]
        subditField.text = subdit
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        subditList[row]
    }

    // MARK: Load Data

    private func loadUserData() {

        AuthManager(endpoint: "api/getme").checkAuth(

            params: [:],

            onSuccess: { json in

                guard let aesKey = json["aes_key"] as? String,
                      let data = json["data"] as? [String: Any] else { return }

                DispatchQueue.main.async {

                    self.etUsername.text = CryptoAES.decrypt(data["username"] as? String ?? "", aesKey)
                    self.etNIP.text = CryptoAES.decrypt(data["nip"] as? String ?? "", aesKey)
                    self.etNama.text = CryptoAES.decrypt(data["nama"] as? String ?? "", aesKey)
                    self.etPangkat.text = CryptoAES.decrypt(data["pangkat"] as? String ?? "", aesKey)
                    self.etJabatan.text = CryptoAES.decrypt(data["jabatan"] as? String ?? "", aesKey)

                    let subditDb = CryptoAES.decrypt(data["subdit"] as? String ?? "", aesKey)

                    if let index = self.subditList.firstIndex(of: subditDb) {
                        self.subditPicker.selectRow(index, inComponent: 0, animated: false)
                        self.subditField.text = subditDb
                        self.subdit = subditDb
                    }
                    let roleId = CryptoAES.decrypt(data["roleId"] as? String ?? "", aesKey)

                    let roleText: String

                    switch roleId {
                    case "2": roleText = "Admin Utama"
                    case "3": roleText = "Admin User"
                    case "4": roleText = "Admin Berita"
                    case "5": roleText = "Admin Anggaran"
                    case "6": roleText = "Admin kantor"
                    case "7": roleText = "Admin laporan"
                    case "8": roleText = "User"
                    default: roleText = roleId
                    }

                    self.etRole.text = roleText
                    self.etUsername.isEnabled = false
                    self.etNIP.isEnabled = false
                    self.etRole.isEnabled = false
                }
            },

            onLogout: { message in
                DispatchQueue.main.async {
                    self.showAlert(message)
                }
            },

            onLoading: { loading in
                DispatchQueue.main.async {
                    loading ? self.showLoading() : self.hideLoading()
                }
            }
        )
    }

    // MARK: Save Profile

    @objc private func saveProfile() {

        guard let subdit = subdit else {
            showAlert("Pilih Subdit")
            return
        }

        var params: [String:String] = [:]

        params["nama"] = etNama.text ?? ""
        params["pangkat"] = etPangkat.text ?? ""
        params["jabatan"] = etJabatan.text ?? ""
        params["subdit"] = subdit

        AuthManager(endpoint: "api/simpanprofile").checkAuth(
            params: params,

            onSuccess: { json in

                if let status = json["status"] as? String, status == "ok" {

                    DispatchQueue.main.async {
                        self.showAlert("Profile berhasil diubah")
                        self.dismiss(animated: true)
                    }
                }
            },

            onLogout: { message in
                DispatchQueue.main.async {
                    self.showAlert(message)
                }
            },

            onLoading: { loading in
                DispatchQueue.main.async {
                    loading ? self.showLoading() : self.hideLoading()
                }
            }
        )
    }

    // MARK: Change Password

    @objc private func changePassword() {

        let lama = etPassLama.text ?? ""
        let baru = etPassBaru.text ?? ""
        let konfirmasi = etPassKonfirmasi.text ?? ""

        if lama.isEmpty || baru.isEmpty {
            showAlert("Password tidak boleh kosong")
            return
        }

        if baru != konfirmasi {
            showAlert("Konfirmasi password tidak cocok")
            return
        }

        var params: [String:String] = [:]

        params["old_password"] = lama
        params["new_password"] = baru

        AuthManager(endpoint: "api/ubahpassword").checkAuth(
            params: params,

            onSuccess: { _ in
                DispatchQueue.main.async {
                    self.showAlert("Password berhasil diubah")
                }
            },

            onLogout: { message in
                DispatchQueue.main.async {
                    self.showAlert(message)
                }
            },

            onLoading: { loading in
                DispatchQueue.main.async {
                    loading ? self.showLoading() : self.hideLoading()
                }
            }
        )
    }
    func showAlert(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
