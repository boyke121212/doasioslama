import UIKit

class PreviewFotoActivity: Boyke, UIScrollViewDelegate {

    private let scrollView = UIScrollView()
    private let imageView = UIImageView()
    private let btTutup = UIButton(type: .system)

    var fotoUri: String?

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        loadImage()
    }

    // =========================
    // UI
    // =========================

    private func setupUI() {

        view.backgroundColor = UIColor.black.withAlphaComponent(0.8)

        // scroll view (zoom container)
        scrollView.frame = view.bounds
        scrollView.delegate = self
        scrollView.minimumZoomScale = 1
        scrollView.maximumZoomScale = 4
        view.addSubview(scrollView)

        // image
        imageView.frame = scrollView.bounds
        imageView.contentMode = .scaleAspectFit
        scrollView.addSubview(imageView)

        // close button
        btTutup.setImage(
            UIImage(systemName: "xmark"),
            for: .normal
        )

        btTutup.tintColor = .white
        btTutup.frame = CGRect(x: view.frame.width - 64, y: 60, width: 48, height: 48)

        btTutup.addTarget(self,
                          action: #selector(closePressed),
                          for: .touchUpInside)

        view.addSubview(btTutup)
    }

    // =========================
    // LOAD IMAGE
    // =========================

    private func loadImage() {

        guard let uri = fotoUri else { return }

        if uri.starts(with: "http") {

            loadRemoteImage(uri)

        } else {

            // file lokal
            let url = URL(fileURLWithPath: uri)

            if let img = UIImage(contentsOfFile: url.path) {
                imageView.image = img
            }
        }
    }

    // =========================
    // LOAD REMOTE (AUTH HEADER)
    // =========================

    private func loadRemoteImage(_ urlString: String) {

        guard let url = URL(string: urlString) else { return }

        var request = URLRequest(url: url)

        let prefs = SecurePrefs()

        request.setValue(
            "Bearer \(prefs.getAccessToken() ?? "")",
            forHTTPHeaderField: "Authorization"
        )
        request.setValue(
            DeviceSecurityHelper.getDeviceHash(),
            forHTTPHeaderField: "X-Device-Hash"
        )

        request.setValue(
            DeviceSecurityHelper.getAppSignatureHash(),
            forHTTPHeaderField: "X-App-Signature"
        )

        URLSession.shared.dataTask(with: request) { data, _, _ in

            guard let data = data else { return }

            DispatchQueue.main.async {

                self.imageView.image = UIImage(data: data)
            }

        }.resume()
    }

    // =========================
    // ZOOM (PhotoView replacement)
    // =========================

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }

    // =========================
    // CLOSE
    // =========================

    @objc private func closePressed() {
        dismiss(animated: true)
    }
}
