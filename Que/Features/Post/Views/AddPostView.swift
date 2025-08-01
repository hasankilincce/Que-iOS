import SwiftUI
import AVFoundation
import PhotosUI

struct AddPostView: View {
    @ObservedObject var viewModel: AddPostViewModel
    @ObservedObject var homeViewModel: HomeViewModel
    
    // Managers
    @StateObject private var cameraManager = CameraManager()
    @StateObject private var mediaCaptureManager = MediaCaptureManager()
    
    // Post creation states
    @State private var showingPostCreation = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Ensure full screen coverage
                Color.black
                    .ignoresSafeArea(.all, edges: .all)
                // Background - either live camera, captured media, or post creation
                if showingPostCreation {
                    // Post creation background
                    if let image = mediaCaptureManager.capturedImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(9/16, contentMode: .fit)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.black)
                            .ignoresSafeArea(.all, edges: .all)
                    } else if let videoURL = mediaCaptureManager.capturedVideoURL {
                        // Video background for post creation - 9:16 aspect ratio için optimize edilmiş
                        VideoPlayerView(
                            videoURL: videoURL,
                            videoId: "add_post_video",
                            isVisible: true
                        )
                            .aspectRatio(9/16, contentMode: .fit) // 9:16 aspect ratio
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.black)
                            .ignoresSafeArea(.all, edges: .all)
                    }
                } else if mediaCaptureManager.showingCapturedMedia {
                    if let image = mediaCaptureManager.capturedImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(9/16, contentMode: .fit)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.black)
                            .ignoresSafeArea(.all, edges: .all)
                    } else if let videoURL = mediaCaptureManager.capturedVideoURL {
                        // Video player - 9:16 aspect ratio için optimize edilmiş
                        VideoPlayerView(
                            videoURL: videoURL,
                            videoId: "captured_video",
                            isVisible: true
                        )
                            .aspectRatio(9/16, contentMode: .fit) // 9:16 aspect ratio
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.black)
                            .ignoresSafeArea(.all, edges: .all)
                    }
                } else if cameraManager.cameraPermissionGranted && cameraManager.cameraSessionReady {
                    LiveCameraView(session: cameraManager.cameraSession)
                        .aspectRatio(9/16, contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black)
                        .ignoresSafeArea(.all, edges: .all)
                } else {
                    Color.black
                        .ignoresSafeArea()
                }
                
                // Camera overlay UI
                CameraOverlayView(
                    mediaCaptureManager: mediaCaptureManager,
                    onCapturePhoto: {
                        capturePhoto()
                    },
                    onStartVideoRecording: {
                        startVideoRecording()
                    },
                    onStopVideoRecording: {
                        stopVideoRecording()
                    },
                    onUseCapturedMedia: {
                        useCapturedMedia()
                    },
                    onSwitchCamera: {
                        switchCamera()
                    },
                    onCancel: {
                        homeViewModel.selectTab(.home)
                    },
                    onSettings: {
                        // Settings logic here
                        print("Settings button tapped")
                    }
                )
                
                // Post creation form overlay
                if showingPostCreation {
                    PostCreationView(
                        viewModel: viewModel,
                        mediaCaptureManager: mediaCaptureManager,
                        onCancel: {
                            showingPostCreation = false
                            mediaCaptureManager.clearCapturedMedia()
                        },
                        onPost: {
                            createPost()
                        }
                    )
                }
            }
        }
        .onAppear {
            cameraManager.checkCameraPermission()
            
            // Video işleme durumunu kontrol etmek için timer başlat
            if viewModel.isVideoProcessing {
                startVideoProcessingTimer()
            }
        }
        .alert("Kamera İzni Gerekli", isPresented: $cameraManager.showingPermissionAlert) {
            Button("Ayarlar") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            Button("İptal", role: .cancel) { }
        } message: {
            Text("Kamera erişimi için ayarlardan izin vermeniz gerekiyor.")
        }
        .alert("Mikrofon İzni Gerekli", isPresented: $cameraManager.showingMicrophonePermissionAlert) {
            Button("Ayarlar") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            Button("İptal", role: .cancel) { }
        } message: {
            Text("Video kayıt sırasında ses kaydetmek için mikrofon erişimi gerekiyor.")
        }
        .alert("Video İşleme Tamamlandı", isPresented: $viewModel.showVideoProcessingComplete) {
            Button("Tamam") {
                showingPostCreation = false
                mediaCaptureManager.clearCapturedMedia()
                homeViewModel.selectTab(.home)
            }
        } message: {
            Text("Video başarıyla işlendi ve gönderiniz paylaşıldı!")
        }
    }
    
    // MARK: - Post Creation Functions
    
    private func createPost() {
        Task {
            await viewModel.createPost()
            
            DispatchQueue.main.async {
                if viewModel.isVideoProcessing {
                    // Video işleniyorsa timer'ı başlat
                    startVideoProcessingTimer()
                } else {
                    // Normal post ise direkt kapat
                    showingPostCreation = false
                    mediaCaptureManager.clearCapturedMedia()
                    homeViewModel.selectTab(.home)
                }
            }
        }
    }
    
    // MARK: - Camera Functions
    
    private func switchCamera() {
        cameraManager.switchCamera()
    }
    
    // MARK: - Capture Functions
    
    private func capturePhoto() {
        mediaCaptureManager.capturePhoto(cameraManager: cameraManager) { success in
            if success {
                print("Photo captured successfully")
            } else {
                print("Photo capture failed")
            }
        }
    }
    
    private func useCapturedMedia() {
        if let image = mediaCaptureManager.capturedImage {
            viewModel.setBackgroundImage(image)
            print("Photo saved to viewModel")
            showingPostCreation = true
        } else if let videoURL = mediaCaptureManager.capturedVideoURL {
            viewModel.setBackgroundVideo(videoURL)
            print("Video saved to viewModel")
            showingPostCreation = true
        }
    }
    
    private func startVideoRecording() {
        print("🎥 Starting video recording from AddPostView...")
        mediaCaptureManager.startVideoRecording(cameraManager: cameraManager)
        
        // Maksimum süre kontrolü (15 saniye)
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if mediaCaptureManager.recordingDuration >= 15.0 {
                print("⏰ Maximum recording duration reached (15s), stopping...")
                stopVideoRecording()
                timer.invalidate()
            }
        }
    }
    
    private func stopVideoRecording() {
        print("⏹️ Stopping video recording from AddPostView...")
        mediaCaptureManager.stopVideoRecording(cameraManager: cameraManager)
    }
    
    // MARK: - Video Processing Timer
    
    private func startVideoProcessingTimer() {
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { timer in
            Task {
                await viewModel.checkVideoProcessingStatus()
                
                // Video işleme tamamlandıysa timer'ı durdur
                let isProcessing = await viewModel.isVideoProcessing
                if !isProcessing {
                    timer.invalidate()
                }
            }
        }
    }
    

}
