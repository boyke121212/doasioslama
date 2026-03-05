import UIKit
import AVFoundation
import CoreLocation
import LocalAuthentication

final class AbsensiManager: NSObject,
CLLocationManagerDelegate,
AVCapturePhotoCaptureDelegate {

    weak var activity: UIViewController?
    weak var previewView: UIView?

    // MARK: LOCATION

    private let locationManager = CLLocationManager()

    var lat: Double?
    var lon: Double?
    var accuracy: Double?
    var alamat: String = "Alamat tidak tersedia"
    private var lastAddressLocation: CLLocation?

    var onGpsStatusChanged: ((Double?) -> Void)?

    // MARK: CAMERA

    private let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()

    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var lensPosition: AVCaptureDevice.Position = .front

    private let cameraQueue = DispatchQueue(label: "camera.queue")

    // MARK: FILES

    var capturedFiles: [URL] = []
    private let maxFoto = 2

    private var previewCallback: ((URL, Int) -> Void)?

    init(activity: UIViewController, previewView: UIView) {
        self.activity = activity
        self.previewView = previewView
        super.init()
    }

    // MARK: BIOMETRIC

    func authenticate(onSuccess: @escaping () -> Void) {
        print("BIOMETRIC BYPASS")
        onSuccess()

//        let context = LAContext()
//
//        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) {
//
//            context.evaluatePolicy(
//                .deviceOwnerAuthenticationWithBiometrics,
//                localizedReason: "Konfirmasi absensi"
//            ) { success, _ in
//
//                DispatchQueue.main.async {
//                    if success {
//                        onSuccess()
//                    }
//                }
//            }
//
//        } else {
//            DispatchQueue.main.async { onSuccess() }
//        }
    }

    // MARK: PREPARE

    func prepare() {

        capturedFiles.removeAll()

        ensureCamera()
        ensureLocation()
    }

    // MARK: CAMERA START

    private func ensureCamera() {

        AVCaptureDevice.requestAccess(for: .video) { granted in

            DispatchQueue.main.async {

                if granted {
                    self.startCamera()
                }
            }
        }
    }

    func startCamera() {

    #if targetEnvironment(simulator)

        DispatchQueue.main.async {

            guard let previewView = self.previewView else { return }

            // dummy preview layer
            let img = UIImage(systemName: "person.crop.square.fill")!
            let imageView = UIImageView(image: img)
            imageView.contentMode = .scaleAspectFill
            imageView.frame = previewView.bounds

            previewView.addSubview(imageView)

            print("SIMULATOR CAMERA PREVIEW")
        }

    #else

        cameraQueue.async {

            self.session.beginConfiguration()

            for input in self.session.inputs {
                self.session.removeInput(input)
            }

            guard let device =
            AVCaptureDevice.default(.builtInWideAngleCamera,
                                    for: .video,
                                    position: self.lensPosition) else {
                print("Camera device not found")
                return
            }

            guard let input = try? AVCaptureDeviceInput(device: device) else {
                print("Camera input error")
                return
            }

            if self.session.canAddInput(input) {
                self.session.addInput(input)
            }

            if !self.session.outputs.contains(self.photoOutput) {
                if self.session.canAddOutput(self.photoOutput) {
                    self.session.addOutput(self.photoOutput)
                }
            }

            self.session.commitConfiguration()

            DispatchQueue.main.async {

                guard let previewView = self.previewView else { return }

                if self.previewLayer == nil {

                    let layer = AVCaptureVideoPreviewLayer(session: self.session)
                    layer.videoGravity = .resizeAspectFill
                    layer.frame = previewView.bounds

                    previewView.layer.insertSublayer(layer, at: 0)

                    self.previewLayer = layer
                }

                self.previewLayer?.frame = previewView.bounds

                if !self.session.isRunning {
                    self.session.startRunning()
                    print("CAMERA SESSION STARTED")
                }
            }
        }

    #endif
    }

    func updatePreviewFrame() {

        guard let previewView = previewView,
              let previewLayer = previewLayer else { return }

        previewLayer.frame = previewView.bounds
    }

    // MARK: CAPTURE

    
    func capture(onPreview: @escaping (URL, Int) -> Void) {

        if capturedFiles.count >= maxFoto {
            toast("Maksimal 2 foto")
            return
        }

        if lat == nil || lon == nil {
            toast("Lokasi belum tersedia")
            return
        }

        previewCallback = onPreview

    #if targetEnvironment(simulator)

        print("SIMULATOR CAPTURE")

        let file = createImageFile()

        // dummy foto ukuran besar
        let size = CGSize(width: 1080, height: 1440)

        let renderer = UIGraphicsImageRenderer(size: size)

        let img = renderer.image { ctx in
            UIColor.darkGray.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }

        let data = img.jpegData(compressionQuality: 1.0)!
        try? data.write(to: file)

        // proses melalui ImageProcessor
        let processedFile = ImageProcessor.processAndSave(
            file: file,
            isFrontCamera: lensPosition == .front,
            alamat: alamat,
            lat: lat,
            lon: lon,
            quality: 50
        )

        capturedFiles.append(processedFile)

        DispatchQueue.main.async {
            onPreview(processedFile, self.capturedFiles.count)
        }

    #else

        guard session.isRunning else {
            print("Camera session not running → starting camera")
            startCamera()
            return
        }

        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)

    #endif
    }

    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {

        if let error = error {
            print("Photo capture error:", error)
            return
        }

        guard let data = photo.fileDataRepresentation() else {
            print("Photo data kosong")
            return
        }

        // ===== SIMPAN FILE CAMERA DULU =====
        let file = createImageFile()

        do {
            try data.write(to: file)
        } catch {
            print("Save camera file error:", error)
            return
        }

        // ===== PROCESS VIA IMAGEPROCESSOR =====
        let processedFile = ImageProcessor.processAndSave(
            file: file,
            isFrontCamera: lensPosition == .front,
            alamat: "Alamat tidak tersedia",
            lat: lat,
            lon: lon,
            quality: 50
        )

        capturedFiles.append(processedFile)

        DispatchQueue.main.async {
            self.previewCallback?(processedFile, self.capturedFiles.count)
        }
    }

    // MARK: SWITCH CAMERA

    func switchCamera() {

    #if targetEnvironment(simulator)

        print("Simulator hanya memiliki satu kamera")

    #else

        lensPosition = lensPosition == .front ? .back : .front

        cameraQueue.async {

            self.session.beginConfiguration()

            // hapus semua input lama
            for input in self.session.inputs {
                self.session.removeInput(input)
            }

            guard let device =
            AVCaptureDevice.default(.builtInWideAngleCamera,
                                    for: .video,
                                    position: self.lensPosition) else {
                print("Camera device not found")
                return
            }

            guard let input = try? AVCaptureDeviceInput(device: device) else {
                print("Camera input error")
                return
            }

            if self.session.canAddInput(input) {
                self.session.addInput(input)
            }

            self.session.commitConfiguration()
        }

    #endif
    }

    // MARK: LOCATION

    func ensureLocation() {

        if locationManager.authorizationStatus == .notDetermined {

            locationManager.requestWhenInUseAuthorization()

        } else {

            requestLocationInternal()
        }
    }
    
    func requestLocationInternal() {

        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest

        locationManager.startUpdatingLocation()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {

        if manager.authorizationStatus == .authorizedWhenInUse ||
           manager.authorizationStatus == .authorizedAlways {

            manager.startUpdatingLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager,
                         didUpdateLocations locations: [CLLocation]) {

        guard let loc = locations.last else { return }

        lat = loc.coordinate.latitude
        lon = loc.coordinate.longitude
        accuracy = loc.horizontalAccuracy

        onGpsStatusChanged?(accuracy)

        // ===== sama seperti Android =====

        let currentLoc = CLLocation(latitude: lat!, longitude: lon!)

        let shouldUpdateAddress =
            lastAddressLocation == nil ||
            lastAddressLocation!.distance(from: currentLoc) > 30

        if shouldUpdateAddress {

            lastAddressLocation = currentLoc

            resolveAddressOnline(lat: lat!, lon: lon!) { address in
                self.alamat = address
            }
        }
    }
    
    func resolveAddressOnline(
        lat: Double,
        lon: Double,
        onResult: @escaping (String) -> Void
    ) {

        let urlString =
        "https://nominatim.openstreetmap.org/reverse" +
        "?format=jsonv2" +
        "&lat=\(lat)&lon=\(lon)"

        guard let url = URL(string: urlString) else {
            onResult("Alamat tidak tersedia")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        // sama seperti header Android
        request.setValue("DOAS-App", forHTTPHeaderField: "User-Agent")

        URLSession.shared.dataTask(with: request) { data, response, error in

            if error != nil {
                DispatchQueue.main.async {
                    onResult("Alamat tidak tersedia")
                }
                return
            }

            guard let data = data else {
                DispatchQueue.main.async {
                    onResult("Alamat tidak tersedia")
                }
                return
            }

            do {

                if let json =
                    try JSONSerialization.jsonObject(with: data)
                    as? [String: Any] {

                    let result =
                        json["display_name"] as? String
                        ?? "Alamat tidak tersedia"

                    DispatchQueue.main.async {
                        onResult(result)
                    }

                } else {

                    DispatchQueue.main.async {
                        onResult("Alamat tidak tersedia")
                    }
                }

            } catch {

                DispatchQueue.main.async {
                    onResult("Alamat tidak tersedia")
                }
            }

        }.resume()
    }

    // MARK: STOP

    func stop() {

        cameraQueue.async {

            if self.session.isRunning {
                self.session.stopRunning()
            }
        }

        locationManager.stopUpdatingLocation()
    }

    // MARK: FILE

    private func createImageFile() -> URL {

        let dir = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0].appendingPathComponent("DOAS")

        if !FileManager.default.fileExists(atPath: dir.path) {

            try? FileManager.default.createDirectory(
                at: dir,
                withIntermediateDirectories: true
            )
        }

        let filename = "CameraX_\(Int(Date().timeIntervalSince1970)).jpg"

        return dir.appendingPathComponent(filename)
    }

    // MARK: TOAST

    private func toast(_ msg: String) {

        guard let vc = activity else { return }

        let alert = UIAlertController(title: nil,
                                      message: msg,
                                      preferredStyle: .alert)

        vc.present(alert, animated: true)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            alert.dismiss(animated: true)
        }
    }
}
