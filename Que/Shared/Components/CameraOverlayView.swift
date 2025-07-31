import SwiftUI

struct CameraOverlayView: View {
    @ObservedObject var mediaCaptureManager: MediaCaptureManager
    let onCapturePhoto: () -> Void
    let onStartVideoRecording: () -> Void
    let onStopVideoRecording: () -> Void
    let onUseCapturedMedia: () -> Void
    let onSwitchCamera: () -> Void
    let onCancel: () -> Void
    let onSettings: () -> Void
    @State private var showImagePicker = false
    @State private var showSettingsMenu = false
    
    var body: some View {
        ZStack {
            // Üst kontroller
            VStack {
                // Top bar + settings button & menu
                ZStack(alignment: .topTrailing) {
                    // 1) İptal–Soru bar'ı
                    HStack {
                        Button("İptal") {
                            if mediaCaptureManager.showingCapturedMedia {
                                mediaCaptureManager.clearCapturedMedia()
                            } else {
                                onCancel()
                            }
                        }
                        .foregroundColor(.white)
                        .font(.system(size: 18, weight: .medium))

                        Spacer()

                        Text("Soru")
                            .foregroundColor(.white)
                            .font(.system(size: 18, weight: .semibold))

                        Spacer()

                        // Sağda yer tutucu (44×44)
                        Color.clear
                            .frame(width: 44, height: 44)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)

                    // 2) Açılır ayar menüsü (sadece kamera modunda)
                    if showSettingsMenu && !mediaCaptureManager.showingCapturedMedia {
                        VStack(spacing: 8) {
                            Button(action: {
                                onSettings()
                            }) {
                                ZStack() {
                                    Image(systemName: "gearshape.fill")
                                        .foregroundColor(.white)
                                        .font(.system(size: 20, weight: .medium))
                                        .frame(width: 44, height: 44)
                                        .background(Color.black.opacity(0.6))
                                        .clipShape(Circle())
                                }
                            }
                        }
                        .padding(.trailing, 20)
                        .padding(.top, 60)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    // 3) Ayar ikonu (sadece kamera modunda)
                    if !mediaCaptureManager.showingCapturedMedia {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showSettingsMenu.toggle()
                            }
                        }) {
                            Image(systemName: "gearshape.fill")
                                .foregroundColor(.white)
                                .font(.system(size: 20, weight: .medium))
                                .frame(width: 44, height: 44)
                                .background(Color.black.opacity(0.3))
                                .clipShape(Circle())
                        }
                        .padding(.trailing, 20)
                        .padding(.top, 10)
                    }
                }
                
                Spacer()
                
                // Kayıt göstergesi
                if mediaCaptureManager.isRecording {
                    HStack {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 12, height: 12)
                            .scaleEffect(
                                mediaCaptureManager.recordingDuration.truncatingRemainder(dividingBy: 1) < 0.5
                                    ? 1.0 : 0.7
                            )
                            .animation(
                                .easeInOut(duration: 0.5).repeatForever(autoreverses: true),
                                value: mediaCaptureManager.recordingDuration
                            )
                        
                        Text(String(format: "%.1f", mediaCaptureManager.recordingDuration))
                            .foregroundColor(.white)
                            .font(.system(size: 16, weight: .medium))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(20)
                }
                
                // Alt kontroller
                HStack {
                    Spacer()
                    
                    // Galeri butonu (sadece kamera modunda)
                    if !mediaCaptureManager.showingCapturedMedia {
                        Button(action: {
                            showImagePicker = true
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
                    }
                    
                    Spacer()
                    
                    // Ana çekim butonu
                    CaptureButton(
                        isRecording: mediaCaptureManager.isRecording,
                        recordingDuration: mediaCaptureManager.recordingDuration,
                        showingCapturedMedia: mediaCaptureManager.showingCapturedMedia,
                        onTap: {
                            if mediaCaptureManager.showingCapturedMedia {
                                onUseCapturedMedia()
                            } else if !mediaCaptureManager.isRecording {
                                onCapturePhoto()
                            }
                        },
                        onLongPressStart: {
                            if !mediaCaptureManager.showingCapturedMedia && !mediaCaptureManager.isRecording {
                                mediaCaptureManager.startLongPress()
                                onStartVideoRecording()
                            }
                        },
                        onLongPressEnd: {
                            if mediaCaptureManager.isRecording {
                                mediaCaptureManager.endLongPress()
                                onStopVideoRecording()
                            }
                        }
                    )
                    
                    Spacer()
                    
                    // Kamera değiştir butonu (sadece kamera modunda)
                    if !mediaCaptureManager.showingCapturedMedia {
                        Button(action: {
                            onSwitchCamera()
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
                    }
                    
                    Spacer()
                }
                .padding(.bottom, 50)
            }
        }
        .fullScreenCover(isPresented: $showImagePicker) {
            UIKitImagePicker(
                image: $mediaCaptureManager.capturedImage,
                videoURL: $mediaCaptureManager.capturedVideoURL,
                isPresented: $showImagePicker
            )
            .onDisappear {
                if let videoURL = mediaCaptureManager.capturedVideoURL {
                    mediaCaptureManager.setVideoFromURL(videoURL)
                } else if mediaCaptureManager.capturedImage != nil {
                    mediaCaptureManager.showingCapturedMedia = true
                }
            }
        }
    }
}

// MARK: - Capture Button Component
struct CaptureButton: View {
    let isRecording: Bool
    let recordingDuration: TimeInterval
    let showingCapturedMedia: Bool
    let onTap: () -> Void
    let onLongPressStart: () -> Void
    let onLongPressEnd: () -> Void
    
    var body: some View {
        ZStack {
            // Ana buton
            Circle()
                .fill(isRecording ? Color.red : Color.white)
                .frame(width: 80, height: 80)
                .scaleEffect(isRecording ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isRecording)
                .overlay(
                    Circle()
                        .stroke(
                            isRecording ? Color.red.opacity(0.3) : Color.white.opacity(0.3),
                            lineWidth: 4
                        )
                        .frame(width: 90, height: 90)
                        .scaleEffect(isRecording ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 0.3), value: isRecording)
                )
            
            // İçerik
            if isRecording {
                // Video kayıt ikonu
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white)
                    .frame(width: 32, height: 32)
                    .scaleEffect(recordingDuration.truncatingRemainder(dividingBy: 0.5) < 0.25 ? 1.0 : 0.9)
                    .animation(.easeInOut(duration: 0.25).repeatForever(autoreverses: true), value: recordingDuration)
            } else if showingCapturedMedia {
                // Onay ikonu
                Image(systemName: "checkmark")
                    .foregroundColor(.black)
                    .font(.system(size: 32, weight: .bold))
            } else {
                // Fotoğraf ikonu
                Image(systemName: "camera")
                    .foregroundColor(.black)
                    .font(.system(size: 24, weight: .medium))
                    .opacity(isRecording ? 0 : 1)
                    .animation(.easeInOut(duration: 0.2), value: isRecording)
            }
        }
        .onTapGesture {
            onTap()
        }
        .gesture(
            LongPressGesture(minimumDuration: 0.1)
                .onChanged { _ in
                    onLongPressStart()
                }
                .onEnded { _ in
                    onLongPressEnd()
                }
        )
    }
}
