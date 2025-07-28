import AVFoundation
import UIKit

class CameraManager: ObservableObject {
    @Published var cameraSession: AVCaptureSession?
    @Published var cameraPosition: AVCaptureDevice.Position = .front
    @Published var cameraPermissionGranted = false
    @Published var cameraSessionReady = false
    @Published var showingPermissionAlert = false
    
    private var photoOutput: AVCapturePhotoOutput?
    private var movieOutput: AVCaptureMovieFileOutput?
    
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
            session.sessionPreset = .photo
            
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
                
                // Movie output for video recording
                let movieOutput = AVCaptureMovieFileOutput()
                if session.canAddOutput(movieOutput) {
                    session.addOutput(movieOutput)
                    print("Movie output added successfully")
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
        
        session.commitConfiguration()
    }
    
    func getPhotoOutput() -> AVCapturePhotoOutput? {
        return photoOutput
    }
    
    func getMovieOutput() -> AVCaptureMovieFileOutput? {
        return movieOutput
    }
} 