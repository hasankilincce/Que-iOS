import AVFoundation
import UIKit

class CameraManager: ObservableObject {
    @Published var cameraSession: AVCaptureSession?
    @Published var cameraPosition: AVCaptureDevice.Position = .front
    @Published var cameraPermissionGranted = false
    @Published var cameraSessionReady = false
    @Published var showingPermissionAlert = false
    @Published var flashMode: AVCaptureDevice.FlashMode = .off
    
    private let userDefaults = UserDefaults.standard
    private let flashModeKey = "CameraFlashMode"
    
    private var photoOutput: AVCapturePhotoOutput?
    private var movieOutput: AVCaptureMovieFileOutput?
    
    init() {
        loadFlashMode()
    }
    
    func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            cameraPermissionGranted = true
            setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    self.cameraPermissionGranted = granted
                    if granted {
                        self.setupCamera()
                    }
                }
            }
        case .denied, .restricted:
            cameraPermissionGranted = false
            showingPermissionAlert = true
        @unknown default:
            cameraPermissionGranted = false
        }
    }
    
    private func setupCamera() {
        print("Setting up camera...")
        DispatchQueue.global(qos: .userInitiated).async {
            let session = AVCaptureSession()
            
            // 9:16 video kayıt için özel ayarlar
            if session.canSetSessionPreset(.hd1920x1080) {
                session.sessionPreset = .hd1920x1080
                print("📹 Using HD 1920x1080 preset for 9:16 video recording")
            } else if session.canSetSessionPreset(.high) {
                session.sessionPreset = .high
                print("📹 Using high quality preset for video recording")
            }
            
            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: self.cameraPosition) else { 
                print("Camera device not found")
                return 
            }
            
            print("Camera device found: \(device)")
            
            do {
                let input = try AVCaptureDeviceInput(device: device)
                if session.canAddInput(input) {
                    session.addInput(input)
                    print("Camera input added successfully")
                }
                
                // Photo output
                let photoOutput = AVCapturePhotoOutput()
                if session.canAddOutput(photoOutput) {
                    session.addOutput(photoOutput)
                    print("Photo output added successfully")
                    
                    if photoOutput.availablePhotoCodecTypes.contains(.jpeg) {
                        print("JPEG photo capture is supported")
                    } else {
                        print("JPEG photo capture is NOT supported")
                    }
                    
                    print("Photo output connections: \(photoOutput.connections)")
                } else {
                    print("Failed to add photo output to session")
                }
                
                // Movie output for video recording with 9:16 optimization
                let movieOutput = AVCaptureMovieFileOutput()
                if session.canAddOutput(movieOutput) {
                    session.addOutput(movieOutput)
                    print("Movie output added successfully")
                    
                    // Video connection ayarları - 9:16 için optimize edilmiş
                    if let connection = movieOutput.connection(with: .video) {
                        if connection.isVideoOrientationSupported {
                            connection.videoOrientation = .portrait
                            print("📹 Video orientation set to portrait for 9:16 recording")
                        }
                        if connection.isVideoStabilizationSupported {
                            connection.preferredVideoStabilizationMode = .auto
                            print("📹 Video stabilization enabled")
                        }
                        if connection.isVideoMirroringSupported {
                            connection.isVideoMirrored = (self.cameraPosition == .front)
                            print("📹 Video mirroring set for front camera")
                        }
                        
                        // 9:16 aspect ratio için özel ayarlar
                        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: self.cameraPosition) {
                            print("📹 Device format: \(device.activeFormat.formatDescription)")
                            print("📹 Supported video dimensions: \(device.activeFormat.supportedMaxPhotoDimensions)")
                            
                            // 9:16 aspect ratio için en uygun formatı seç
                            let formats = device.formats
                            print("📹 Available formats count: \(formats.count)")
                            
                            // Portrait video için optimize edilmiş format ara
                            for format in formats {
                                let dimensions = format.supportedMaxPhotoDimensions
                                for dimension in dimensions {
                                    let ratio = dimension.width / dimension.height
                                    if abs(Double(ratio) - 9.0/16.0) < 0.1 { // 9:16 oranına yakın
                                        print("📹 Found 9:16 compatible format: \(dimension.width) x \(dimension.height)")
                                    }
                                }
                            }
                        }
                    }
                } else {
                    print("Failed to add movie output to session")
                }
                
                session.startRunning()
                print("Camera session started running")
                
                DispatchQueue.main.async {
                    self.cameraSession = session
                    self.photoOutput = photoOutput
                    self.movieOutput = movieOutput
                    self.cameraSessionReady = true
                    print("Camera session assigned to UI and ready")
                }
                
            } catch {
                print("Camera setup error: \(error)")
            }
        }
    }
    
    func switchCamera() {
        guard let session = cameraSession else { return }
        
        session.beginConfiguration()
        
        // Remove existing input
        if let existingInput = session.inputs.first {
            session.removeInput(existingInput)
        }
        
        // Switch camera position
        cameraPosition = cameraPosition == .back ? .front : .back
        
        // Add new input
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: cameraPosition) else { return }
        
        do {
            let input = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(input) {
                session.addInput(input)
            }
        } catch {
            print("Camera switch error: \(error)")
        }
        
        // Video connection ayarlarını güncelle - 9:16 için optimize edilmiş
        if let movieOutput = movieOutput {
            if let connection = movieOutput.connection(with: .video) {
                if connection.isVideoOrientationSupported {
                    connection.videoOrientation = .portrait
                    print("📹 Video orientation updated to portrait for 9:16 recording")
                }
                if connection.isVideoStabilizationSupported {
                    connection.preferredVideoStabilizationMode = .auto
                    print("📹 Video stabilization updated for 9:16 recording")
                }
                if connection.isVideoMirroringSupported {
                    connection.isVideoMirrored = (cameraPosition == .front)
                    print("📹 Video mirroring updated for front camera")
                }
            }
        }
        

        
        session.commitConfiguration()
    }
    
    func getPhotoOutput() -> AVCapturePhotoOutput? {
        return photoOutput
    }
    
    func getMovieOutput() -> AVCaptureMovieFileOutput? {
        return movieOutput
    }
    
    func getCurrentDevice() -> AVCaptureDevice? {
        return AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: cameraPosition)
    }
    
    // Flaş modunu değiştir
    func toggleFlashMode() {
        switch flashMode {
        case .off:
            flashMode = .on
        case .on:
            flashMode = .off
        @unknown default:
            flashMode = .off
        }
        saveFlashMode()
        print("Flash mode changed to: \(flashMode)")
    }
    
    // Flaş modunu UserDefaults'a kaydet
    private func saveFlashMode() {
        let flashModeValue: Int
        switch flashMode {
        case .off:
            flashModeValue = 0
        case .on:
            flashModeValue = 1
        @unknown default:
            flashModeValue = 0
        }
        userDefaults.set(flashModeValue, forKey: flashModeKey)
    }
    
    // Flaş modunu UserDefaults'tan yükle
    private func loadFlashMode() {
        let flashModeValue = userDefaults.integer(forKey: flashModeKey)
        switch flashModeValue {
        case 0:
            flashMode = .off
        case 1:
            flashMode = .on
        default:
            flashMode = .off // Varsayılan değer
        }
    }
    
    // Flaş modu için icon adı
    var flashModeIcon: String {
        switch flashMode {
        case .off:
            return "bolt.slash"
        case .on:
            return "bolt.fill"
        @unknown default:
            return "bolt.slash"
        }
    }
    
    // Flaş modu için açıklama
    var flashModeDescription: String {
        switch flashMode {
        case .off:
            return "Flaş Kapalı"
        case .on:
            return "Flaş Açık"
        @unknown default:
            return "Flaş Kapalı"
        }
    }
} 
