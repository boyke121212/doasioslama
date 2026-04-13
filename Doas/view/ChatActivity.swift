import UIKit
import AVFoundation
import UniformTypeIdentifiers

// MARK: - ChatActivity

class ChatActivity: Boyke {

    // MARK: - Properties

     var messages: [Message] = []
     var doctorId = ""         // Decrypted
     var rawDoctorId: String?      // Encrypted (RAW)
     var aesKey: String = ""
     var accessToken: String?
     var doctorName: String?
    

    private var pollingTimer: Timer?
    private var docInteractionController: UIDocumentInteractionController?

    // MARK: - UI

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.separatorStyle = .none
        tv.backgroundColor = .clear
        tv.keyboardDismissMode = .interactive
        tv.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.register(OutgoingCell.self, forCellReuseIdentifier: OutgoingCell.reuseId)
        tv.register(IncomingCell.self, forCellReuseIdentifier: IncomingCell.reuseId)
        tv.rowHeight = UITableView.automaticDimension
        tv.estimatedRowHeight = 80
        tv.delegate = self
        tv.dataSource = self
        return tv
    }()

    private lazy var inputContainer: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.translatesAutoresizingMaskIntoConstraints = false
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.10
        v.layer.shadowOffset = CGSize(width: 0, height: -2)
        v.layer.shadowRadius = 6
        return v
    }()

    private lazy var btnClip: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: "paperclip"), for: .normal)
        b.tintColor = UIColor.fromHex("#757575")
        b.translatesAutoresizingMaskIntoConstraints = false
        b.addTarget(self, action: #selector(didTapClip), for: .touchUpInside)
        return b
    }()

    private lazy var btnCamera: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: "camera.fill"), for: .normal)
        b.tintColor = UIColor.fromHex("#757575")
        b.translatesAutoresizingMaskIntoConstraints = false
        b.addTarget(self, action: #selector(didTapCamera), for: .touchUpInside)
        return b
    }()

    private lazy var messageTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Ketik pesan..."
        tf.backgroundColor = UIColor.fromHex("#F5F5F5")
        tf.textColor = UIColor.fromHex("#212121")
        tf.font = .systemFont(ofSize: 16)
        tf.layer.cornerRadius = 22
        tf.clipsToBounds = true
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 14, height: 0))
        tf.leftViewMode = .always
        tf.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 14, height: 0))
        tf.rightViewMode = .always
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()

    private lazy var btnSend: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: "paperplane.fill"), for: .normal)
        b.tintColor = .white
        b.backgroundColor = UIColor(named: "brand_primary") ?? .systemBlue
        b.layer.cornerRadius = 24
        b.clipsToBounds = true
        b.translatesAutoresizingMaskIntoConstraints = false
        b.addTarget(self, action: #selector(didTapSend), for: .touchUpInside)
        return b
    }()

    private var inputBottomConstraint: NSLayoutConstraint?

    // MARK: - Init

    /// Designated initializer — mirrors Android Intent extras
  


    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(named: "bg_app") ?? UIColor(hex: "#F0F0F0")
        accessToken = SecurePrefs().getAccessToken()
        doctorId=CryptoAES.decrypt(doctorId, aesKey)
        setupNavigationBar()
        setupUI()
        setupKeyboardObservers()

        fetchMessages(showProgress: true)
        markMessagesAsRead()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startPolling()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopPolling()
    }



    // MARK: - Navigation Bar
    private func setupNavigationBar() {
        title = doctorName ?? "Chat"

        let brandColor = UIColor(named: "brand_primary") ?? .systemBlue

        // Simple icon button (clean)
        let backIcon = UIImage(systemName: "chevron.left")

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: backIcon,
            style: .plain,
            target: self,
            action: #selector(didTapBack)
        )

        navigationItem.leftBarButtonItem?.tintColor = .white

        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = brandColor
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]

        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
    }

    // MARK: - UI Setup

    private func setupUI() {
        // ── Table view ──────────────────────────────────────────────────────────
        view.addSubview(tableView)

        // ── Input container ─────────────────────────────────────────────────────
        view.addSubview(inputContainer)

        let stack = UIStackView(arrangedSubviews: [btnClip, btnCamera, messageTextField, btnSend])
        stack.axis      = .horizontal
        stack.spacing   = 8
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        inputContainer.addSubview(stack)

        // Bottom constraint — animated when keyboard appears
        inputBottomConstraint = inputContainer.bottomAnchor.constraint(
            equalTo: view.safeAreaLayoutGuide.bottomAnchor
        )

        NSLayoutConstraint.activate([
            // Table
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: inputContainer.topAnchor),

            // Input bar
            inputContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            inputContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            inputBottomConstraint!,

            // Stack inside input bar
            stack.topAnchor.constraint(equalTo: inputContainer.topAnchor, constant: 8),
            stack.leadingAnchor.constraint(equalTo: inputContainer.leadingAnchor, constant: 8),
            stack.trailingAnchor.constraint(equalTo: inputContainer.trailingAnchor, constant: -8),
            stack.bottomAnchor.constraint(equalTo: inputContainer.bottomAnchor, constant: -8),

            // Button / field sizes
            btnClip.widthAnchor.constraint(equalToConstant: 44),
            btnClip.heightAnchor.constraint(equalToConstant: 44),
            btnCamera.widthAnchor.constraint(equalToConstant: 44),
            btnCamera.heightAnchor.constraint(equalToConstant: 44),
            messageTextField.heightAnchor.constraint(equalToConstant: 44),
            btnSend.widthAnchor.constraint(equalToConstant: 48),
            btnSend.heightAnchor.constraint(equalToConstant: 48),
        ])
    }

    // MARK: - Keyboard

    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            self, selector: #selector(keyboardWillShow(_:)),
            name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(
            self, selector: #selector(keyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc private func keyboardWillShow(_ n: Notification) {
        guard let kbFrame = n.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let duration = n.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double
        else { return }
        let kbHeight = kbFrame.height - view.safeAreaInsets.bottom
        inputBottomConstraint?.constant = -kbHeight
        UIView.animate(withDuration: duration) { self.view.layoutIfNeeded() }
        scrollToBottom(animated: true)
    }

    @objc private func keyboardWillHide(_ n: Notification) {
        guard let duration = n.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double
        else { return }
        inputBottomConstraint?.constant = 0
        UIView.animate(withDuration: duration) { self.view.layoutIfNeeded() }
    }

    // MARK: - Actions

    @objc private func didTapBack() {
       openPage(DoctorListActivity())
    }

    @objc private func didTapSend() {
        let text = messageTextField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        guard !text.isEmpty else { return }
        sendMessage(text: text)
    }

    @objc private func didTapCamera() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            openCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    granted ? self?.openCamera() : self?.showToast("Izin kamera dibutuhkan untuk mengambil foto")
                }
            }
        default:
            showToast("Izin kamera dibutuhkan untuk mengambil foto")
        }
    }

    @objc private func didTapClip() {
        if #available(iOS 14.0, *) {
            let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.item])
            picker.delegate = self
            present(picker, animated: true)
        } else {
            let picker = UIDocumentPickerViewController(documentTypes: ["public.item"], in: .import)
            picker.delegate = self
            present(picker, animated: true)
        }
    }

    // MARK: - Camera

    private func openCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            showToast("Kamera tidak tersedia di perangkat ini"); return
        }
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate   = self
        present(picker, animated: true)
    }

    // MARK: - Polling

    private func startPolling() {
        stopPolling()
        pollingTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.fetchMessages(showProgress: false)
        }
    }

    private func stopPolling() {
        pollingTimer?.invalidate()
        pollingTimer = nil
    }

    // MARK: - API Calls
    private func fetchMessages(showProgress: Bool = true) {
        let params: [String: String] = ["receiver_id": doctorId]

        AuthManager(endpoint: "api/chats").checkAuth(
            params: params,

            onSuccess: { [weak self] json in
                guard let self = self else { return }

                let dataArray       = json["data"] as? [[String: Any]] ?? []
                let aesFromResponse = json["aes_key"] as? String ?? ""
                let oldSize         = self.messages.count

                var newMessages: [Message] = []

                for obj in dataArray {
                    let encryptedMsg  = obj["message"]   as? String ?? ""
                    let encryptedPath = obj["file_path"] as? String ?? ""
                    let senderId      = obj["sender_id"] as? String ?? ""

                    let decryptedMsg  = CryptoAES.decrypt(encryptedMsg, aesFromResponse)
                    let decryptedPath = CryptoAES.decrypt(encryptedPath, aesFromResponse)

                    newMessages.append(Message(
                        id: obj["id"] as? String ?? "",
                        content: decryptedMsg,
                        senderId: senderId,
                        fileUrl: decryptedPath.isEmpty ? nil : decryptedPath,
                        timestamp: obj["created_at"] as? String ?? "",
                        isOutgoing: senderId != self.doctorId
                    ))
                }

                if newMessages.count != oldSize {
                    self.messages = newMessages
                    self.tableView.reloadData()
                    self.scrollToBottom(animated: true)
                }
            },

            onLogout: { [weak self] msg in
                self?.showToast(msg)
            },

            onLoading: { [weak self] isLoading in
                guard let self = self else { return }
                if showProgress {
                    isLoading ? self.showLoading() : self.hideLoading()
                }
            }
        )
    }
    private func sendMessage(text: String) {
        let encryptedText = text.isEmpty ? "" : CryptoAES.encrypt(text, aesKey)

        let params: [String: String] = [
            "receiver_id": doctorId,
            "content": encryptedText,
            "aes_key": aesKey,
            "file_path": CryptoAES.encrypt("",  aesKey),
            "file_type": "text"
        ]

        AuthManager(endpoint: "api/chats/send").uploadFoto(
            files: nil,
            params: params,

            onSuccess: { [weak self] _ in
                self?.messageTextField.text = ""
                self?.fetchMessages()
            },

            onError: { [weak self] msg in
                self?.showToast(msg)
            },

            onLogout: { [weak self] msg in
                self?.showToast(msg)
            },

            onLoading: { [weak self] isLoading in
                isLoading ? self?.showLoading() : self?.hideLoading()
            }
        )
    }

    private func markMessagesAsRead() {
        let params: [String: String] = ["receiver_id": doctorId ?? ""]

        AuthManager(endpoint: "api/chats/read").checkAuth(
            params: params,
            onSuccess: { _ in },
            onLogout: { _ in },
            onLoading: { _ in }
        )
    }
    // MARK: - File Upload
    private func uploadAndSend(fileURL: URL) {
        let compressedURL = compressImageIfNeeded(url: fileURL) ?? fileURL
        let ext = compressedURL.pathExtension.lowercased()

        let params: [String: String] = [
            "receiver_id": doctorId ?? "",
            "aes_key":     aesKey,
            "content":     CryptoAES.encrypt("",  aesKey),
            "file_path":   CryptoAES.encrypt(compressedURL.lastPathComponent,  aesKey),
            "file_type":   ext == "pdf" ? "pdf" : "image"
        ]

        AuthManager(endpoint: "api/chats/send").uploadFoto(
            files: [compressedURL],
            params: params,

            onSuccess: { [weak self] _ in
                self?.fetchMessages()
            },

            onError: { [weak self] msg in
                self?.showToast(msg)
            },

            onLogout: { [weak self] msg in
                self?.showToast(msg)
            },

            onLoading: { [weak self] isLoading in
                isLoading ? self?.showLoading() : self?.hideLoading()
            }
        )
    }

    /// Compress JPEG to 70% quality, mirroring Android's compressImage()
    private func compressImageIfNeeded(url: URL) -> URL? {
        guard let image = UIImage(contentsOfFile: url.path),
              let data  = image.jpegData(compressionQuality: 0.7) else { return nil }
        let dest = FileManager.default.temporaryDirectory
            .appendingPathComponent("compressed_\(url.lastPathComponent)")
        try? data.write(to: dest)
        return dest
    }

    // MARK: - PDF

    private func downloadAndOpenPdf(urlString: String, fileName: String) {
        guard let url = URL(string: urlString) else { return }
        showLoading()

        var request = URLRequest(url: url)
        request.addValue("Bearer \(accessToken ?? "")", forHTTPHeaderField: "Authorization")
        request.addValue(DeviceSecurityHelper.getDeviceHash(),        forHTTPHeaderField: "X-Device-Hash")
        request.addValue(DeviceSecurityHelper.getAppSignatureHash(),  forHTTPHeaderField: "X-App-Signature")
        request.addValue("ios",                                        forHTTPHeaderField: "Platform")

        URLSession.shared.downloadTask(with: request) { [weak self] tempURL, response, error in
            DispatchQueue.main.async {
                self?.hideLoading()

                if let error = error {
                    self?.showToast("Gagal download: \(error.localizedDescription)"); return
                }
                guard let tempURL else { self?.showToast("File kosong"); return }

                let baseName = fileName.components(separatedBy: "/").last ?? "document.pdf"
                let destURL  = FileManager.default.temporaryDirectory.appendingPathComponent(baseName)
                try? FileManager.default.removeItem(at: destURL)
                try? FileManager.default.moveItem(at: tempURL, to: destURL)
                self?.openFile(at: destURL)
            }
        }.resume()
    }

    private func openFile(at url: URL) {
        docInteractionController = UIDocumentInteractionController(url: url)
        docInteractionController?.delegate = self
        if !(docInteractionController?.presentPreview(animated: true) ?? false) {
            showToast("Tidak ada aplikasi untuk membuka PDF")
        }
    }

    // MARK: - Helpers

    private func scrollToBottom(animated: Bool) {
        guard !messages.isEmpty else { return }
        let indexPath = IndexPath(row: messages.count - 1, section: 0)
        tableView.scrollToRow(at: indexPath, at: .bottom, animated: animated)
    }

    private func showToast(_ text: String) {
        let alert = UIAlertController(title: nil, message: text, preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { alert.dismiss(animated: true) }
    }

    // MARK: - Model

    struct Message {
        let id:         String
        let content:    String
        let senderId:   String
        let fileUrl:    String?
        let timestamp:  String
        let isOutgoing: Bool
    }
}

