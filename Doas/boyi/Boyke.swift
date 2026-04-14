import UIKit
import Network
import UserNotifications

class Boyke: UIViewController {
    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "InternetMonitorboy")
    private var isConnected: Bool = false
    private var loadingView: UIView?
    private var spinner: UIActivityIndicatorView?
    private static var lastTotalUnread: Int = -1
    private static var timer: Timer?
    private static var isPollingActive = false
    private static var isShowingNetworkAlert = false
    override func viewDidLoad() {
        super.viewDidLoad()
        initLoading()
        requestNotificationPermission()
             createNotificationChannel()
        monitorInternet()
        UNUserNotificationCenter.current().delegate = self
    }
    
    private func checkNewMessages() {
        let token = SecurePrefs().getAccessToken()
           if token == nil || token?.isEmpty == true {
               Boyke.isPollingActive = false
               Boyke.timer?.invalidate()
               Boyke.timer = nil
               return
           }
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
    
//    func openPage(_ vc: UIViewController) {
//        vc.modalPresentationStyle = .fullScreen
//        
//        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
//              let window = windowScene.windows.first else { return }
//        
//        window.rootViewController = vc
//        window.makeKeyAndVisible()
//    }
    func back(){
        navigationController?.popViewController(animated: true)
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

    // Boyke.swift

    // Tambahkan deinit untuk memastikan monitor mati saat class dihancurkan
    deinit {
        monitor.cancel()
    }
    func monitorInternet() {
           monitor.pathUpdateHandler = { [weak self] path in
               guard let self = self else { return }
               
               DispatchQueue.main.async {
                   if path.status != .satisfied {
                       // 1. Matikan semua proses yang bikin berat/error
                       self.hideLoading()
                       
                       // 2. CEK: Jika sudah di Home, tampilkan alert saja. Jangan pindah halaman (mencegah loop)
                       let className = String(describing: type(of: self))
                       if className == "Home" {
                           self.showRefreshAlert()
                       } else {
                           // Jika di halaman lain (Profile/Chat), balik ke Home agar aman
                           print("Internet putus, balik ke Home...")
                           self.openPage(Home())
                       }
                   }
               }
           }
           monitor.start(queue: monitorQueue)
       }

    private func showRefreshAlert() {
           // Mencegah alert muncul bertumpuk-tumpuk
           guard !Boyke.isShowingNetworkAlert else { return }
           guard self.view.window != nil else { return }

           Boyke.isShowingNetworkAlert = true
           
           let alert = UIAlertController(
               title: "Koneksi Terputus",
               message: "Koneksi internet hilang. Silaakan klik Refresh jika internet sudah aktif kembali.",
               preferredStyle: .alert
           )

           let refreshAction = UIAlertAction(title: "Refresh", style: .default) { [weak self] _ in
               Boyke.isShowingNetworkAlert = false
               
               // Tampilkan loading sebagai indikasi proses dimulai
               self?.showLoading()
               
               // JEDA 3 DETIK sebelum mencoba memuat ulang
               // Ini memberi waktu bagi sistem iOS untuk menstabilkan koneksi
               DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                   print("Mencoba me-load ulang...")
                   // Pindah ke Home secara bersih (seperti saran Anda, me-load ulang state)
                   self?.openPage(Home())
               }
           }

           alert.addAction(refreshAction)
           self.present(alert, animated: true)
       }

    // Update fungsi openPage agar mematikan monitor lama

    func openPage(_ vc: UIViewController) {
        // MATIKAN monitor instance lama agar tidak terjadi zombie monitor di background
        monitor.cancel()
        
        vc.modalPresentationStyle = .fullScreen
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }
        
        window.rootViewController = vc
        window.makeKeyAndVisible()
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
