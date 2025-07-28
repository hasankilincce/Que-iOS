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
                // Background - either live camera, captured media, or post creation
                if showingPostCreation {
                    // Post creation background
                    if let image = mediaCaptureManager.capturedImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .clipped()
                            .ignoresSafeArea()
                    } else if let videoURL = mediaCaptureManager.capturedVideoURL {
                        // Video background for post creation
                        Color.black
                            .ignoresSafeArea()
                    }
                } else if mediaCaptureManager.showingCapturedMedia {
                    if let image = mediaCaptureManager.capturedImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .clipped()
                            .ignoresSafeArea()
                    } else if let videoURL = mediaCaptureManager.capturedVideoURL {
                        // Video player will be added here
                        Color.black
                            .ignoresSafeArea()
                    }
                } else if cameraManager.cameraPermissionGranted && cameraManager.cameraSessionReady {
                    LiveCameraView(session: cameraManager.cameraSession)
                        .ignoresSafeArea()
                } else {
                    Color.black
                        .ignoresSafeArea()
                }
                
                // Camera overlay UI
                CameraOverlayView(
                    cameraManager: cameraManager,
                    mediaCaptureManager: mediaCaptureManager,
                    homeViewModel: homeViewModel,
                    onCancel: {
                        homeViewModel.selectTab(.home)
                    },
                    onUseCapturedMedia: {
                        useCapturedMedia()
                    },
                    onCapturePhoto: {
                        capturePhoto()
                    },
                    onStartVideoRecording: {
                        startVideoRecording()
                    },
                    onStopVideoRecording: {
                        stopVideoRecording()
                    },
                    onSwitchCamera: {
                        switchCamera()
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
    }
    
    // MARK: - Post Creation Functions
    
    private func createPost() {
        Task {
            await viewModel.createPost()
            
            DispatchQueue.main.async {
                showingPostCreation = false
                mediaCaptureManager.clearCapturedMedia()
                homeViewModel.selectTab(.home)
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
        mediaCaptureManager.startVideoRecording(cameraManager: cameraManager)
        
        // Start a timer to check for max duration
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if mediaCaptureManager.recordingDuration >= 15.0 {
                stopVideoRecording()
                timer.invalidate()
            }
        }
    }
    
    private func stopVideoRecording() {
        mediaCaptureManager.stopVideoRecording(cameraManager: cameraManager)
    }
    

}