// MARK: - UITableViewDataSource & Delegate

extension ChatActivity: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        messages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let msg = messages[indexPath.row]
        if msg.isOutgoing {
            let cell = tableView.dequeueReusableCell(withIdentifier: OutgoingCell.reuseId, for: indexPath) as! OutgoingCell
            cell.configure(with: msg, onPdfTap: { [weak self] url, name in
                self?.downloadAndOpenPdf(urlString: url, fileName: name)
            })
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: IncomingCell.reuseId, for: indexPath) as! IncomingCell
            cell.configure(with: msg, onPdfTap: { [weak self] url, name in
                self?.downloadAndOpenPdf(urlString: url, fileName: name)
            })
            return cell
        }
    }
}

// MARK: - Camera (UIImagePickerController)

extension ChatActivity: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true)
        guard let image = info[.originalImage] as? UIImage,
              let data  = image.jpegData(compressionQuality: 0.7) else { return }

        let name    = "IMG_\(Int(Date().timeIntervalSince1970)).jpg"
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        try? data.write(to: fileURL)
        uploadAndSend(fileURL: fileURL)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}

// MARK: - Document Picker

extension ChatActivity: UIDocumentPickerDelegate {

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        _ = url.startAccessingSecurityScopedResource()
        defer { url.stopAccessingSecurityScopedResource() }

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(url.lastPathComponent)
        try? FileManager.default.removeItem(at: tempURL)
        try? FileManager.default.copyItem(at: url, to: tempURL)
        uploadAndSend(fileURL: tempURL)
    }
}

