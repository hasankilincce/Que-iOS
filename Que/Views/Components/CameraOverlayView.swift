import SwiftUI

struct CameraOverlayView: View {
    @ObservedObject var cameraManager: CameraManager
    @ObservedObject var mediaCaptureManager: MediaCaptureManager
    @ObservedObject var homeViewModel: HomeViewModel
    @State private var showSettingsMenu = false

    let onCancel: () -> Void
    let onUseCapturedMedia: () -> Void
    let onCapturePhoto: () -> Void
    let onStartVideoRecording: () -> Void
    let onStopVideoRecording: () -> Void
    let onSwitchCamera: () -> Void

    var body: some View {
        VStack {
            // Top bar + settings button & menu
            ZStack(alignment: .topTrailing) {
                // 1) İptal–Soru bar’ı
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

                // 2) Açılır ayar menüsü
                if showSettingsMenu {
                    VStack(spacing: 8) {
                        Button(action: {
                            cameraManager.toggleFlashMode()
                        }) {
                            ZStack() {
                                Image(systemName: cameraManager.flashModeIcon)
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

                // 3) Ayar ikonu
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

                // Galeri butonu
                Button(action: {
                    // Galeri seçici
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

                // Fotoğraf/Kayıt butonu
                Button(action: {
                    if mediaCaptureManager.showingCapturedMedia {
                        onUseCapturedMedia()
                    } else {
                        onCapturePhoto()
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(mediaCaptureManager.isRecording ? Color.red : Color.white)
                            .frame(width: 80, height: 80)
                            .overlay(
                                Circle()
                                    .stroke(
                                        mediaCaptureManager.isRecording
                                            ? Color.red.opacity(0.3)
                                            : Color.white.opacity(0.3),
                                        lineWidth: 4
                                    )
                                    .frame(width: 90, height: 90)
                            )

                        if mediaCaptureManager.isRecording {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white)
                                .frame(width: 32, height: 32)
                        } else if mediaCaptureManager.showingCapturedMedia {
                            Image(systemName: "checkmark")
                                .foregroundColor(.black)
                                .font(.system(size: 32, weight: .bold))
                        }
                    }
                }
                .simultaneousGesture(
                    LongPressGesture(minimumDuration: 0.5)
                        .onChanged { _ in
                            if !mediaCaptureManager.showingCapturedMedia {
                                onStartVideoRecording()
                            }
                        }
                        .onEnded { _ in
                            if !mediaCaptureManager.showingCapturedMedia {
                                onStopVideoRecording()
                            }
                        }
                )

                Spacer()

                // Kamera değiştir butonu
                Button(action: {
                    if !mediaCaptureManager.showingCapturedMedia {
                        onSwitchCamera()
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
                .disabled(mediaCaptureManager.showingCapturedMedia)

                Spacer()
            }
            .padding(.bottom, 50)
        }
    }
}
