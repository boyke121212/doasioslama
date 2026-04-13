import UIKit
import UserNotifications

class Boyke: UIViewController {

    private var loadingView: UIView?
    private var spinner: UIActivityIndicatorView?
    private static var lastTotalUnread: Int = -1
    private static var timer: Timer?
    private static var isPollingActive = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initLoading()
        requestNotificationPermission()
             createNotificationChannel()
        UNUserNotificationCenter.current().delegate = self
    }
    
    private func checkNewMessages() {
        let params: [String: String] = ["roleId": "9"]

        AuthManager(endpoint: "api/dokters").checkAuth(
            params: params,

            onSuccess: { json in
                let dataArray = json["data"] as? [[String: Any]] ?? []
                var currentTotalUnread = 0

                for obj in dataArray {
                    currentTotalUnread += obj["unread_count"] as? Int ?? 0
                }

                if Boyke.lastTotalUnread == -1 {
                    Boyke.lastTotalUnread = currentTotalUnread
                } else if currentTotalUnread > Boyke.lastTotalUnread {
                    self.showChatNotification("Ada pesan baru dari dokter")
                    Boyke.lastTotalUnread = currentTotalUnread
                } else if currentTotalUnread < Boyke.lastTotalUnread {
                    Boyke.lastTotalUnread = currentTotalUnread
                }
            },

            onLogout: { _ in
                Boyke.isPollingActive = false
            },

            onLoading: { _ in }
        )
    }
    
    func openPage(_ vc: UIViewController) {
        vc.modalPresentationStyle = .fullScreen
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }
        
        window.rootViewController = vc
        window.makeKeyAndVisible()
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
    private func startGlobalPolling() {
        guard !Boyke.isPollingActive else { return }

        Boyke.isPollingActive = true

        Boyke.timer = Timer.scheduledTimer(withTimeInterval: 15.0, repeats: true) { _ in
            self.checkNewMessages()
        }
    }

    private func stopGlobalPolling() {
        Boyke.timer?.invalidate()
        Boyke.timer = nil
        Boyke.isPollingActive = false
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { granted, error in
            
            print("PERMISSION:", granted)
        }
    }

    private func createNotificationChannel() {
        // iOS gak butuh channel kayak Android, kosong aja biar konsisten
    }

    private func showChatNotification(_ message: String) {
        print("🔥 NOTIF DIKIRIM")

        let content = UNMutableNotificationContent()
        content.title = "Doas Chat"
        content.body = message
        content.sound = .default

        // 🔥 WAJIB: pakai trigger (jangan nil)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startGlobalPolling()
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopGlobalPolling()
    }
}
extension Boyke: UNUserNotificationCenterDelegate {

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        completionHandler([.banner, .sound, .badge])
    }
}