// MARK: - Document Interaction

extension ChatActivity: UIDocumentInteractionControllerDelegate {
    func documentInteractionControllerViewControllerForPreview(
        _ controller: UIDocumentInteractionController) -> UIViewController { self }
}

// ============================================================
// MARK: - OutgoingCell  (mirrors item_chat_outgoing.xml)
// ============================================================

class OutgoingCell: UITableViewCell {

    static let reuseId = "OutgoingCell"

    private var pdfTapHandler: ((String, String) -> Void)?
    private var pdfUrl: String?
    private var pdfName: String?

    // Bubble card (brand_primary background)
    private let card: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(named: "brand_primary") ?? .systemBlue
        v.layer.cornerRadius = 16
        v.layer.shadowColor  = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.08
        v.layer.shadowOffset  = CGSize(width: 0, height: 2)
        v.layer.shadowRadius  = 4
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let photoView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode   = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 12
        iv.isHidden = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let pdfContainer: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(white: 0, alpha: 0.13)
        v.layer.cornerRadius = 8
        v.isHidden = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let pdfIcon: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "doc.fill"))
        iv.tintColor = .white
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let pdfLabel: UILabel = {
        let l = UILabel()
        l.text      = "Document.pdf"
        l.textColor = .white
        l.font      = .systemFont(ofSize: 14)
        l.numberOfLines = 1
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let messageLabel: UILabel = {
        let l = UILabel()
        l.textColor     = .white
        l.font          = .systemFont(ofSize: 16)
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let timeLabel: UILabel = {
        let l = UILabel()
        l.textColor = UIColor(white: 1, alpha: 0.8)
        l.font      = .systemFont(ofSize: 10)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // Stack that holds photo / pdf / text / time
    private lazy var contentStack: UIStackView = {
        let s = UIStackView(arrangedSubviews: [photoView, pdfContainer, messageLabel, timeLabel])
        s.axis      = .vertical
        s.spacing   = 4
        s.alignment = .trailing
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    // MARK: Init
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle  = .none
        build()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func build() {
        // pdf icon + label row
        pdfContainer.addSubview(pdfIcon)
        pdfContainer.addSubview(pdfLabel)
        NSLayoutConstraint.activate([
            pdfIcon.leadingAnchor.constraint(equalTo: pdfContainer.leadingAnchor, constant: 8),
            pdfIcon.centerYAnchor.constraint(equalTo: pdfContainer.centerYAnchor),
            pdfIcon.widthAnchor.constraint(equalToConstant: 28),
            pdfIcon.heightAnchor.constraint(equalToConstant: 28),
            pdfLabel.leadingAnchor.constraint(equalTo: pdfIcon.trailingAnchor, constant: 8),
            pdfLabel.trailingAnchor.constraint(equalTo: pdfContainer.trailingAnchor, constant: -8),
            pdfLabel.topAnchor.constraint(equalTo: pdfContainer.topAnchor, constant: 8),
            pdfLabel.bottomAnchor.constraint(equalTo: pdfContainer.bottomAnchor, constant: -8),
        ])
        pdfContainer.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapPdf)))

        card.addSubview(contentStack)
        contentView.addSubview(card)

        NSLayoutConstraint.activate([
            photoView.widthAnchor.constraint(equalToConstant: 200),
            photoView.heightAnchor.constraint(equalToConstant: 200),

            contentStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
            contentStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            contentStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            contentStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -12),

            // Bubble on the right side
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            card.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 60),
        ])
    }

    // MARK: Configure
    func configure(with msg: ChatActivity.Message, onPdfTap: @escaping (String, String) -> Void) {
        messageLabel.text = msg.content.isEmpty ? nil : msg.content
        messageLabel.isHidden = msg.content.isEmpty
        timeLabel.text = msg.timestamp
        pdfTapHandler = onPdfTap

        if let fileName = msg.fileUrl, !fileName.isEmpty {
            let baseUrl  = Bundle.main.object(forInfoDictionaryKey: "BASE_URL") as? String ?? ""
            let cleanBase = baseUrl.hasSuffix("/") ? String(baseUrl.dropLast()) : baseUrl
            let fullUrl  = "\(cleanBase)/api/chats/file?path=\(fileName)"

            if fileName.lowercased().hasSuffix(".pdf") {
                photoView.isHidden    = true
                pdfContainer.isHidden = false
                pdfLabel.text         = fileName.components(separatedBy: "/").last
                pdfUrl  = fullUrl
                pdfName = fileName
            } else {
                pdfContainer.isHidden = true
                photoView.isHidden    = false
                loadImage(url: fullUrl, into: photoView)
            }
        } else {
            photoView.isHidden    = true
            pdfContainer.isHidden = true
        }
    }

    @objc private func didTapPdf() {
        guard let url = pdfUrl, let name = pdfName else { return }
        pdfTapHandler?(url, name)
    }
}

