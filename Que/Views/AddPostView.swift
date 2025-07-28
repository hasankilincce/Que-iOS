import SwiftUI
import AVFoundation
import PhotosUI

struct AddPostView: View {
    @ObservedObject var viewModel: AddPostViewModel
    @ObservedObject var homeViewModel: HomeViewModel
    
    // Camera states
    @State private var cameraSession: AVCaptureSession?
    @State private var cameraPosition: AVCaptureDevice.Position = .front
    @State private var cameraPermissionGranted = false
    @State private var showingPermissionAlert = false
    @State private var cameraSessionReady = false
    
    // Capture states
    @State private var photoOutput: AVCapturePhotoOutput?
    @State private var movieOutput: AVCaptureMovieFileOutput?
    @State private var isRecording = false
    @State private var recordingStartTime: Date?
    @State private var recordingTimer: Timer?
    @State private var recordingDuration: TimeInterval = 0
    
    // Captured media states
    @State private var capturedImage: UIImage?
    @State private var capturedVideoURL: URL?
    @State private var showingCapturedMedia = false
    
    // Delegate retention
    @State private var photoCaptureDelegate: PhotoCaptureDelegate?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background - either live camera or captured media
                if showingCapturedMedia {
                    if let image = capturedImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .clipped()
                            .ignoresSafeArea()
                    } else if let videoURL = capturedVideoURL {
                        // Video player will be added here
                        Color.black
                            .ignoresSafeArea()
                    }
                } else if cameraPermissionGranted && cameraSessionReady {
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
                            if showingCapturedMedia {
                                // Return to camera
                                showingCapturedMedia = false
                                capturedImage = nil
                                capturedVideoURL = nil
                            } else {
                                homeViewModel.selectTab(.home)
                            }
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
                    
                    // Recording indicator
                    if isRecording {
                        HStack {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 12, height: 12)
                                .scaleEffect(recordingDuration.truncatingRemainder(dividingBy: 1) < 0.5 ? 1.0 : 0.7)
                                .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: recordingDuration)
                            
                            Text(String(format: "%.1f", recordingDuration))
                                                .foregroundColor(.white)
                                .font(.system(size: 16, weight: .medium))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(20)
                    }
                    
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
                        
                        // Capture button with long press gesture
                        Button(action: {
                            if showingCapturedMedia {
                                // Use captured media
                                useCapturedMedia()
                            } else {
                                // Single tap for photo
                                capturePhoto()
                            }
                        }) {
                            ZStack {
                                Circle()
                                    .fill(isRecording ? Color.red : Color.white)
                                    .frame(width: 80, height: 80)
                                    .overlay(
                                        Circle()
                                            .stroke(isRecording ? Color.red.opacity(0.3) : Color.white.opacity(0.3), lineWidth: 4)
                                            .frame(width: 90, height: 90)
                                    )
                                
                                if isRecording {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.white)
                                        .frame(width: 32, height: 32)
                                } else if showingCapturedMedia {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.black)
                                        .font(.system(size: 32, weight: .bold))
                                }
                            }
                        }
                        .simultaneousGesture(
                            LongPressGesture(minimumDuration: 0.5)
                                .onChanged { _ in
                                    if !showingCapturedMedia {
                                        startVideoRecording()
                                    }
                                }
                                .onEnded { _ in
                                    if !showingCapturedMedia {
                                        stopVideoRecording()
                                    }
                                }
                        )
                        
                        Spacer()
                        
                        // Camera switch button
                        Button(action: {
                            if !showingCapturedMedia {
                                switchCamera()
                            }
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
                        .disabled(showingCapturedMedia)
                        
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
                
                // Photo output
                let photoOutput = AVCapturePhotoOutput()
                if session.canAddOutput(photoOutput) {
                    session.addOutput(photoOutput)
                    print("Photo output added successfully")
                    
                    // Check if photo capture is supported
                    if photoOutput.availablePhotoCodecTypes.contains(.jpeg) {
                        print("JPEG photo capture is supported")
                    } else {
                        print("JPEG photo capture is NOT supported")
                    }
                    
                    // Check if photo capture is ready
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
    
    // MARK: - Capture Functions
    
    private func capturePhoto() {
        guard let photoOutput = photoOutput else { 
            print("Photo output is nil")
            return 
        }
        
        print("Starting photo capture...")
        
        // ➊: capturePhoto'dan önce bağlantı orientation'ını belirleyelim
        if let conn = photoOutput.connection(with: .video),
           conn.isVideoOrientationSupported {
                // Sabit portre modundaysanız:
                conn.videoOrientation = .portrait
            
                // front-kameradaysak yatayda çevir (ayna efekti)
                if conn.isVideoMirroringSupported {
                    conn.isVideoMirrored = (cameraPosition == .front)
                }
                
                // Eğer dinamik olarak UIDevice'ten okumak isterseniz:
                // conn.videoOrientation = currentVideoOrientation()
                
                print("Video orientation set to: \(conn.videoOrientation.rawValue)")
        }
        
        print("Photo output available codecs: \(photoOutput.availablePhotoCodecTypes)")
        
        let settings = AVCapturePhotoSettings()
        settings.flashMode = .auto
        
        // Check if settings are valid
        print("Photo settings created: \(settings)")
        
        let delegate = PhotoCaptureDelegate(completion: { image in
            DispatchQueue.main.async {
                print("Photo capture completion called with image: \(image != nil)")
                if let image = image {
                    self.capturedImage = image
                    self.showingCapturedMedia = true
                    print("Photo captured successfully and set to UI")
                } else {
                    print("Photo capture failed - no image received")
                }
            }
        }, cameraPosition: cameraPosition)
        
        // Delegate'i retain etmek için saklayalım
        photoCaptureDelegate = delegate
        
        print("About to call capturePhoto with delegate: \(delegate)")
        print("Photo output connections before capture: \(photoOutput.connections)")
        
        photoOutput.capturePhoto(with: settings, delegate: delegate)
        print("capturePhoto called successfully")
    }
    
    // Opsiyonel yardımcı metod, eğer UIDevice orientation'a göre çekim yapmak isterseniz:
    private func currentVideoOrientation() -> AVCaptureVideoOrientation {
        switch UIDevice.current.orientation {
        case .portrait:           return .portrait
        case .landscapeLeft:      return .landscapeRight
        case .landscapeRight:     return .landscapeLeft
        case .portraitUpsideDown: return .portraitUpsideDown
        default:                  return .portrait
        }
    }
    
    private func useCapturedMedia() {
        if let image = capturedImage {
            viewModel.setBackgroundImage(image)
            print("Photo saved to viewModel")
            // Navigate to post creation or show success message
            homeViewModel.selectTab(.home)
        } else if let videoURL = capturedVideoURL {
            viewModel.setBackgroundVideo(videoURL)
            print("Video saved to viewModel")
            // Navigate to post creation or show success message
            homeViewModel.selectTab(.home)
        }
    }
    
    private func startVideoRecording() {
        guard let movieOutput = movieOutput, !isRecording else { return }
        
        // Check if we can record
        guard movieOutput.isRecording == false else { return }
        
        // Get documents directory for temporary video file
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let videoName = "temp_video_\(Date().timeIntervalSince1970).mov"
        let videoURL = documentsPath.appendingPathComponent(videoName)
        
        // Start recording
        movieOutput.startRecording(to: videoURL, recordingDelegate: VideoRecordingDelegate { success, videoURL in
                            DispatchQueue.main.async {
                if success {
                    print("Video recording started successfully")
                    self.isRecording = true
                    self.recordingStartTime = Date()
                    self.startRecordingTimer()
                }
                
                // Video recording finished, save to viewModel
                if let videoURL = videoURL {
                    self.capturedVideoURL = videoURL
                    self.showingCapturedMedia = true
                    print("Video saved to viewModel: \(videoURL)")
                }
            }
        })
    }
    
    private func stopVideoRecording() {
        guard let movieOutput = movieOutput, isRecording else { return }
        
        movieOutput.stopRecording()
        isRecording = false
        recordingTimer?.invalidate()
        recordingTimer = nil
        recordingDuration = 0
        print("Video recording stopped")
    }
    
    private func startRecordingTimer() {
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            if let startTime = recordingStartTime {
                recordingDuration = Date().timeIntervalSince(startTime)
                
                // Stop recording if max duration reached (15 seconds)
                if recordingDuration >= 15.0 {
                    stopVideoRecording()
                }
            }
        }
    }
    

}

// MARK: - Photo Capture Delegate
class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    private let completion: (UIImage?) -> Void
    private let cameraPosition: AVCaptureDevice.Position
    
    init(completion: @escaping (UIImage?) -> Void, cameraPosition: AVCaptureDevice.Position) {
        self.completion = completion
        self.cameraPosition = cameraPosition
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("Photo capture error: \(error)")
            completion(nil)
            return
        }
        
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            print("Failed to create image from photo data")
            completion(nil)
            return
        }
        
        // Canlı kamera görüntüsü zaten ayna görüntüsü olduğu için fotoğrafı değiştirmiyoruz
        let finalImage = image
        print("Using original image for both front and back camera")
        
        print("Photo captured successfully, calling completion with image")
        completion(finalImage)
    }
}

// MARK: - Video Recording Delegate
class VideoRecordingDelegate: NSObject, AVCaptureFileOutputRecordingDelegate {
    private let completion: (Bool, URL?) -> Void
    
    init(completion: @escaping (Bool, URL?) -> Void) {
        self.completion = completion
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        completion(true, nil)
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error = error {
            print("Video recording error: \(error)")
            completion(false, nil)
            return
        }
        
        print("Video recorded successfully to: \(outputFileURL)")
        completion(true, outputFileURL)
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
