import UIKit
import PDFKit
import CoreLocation
import Network

final class Auto {
    
    // MARK: =========================
    // AUTO SLIDE (ViewPager → UIScrollView / UIPageViewController)
    // =========================
    
    static func autoSlide(pageControl: UIPageControl,
                          scrollView: UIScrollView,
                          size: Int) {
        
        guard size > 0 else { return }
        
        var index = 0
        
        Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { timer in
            index = (index + 1) % size
            let x = CGFloat(index) * scrollView.frame.width
            scrollView.setContentOffset(CGPoint(x: x, y: 0), animated: true)
            pageControl.currentPage = index
        }
    }
    
    
    // MARK: =========================
    // DOWNLOAD PDF (HttpURLConnection → URLSession)
    // =========================
    
    static func downloadPdfWithAuth(
        url: String,
        fileName: String,
        viewController: UIViewController
    ) {
        
        guard let token = SecurePrefs().getAccessToken() else {
            showAlert(vc: viewController, message: "Token tidak ditemukan")
            return
        }
        
        guard let requestURL = URL(string: url) else { return }
        
        var request = URLRequest(url: requestURL)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(DeviceSecurityHelper.getDeviceHash(),
                         forHTTPHeaderField: "X-Device-Hash")
        request.setValue(DeviceSecurityHelper.getAppSignatureHash(),
                         forHTTPHeaderField: "X-App-Signature")
        
        let task = URLSession.shared.downloadTask(with: request) { location, response, error in
            
            if let error = error {
                DispatchQueue.main.async {
                    showAlert(vc: viewController, message: "Download gagal: \(error.localizedDescription)")
                }
                return
            }
            
            guard let location = location else { return }
            
            do {
                let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let destination = docs.appendingPathComponent(fileName)
                
                if FileManager.default.fileExists(atPath: destination.path) {
                    try FileManager.default.removeItem(at: destination)
                }
                
                try FileManager.default.moveItem(at: location, to: destination)
                
                DispatchQueue.main.async {
                    showAlert(vc: viewController, message: "PDF tersimpan di Documents")
                }
                
            } catch {
                DispatchQueue.main.async {
                    showAlert(vc: viewController, message: "Gagal menyimpan file")
                }
            }
        }
        
        task.resume()
    }
    
    
    // MARK: =========================
    // OPEN PDF
    // =========================
    
    static func openPdf(from url: URL, in vc: UIViewController) {
        let pdfVC = UIViewController()
        let pdfView = PDFView(frame: pdfVC.view.bounds)
        pdfView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        pdfView.document = PDFDocument(url: url)
        pdfVC.view.addSubview(pdfView)
        vc.present(pdfVC, animated: true)
    }
    
    
    // MARK: =========================
    // CLEAN TEMP PHOTOS
    // =========================
    
    static func cleanTempPhotos() {
        
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("DOAS")
        
        if FileManager.default.fileExists(atPath: dir.path) {
            do {
                let files = try FileManager.default.contentsOfDirectory(at: dir,
                                                                        includingPropertiesForKeys: nil)
                for file in files {
                    try? FileManager.default.removeItem(at: file)
                }
            } catch { }
        }
    }
    
    
    // MARK: =========================
    // INTERNET CHECK
    // =========================
    
    static func isInternetAvailable() -> Bool {

            let monitor = NWPathMonitor()
            let queue = DispatchQueue(label: "InternetMonitor")

            var isAvailable = false
            let semaphore = DispatchSemaphore(value: 0)

            monitor.pathUpdateHandler = { path in
                isAvailable = path.status == .satisfied
                monitor.cancel()
                semaphore.signal()
            }

            monitor.start(queue: queue)
            semaphore.wait()

            return isAvailable
        }
    
    // MARK: =========================
    // LOAD FOTO (Coil → URLSession + header)
    // =========================
    
    static func loadFoto(
        imageView: UIImageView,
        file: String,
        tanggal: String,
        baseURL: String
    ) {
        
        guard let token = SecurePrefs().getAccessToken() else { return }
        
        let folderPath = tanggal.replacingOccurrences(of: "-", with: "/")
        let fullPath = "\(folderPath)/\(file)"
        let encodedPath = fullPath.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        let urlString = baseURL + "api/media/absensi?file=" + encodedPath
        
        guard let url = URL(string: urlString) else { return }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(DeviceSecurityHelper.getDeviceHash(),
                         forHTTPHeaderField: "X-Device-Hash")
        request.setValue(DeviceSecurityHelper.getAppSignatureHash(),
                         forHTTPHeaderField: "X-App-Signature")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                DispatchQueue.main.async {
                    imageView.image = UIImage(data: data)
                }
            }
        }.resume()
    }
    
    
    // MARK: =========================
    // GET ADDRESS FROM LAT LNG
    // =========================
    
    static func getAddressFromLatLng(
        lat: Double,
        lon: Double,
        callback: @escaping (String) -> Void
    ) {
        let location = CLLocation(latitude: lat, longitude: lon)
        CLGeocoder().reverseGeocodeLocation(location) { placemarks, error in
            
            if let placemark = placemarks?.first {
                let address = [
                    placemark.name,
                    placemark.locality,
                    placemark.administrativeArea,
                    placemark.country
                ].compactMap { $0 }.joined(separator: ", ")
                
                callback(address)
            } else {
                callback("Alamat tidak ditemukan")
            }
        }
    }
    
    
    // MARK: =========================
    // ALERT HELPER
    // =========================
    
    private static func showAlert(vc: UIViewController, message: String) {
        let alert = UIAlertController(title: "Info",
                                      message: message,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        vc.present(alert, animated: true)
    }
}