// ============================================================
// MARK: - IncomingCell  (mirrors item_chat_incoming.xml)
// ============================================================

class IncomingCell: UITableViewCell {

    static let reuseId = "IncomingCell"

    private var pdfTapHandler: ((String, String) -> Void)?
    private var pdfUrl:  String?
    private var pdfName: String?

    private let card: UIView = {
        let v = UIView()
        v.backgroundColor   = .white
        v.layer.cornerRadius = 16
        v.layer.shadowColor  = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.08
        v.layer.shadowOffset  = CGSize(width: 0, height: 2)
        v.layer.shadowRadius  = 4
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let photoView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode    = .scaleAspectFill
        iv.clipsToBounds  = true
        iv.layer.cornerRadius = 12
        iv.isHidden       = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let pdfContainer: UIView = {
        let v = UIView()
        v.backgroundColor   = UIColor.fromHex("#F5F5F5")
        v.layer.cornerRadius = 8
        v.isHidden = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let pdfIcon: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "doc.fill"))
        iv.tintColor = UIColor.fromHex("#D32F2F")
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let pdfLabel: UILabel = {
        let l = UILabel()
        l.text      = "Document.pdf"
        l.textColor = UIColor(named: "text_primary") ?? .darkText
        l.font      = .systemFont(ofSize: 14)
        l.numberOfLines = 1
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let messageLabel: UILabel = {
        let l = UILabel()
        l.textColor     = UIColor(named: "text_primary") ?? .darkText
        l.font          = .systemFont(ofSize: 16)
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let timeLabel: UILabel = {
        let l = UILabel()
        l.textColor = UIColor(named: "text_muted") ?? .gray
        l.font      = .systemFont(ofSize: 10)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private lazy var contentStack: UIStackView = {
        let s = UIStackView(arrangedSubviews: [photoView, pdfContainer, messageLabel, timeLabel])
        s.axis      = .vertical
        s.spacing   = 4
        s.alignment = .leading
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle  = .none
        build()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func build() {
        pdfContainer.addSubview(pdfIcon)
        pdfContainer.addSubview(pdfLabel)
        NSLayoutConstraint.activate([
            pdfIcon.leadingAnchor.constraint(equalTo: pdfContainer.leadingAnchor, constant: 8),
            pdfIcon.centerYAnchor.constraint(equalTo: pdfContainer.centerYAnchor),
            pdfIcon.widthAnchor.constraint(equalToConstant: 28),
            pdfIcon.heightAnchor.constraint(equalToConstant: 28),
            pdfLabel.leadingAnchor.constraint(equalTo: pdfIcon.trailingAnchor, constant: 8),
            pdfLabel.trailingAnchor.constraint(equalTo: pdfContainer.trailingAnchor, constant: -8),
            pdfLabel.topAnchor.constraint(equalTo: pdfContainer.topAnchor, constant: 8),
            pdfLabel.bottomAnchor.constraint(equalTo: pdfContainer.bottomAnchor, constant: -8),
        ])
        pdfContainer.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapPdf)))

        card.addSubview(contentStack)
        contentView.addSubview(card)

        NSLayoutConstraint.activate([
            photoView.widthAnchor.constraint(equalToConstant: 200),
            photoView.heightAnchor.constraint(equalToConstant: 200),

            contentStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
            contentStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            contentStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            contentStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -12),

            // Bubble on the left side
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            card.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -60),
        ])
    }

    func configure(with msg: ChatActivity.Message, onPdfTap: @escaping (String, String) -> Void) {
        messageLabel.text    = msg.content.isEmpty ? nil : msg.content
        messageLabel.isHidden = msg.content.isEmpty
        timeLabel.text = msg.timestamp
        pdfTapHandler  = onPdfTap

        if let fileName = msg.fileUrl, !fileName.isEmpty {
            let baseUrl   = Bundle.main.object(forInfoDictionaryKey: "BASE_URL") as? String ?? ""
            let cleanBase = baseUrl.hasSuffix("/") ? String(baseUrl.dropLast()) : baseUrl
            let fullUrl   = "\(cleanBase)/api/chats/file?path=\(fileName)"

            if fileName.lowercased().hasSuffix(".pdf") {
                photoView.isHidden    = true
                pdfContainer.isHidden = false
                pdfLabel.text         = fileName.components(separatedBy: "/").last
                pdfUrl  = fullUrl
                pdfName = fileName
            } else {
                pdfContainer.isHidden = true
                photoView.isHidden    = false
                loadImage(url: fullUrl, into: photoView)
            }
        } else {
            photoView.isHidden    = true
            pdfContainer.isHidden = true
        }
    }

    @objc private func didTapPdf() {
        guard let url = pdfUrl, let name = pdfName else { return }
        pdfTapHandler?(url, name)
    }
}

