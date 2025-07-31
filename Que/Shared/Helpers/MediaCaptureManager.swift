import AVFoundation
import UIKit

class MediaCaptureManager: ObservableObject {
    @Published var isRecording = false
    @Published var recordingDuration: TimeInterval = 0
    @Published var capturedImage: UIImage?
    @Published var capturedVideoURL: URL?
    @Published var showingCapturedMedia = false
    @Published var isLongPressing = false
    
    private var recordingStartTime: Date?
    private var recordingTimer: Timer?
    private var photoCaptureDelegate: PhotoCaptureDelegate?
    private var videoRecordingDelegate: VideoRecordingDelegate?
    
    // MARK: - Photo Capture
    func capturePhoto(cameraManager: CameraManager, completion: @escaping (Bool) -> Void) {
        guard let photoOutput = cameraManager.getPhotoOutput() else { 
            print("❌ Photo output is nil")
            completion(false)
            return 
        }
        
        print("📸 Starting photo capture...")
        
        // Video orientation ayarla
        if let connection = photoOutput.connection(with: .video) {
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = .portrait
            }
            if connection.isVideoMirroringSupported {
                connection.isVideoMirrored = (cameraManager.cameraPosition == .front)
            }
        }
        
        let settings = AVCapturePhotoSettings()
        settings.flashMode = cameraManager.flashMode
        
        let delegate = PhotoCaptureDelegate { [weak self] image in
            DispatchQueue.main.async {
                if let image = image {
                    self?.capturedImage = image
                    self?.showingCapturedMedia = true
                    print("✅ Photo captured successfully")
                    completion(true)
                } else {
                    print("❌ Photo capture failed")
                    completion(false)
                }
            }
        }
        
        photoCaptureDelegate = delegate
        photoOutput.capturePhoto(with: settings, delegate: delegate)
    }
    
    // MARK: - Video Recording
    func startVideoRecording(cameraManager: CameraManager) {
        guard let movieOutput = cameraManager.getMovieOutput() else {
            print("❌ Movie output is nil")
            return
        }
        
        guard !isRecording else {
            print("⚠️ Already recording")
            return
        }
        
        guard !movieOutput.isRecording else {
            print("⚠️ Movie output is already recording")
            return
        }
        
        print("🎥 Starting video recording...")
        
        // Video ayarları
        if let connection = movieOutput.connection(with: .video) {
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = .portrait
            }
            if connection.isVideoStabilizationSupported {
                connection.preferredVideoStabilizationMode = .auto
            }
        }
        
        // Video dosyası oluştur
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let videoName = "video_\(Date().timeIntervalSince1970).mov"
        let videoURL = documentsPath.appendingPathComponent(videoName)
        
        print("📁 Video will be saved to: \(videoURL)")
        
        // Hemen UI'ı güncelle
        DispatchQueue.main.async {
            self.isRecording = true
            self.recordingStartTime = Date()
            self.startRecordingTimer()
        }
        
        // Video kaydını başlat
        let delegate = VideoRecordingDelegate { [weak self] success, url in
            DispatchQueue.main.async {
                if success {
                    print("✅ Video recording started successfully")
                    if let url = url {
                        self?.capturedVideoURL = url
                        self?.showingCapturedMedia = true
                        print("📹 Video saved: \(url)")
                    }
                } else {
                    print("❌ Video recording failed to start")
                    self?.isRecording = false
                    self?.recordingTimer?.invalidate()
                    self?.recordingTimer = nil
                    self?.recordingDuration = 0
                }
            }
        }
        
        videoRecordingDelegate = delegate
        movieOutput.startRecording(to: videoURL, recordingDelegate: delegate)
    }
    
    func stopVideoRecording(cameraManager: CameraManager) {
        guard let movieOutput = cameraManager.getMovieOutput() else {
            print("❌ Movie output is nil")
            return
        }
        
        guard isRecording else {
            print("⚠️ No active recording to stop")
            return
        }
        
        print("⏹️ Stopping video recording...")
        
        // Hemen UI'ı güncelle
        DispatchQueue.main.async {
            self.isRecording = false
            self.recordingTimer?.invalidate()
            self.recordingTimer = nil
            self.recordingDuration = 0
        }
        
        movieOutput.stopRecording()
    }
    
    // MARK: - Timer Management
    private func startRecordingTimer() {
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let startTime = self.recordingStartTime else { return }
            
            self.recordingDuration = Date().timeIntervalSince(startTime)
            
            // Maksimum 15 saniye
            if self.recordingDuration >= 15.0 {
                print("⏰ Max recording duration reached")
                self.recordingTimer?.invalidate()
                self.recordingTimer = nil
            }
        }
    }
    
    // MARK: - Long Press Management
    func startLongPress() {
        print("👆 Long press started")
        isLongPressing = true
    }
    
    func endLongPress() {
        print("👆 Long press ended")
        isLongPressing = false
    }
    
    // MARK: - Media Management
    func clearCapturedMedia() {
        capturedImage = nil
        capturedVideoURL = nil
        showingCapturedMedia = false
        isRecording = false
        recordingDuration = 0
        recordingTimer?.invalidate()
        recordingTimer = nil
    }
    
    func setVideoFromURL(_ url: URL) {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let videoName = "selected_video_\(Date().timeIntervalSince1970).mov"
        let destinationURL = documentsPath.appendingPathComponent(videoName)
        
        do {
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            
            try FileManager.default.copyItem(at: url, to: destinationURL)
            capturedVideoURL = destinationURL
            capturedImage = nil
            showingCapturedMedia = true
            
            print("📹 Video copied to: \(destinationURL.path)")
        } catch {
            print("❌ Error copying video: \(error)")
            capturedVideoURL = url
            capturedImage = nil
            showingCapturedMedia = true
        }
    }
}

// MARK: - Photo Capture Delegate
class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    private let completion: (UIImage?) -> Void
    
    init(completion: @escaping (UIImage?) -> Void) {
        self.completion = completion
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("❌ Photo capture error: \(error)")
            completion(nil)
            return
        }
        
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            print("❌ Failed to create image from photo data")
            completion(nil)
            return
        }
        
        let correctedImage = correctImageOrientation(image)
        let compressedImage = correctedImage.compressedForUpload() ?? correctedImage
        
        print("✅ Photo processed successfully")
        completion(compressedImage)
    }
    
    private func correctImageOrientation(_ image: UIImage) -> UIImage {
        if image.imageOrientation == .up {
            return image
        }
        
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        image.draw(in: CGRect(origin: .zero, size: image.size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return normalizedImage ?? image
    }
}

// MARK: - Video Recording Delegate
class VideoRecordingDelegate: NSObject, AVCaptureFileOutputRecordingDelegate {
    private let completion: (Bool, URL?) -> Void
    
    init(completion: @escaping (Bool, URL?) -> Void) {
        self.completion = completion
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        print("🎬 Video recording started to: \(fileURL)")
        completion(true, nil)
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error = error {
            print("❌ Video recording error: \(error)")
            completion(false, nil)
            return
        }
        
        print("✅ Video recorded successfully to: \(outputFileURL)")
        completion(true, outputFileURL)
    }
} 