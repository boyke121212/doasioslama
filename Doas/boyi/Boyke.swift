import UIKit

class Boyke: UIViewController {

    private var loadingView: UIView?
    private var spinner: UIActivityIndicatorView?

    override func viewDidLoad() {
        super.viewDidLoad()
        initLoading()
    }

    private func initLoading() {

        let overlay = UIView(frame: view.bounds)
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.35)
        overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        overlay.isHidden = true

        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .white
        indicator.center = overlay.center
        indicator.hidesWhenStopped = true

        overlay.addSubview(indicator)
        view.addSubview(overlay)

        loadingView = overlay
        spinner = indicator
    }

    func showLoading() {

        guard let overlay = loadingView else { return }

        view.bringSubviewToFront(overlay)
        overlay.isHidden = false
        spinner?.startAnimating()

        view.isUserInteractionEnabled = false
    }

    func hideLoading() {

        spinner?.stopAnimating()
        loadingView?.isHidden = true

        view.isUserInteractionEnabled = true
    }
}