// ============================================================
// MARK: - Image Loading helper (replaces Coil + auth headers)
// ============================================================

/// Loads a chat image that requires Authorization + security headers.
private func loadImage(url urlString: String, into imageView: UIImageView) {
    guard let url = URL(string: urlString) else { return }

    let token = SecurePrefs().getAccessToken() ?? ""
    var request = URLRequest(url: url)
    request.addValue("Bearer \(token)",                           forHTTPHeaderField: "Authorization")
    request.addValue(DeviceSecurityHelper.getDeviceHash(),        forHTTPHeaderField: "X-Device-Hash")
    request.addValue(DeviceSecurityHelper.getAppSignatureHash(),  forHTTPHeaderField: "X-App-Signature")
    request.addValue("ios",                                        forHTTPHeaderField: "Platform")
    request.addValue("application/json",                           forHTTPHeaderField: "Accept")

    URLSession.shared.dataTask(with: request) { data, _, _ in
        guard let data, let image = UIImage(data: data) else { return }
        DispatchQueue.main.async { imageView.image = image }
    }.resume()
}

// ============================================================
// MARK: - UIColor convenience
// ============================================================



extension UIColor {
    static func fromHex(_ hex: String) -> UIColor {
        var cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        cleaned = cleaned.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&rgb)

        return UIColor(
            red: CGFloat((rgb >> 16) & 0xFF) / 255.0,
            green: CGFloat((rgb >> 8) & 0xFF) / 255.0,
            blue: CGFloat(rgb & 0xFF) / 255.0,
            alpha: 1.0
        )
    }
}
