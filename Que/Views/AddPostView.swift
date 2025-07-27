import SwiftUI
import AVFoundation
import PhotosUI

struct AddPostView: View {
    @ObservedObject var viewModel: AddPostViewModel
    @Environment(\.dismiss) private var dismiss
    
    // Camera states
    @State private var cameraSession: AVCaptureSession?
    @State private var cameraPosition: AVCaptureDevice.Position = .front
    @State private var cameraPermissionGranted = false
    @State private var showingPermissionAlert = false
    @State private var cameraSessionReady = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Live camera background
                if cameraPermissionGranted && cameraSessionReady {
                    LiveCameraView(session: cameraSession)
                        .ignoresSafeArea()
                } else {
                    Color.black
                        .ignoresSafeArea()
                }
                
                // Camera overlay UI
                VStack {
                    // Top bar
                    HStack {
                        Button("İptal") {
                            dismiss()
                        }
                        .foregroundColor(.white)
                        .font(.system(size: 18, weight: .medium))
                        
                        Spacer()
                        
                        // Post type selector will be added here
                        Text("Soru")
                            .foregroundColor(.white)
                            .font(.system(size: 18, weight: .semibold))
                        
                        Spacer()
                        
                        Button("Ayarlar") {
                            // Camera settings will be added here
                        }
                        .foregroundColor(.white)
                        .font(.system(size: 18, weight: .medium))
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    Spacer()
                    
                    // Bottom controls
                    HStack {
                        Spacer()
                        
                        // Gallery button
                        Button(action: {
                            // Gallery picker will be added here
                        }) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 60, height: 60)
                                .overlay(
                                    Image(systemName: "photo.on.rectangle")
                                        .foregroundColor(.white)
                                        .font(.system(size: 24))
                                )
                        }
                        
                        Spacer()
                        
                        // Capture button
                        Button(action: {
                            // Photo capture will be added here
                        }) {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.3), lineWidth: 4)
                                        .frame(width: 90, height: 90)
                                )
                        }
                        
                        Spacer()
                        
                        // Camera switch button
                        Button(action: {
                            switchCamera()
                        }) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 60, height: 60)
                                .overlay(
                                    Image(systemName: "camera.rotate")
                                        .foregroundColor(.white)
                                        .font(.system(size: 24))
                                )
                        }
                        
                        Spacer()
                    }
                    .padding(.bottom, 50)
                }
            }
        }
        .onAppear {
            checkCameraPermission()
        }
        .alert("Kamera İzni Gerekli", isPresented: $showingPermissionAlert) {
            Button("Ayarlar") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            Button("İptal", role: .cancel) { }
        } message: {
            Text("Kamera erişimi için ayarlardan izin vermeniz gerekiyor.")
        }
    }
    
    // MARK: - Camera Functions
    
    private func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            cameraPermissionGranted = true
            setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    cameraPermissionGranted = granted
                    if granted {
                        setupCamera()
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
            
            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: cameraPosition) else { 
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
                
                let photoOutput = AVCapturePhotoOutput()
                if session.canAddOutput(photoOutput) {
                    session.addOutput(photoOutput)
                    print("Photo output added successfully")
                }
                
                session.startRunning()
                print("Camera session started running")
                
                DispatchQueue.main.async {
                    self.cameraSession = session
                    self.cameraSessionReady = true
                    print("Camera session assigned to UI and ready")
                }
                
            } catch {
                print("Camera setup error: \(error)")
            }
        }
    }
    
    private func switchCamera() {
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
}

// MARK: - Live Camera View
struct LiveCameraView: UIViewRepresentable {
    let session: AVCaptureSession?
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .black
        
        guard let session = session else { 
            print("LiveCameraView: No session provided")
            return view 
        }
        
        print("LiveCameraView: Creating preview layer with session")
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        
        view.layer.addSublayer(previewLayer)
        
        print("LiveCameraView created with session: \(session)")
        print("Preview layer added to view with frame: \(previewLayer.frame)")
        
        // View'ın layout'u değiştiğinde preview layer'ı güncelle
        view.setNeedsLayout()
        view.layoutIfNeeded()
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            // Tüm sublayer'ları kontrol et
            for sublayer in uiView.layer.sublayers ?? [] {
                if let previewLayer = sublayer as? AVCaptureVideoPreviewLayer {
                    let newFrame = uiView.bounds
                    print("Preview layer frame check: \(newFrame)")
                    
                    if newFrame.width > 0 && newFrame.height > 0 {
                        if previewLayer.frame != newFrame {
                            previewLayer.frame = newFrame
                            print("Preview layer frame updated: \(newFrame)")
                        }
                    } else {
                        print("View bounds are zero, waiting for layout...")
                        // Layout completion'ı bekleyelim
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            let updatedFrame = uiView.bounds
                            if updatedFrame.width > 0 && updatedFrame.height > 0 {
                                previewLayer.frame = updatedFrame
                                print("Preview layer frame set after delay: \(previewLayer.frame)")
                            }
                        }
                    }
                    return
                }
            }
            print("LiveCameraView: No preview layer found in updateUIView")
        }
    }
}

#Preview {
    AddPostView(viewModel: AddPostViewModel())
} 
