import AVFoundation
import UIKit

class MediaCaptureManager: ObservableObject {
    @Published var isRecording = false
    @Published var recordingDuration: TimeInterval = 0
    @Published var capturedImage: UIImage?
    @Published var capturedVideoURL: URL?
    @Published var showingCapturedMedia = false
    
    private var recordingStartTime: Date?
    private var recordingTimer: Timer?
    private var photoCaptureDelegate: PhotoCaptureDelegate?
    
    func capturePhoto(cameraManager: CameraManager, completion: @escaping (Bool) -> Void) {
        guard let photoOutput = cameraManager.getPhotoOutput() else { 
            print("Photo output is nil")
            completion(false)
            return 
        }
        
        print("Starting photo capture...")
        
        // Set video orientation
        if let conn = photoOutput.connection(with: .video),
           conn.isVideoOrientationSupported {
            conn.videoOrientation = .portrait
            
            if conn.isVideoMirroringSupported {
                conn.isVideoMirrored = (cameraManager.cameraPosition == .front)
            }
            
            print("Video orientation set to: \(conn.videoOrientation.rawValue)")
        }
        
        print("Photo output available codecs: \(photoOutput.availablePhotoCodecTypes)")
        
        let settings = AVCapturePhotoSettings()
        
        // Flaş ayarları - tüm kameralar için kullanıcının seçtiği modu kullan
        settings.flashMode = cameraManager.flashMode
        
        // 9:16 format için özel ayarlar
        if let photoOutputConnection = photoOutput.connection(with: .video) {
            if photoOutputConnection.isVideoOrientationSupported {
                photoOutputConnection.videoOrientation = .portrait
            }
            
            // 9:16 aspect ratio için ayarlar
            if photoOutputConnection.isVideoStabilizationSupported {
                photoOutputConnection.preferredVideoStabilizationMode = .auto
            }
        }
        
        print("Photo settings created: \(settings)")
        
        let delegate = PhotoCaptureDelegate(completion: { image in
            DispatchQueue.main.async {
                print("Photo capture completion called with image: \(image != nil)")
                if let image = image {
                    self.capturedImage = image
                    self.showingCapturedMedia = true
                    print("Photo captured successfully and set to UI")
                    completion(true)
                } else {
                    print("Photo capture failed - no image received")
                    completion(false)
                }
            }
        }, cameraPosition: cameraManager.cameraPosition)
        
        photoCaptureDelegate = delegate
        
        print("About to call capturePhoto with delegate: \(delegate)")
        print("Photo output connections before capture: \(photoOutput.connections)")
        
        photoOutput.capturePhoto(with: settings, delegate: delegate)
        print("capturePhoto called successfully")
    }
    
    func startVideoRecording(cameraManager: CameraManager) {
        guard let movieOutput = cameraManager.getMovieOutput(), !isRecording else { return }
        
        guard movieOutput.isRecording == false else { return }
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let videoName = "temp_video_\(Date().timeIntervalSince1970).mov"
        let videoURL = documentsPath.appendingPathComponent(videoName)
        
        movieOutput.startRecording(to: videoURL, recordingDelegate: VideoRecordingDelegate { success, videoURL in
            DispatchQueue.main.async {
                if success {
                    print("Video recording started successfully")
                    self.isRecording = true
                    self.recordingStartTime = Date()
                    self.startRecordingTimer()
                }
                
                if let videoURL = videoURL {
                    self.capturedVideoURL = videoURL
                    self.showingCapturedMedia = true
                    print("Video saved to viewModel: \(videoURL)")
                }
            }
        })
    }
    
    func stopVideoRecording(cameraManager: CameraManager) {
        guard let movieOutput = cameraManager.getMovieOutput(), isRecording else { return }
        
        movieOutput.stopRecording()
        isRecording = false
        recordingTimer?.invalidate()
        recordingTimer = nil
        recordingDuration = 0
        print("Video recording stopped")
    }
    
    private func startRecordingTimer() {
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            if let startTime = self.recordingStartTime {
                self.recordingDuration = Date().timeIntervalSince(startTime)
                
                // Stop recording if max duration reached (15 seconds)
                if self.recordingDuration >= 15.0 {
                    // We can't call stopVideoRecording here because we don't have access to cameraManager
                    // This will be handled by the timer in the view
                }
            }
        }
    }
    
    func clearCapturedMedia() {
        capturedImage = nil
        capturedVideoURL = nil
        showingCapturedMedia = false
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
        
        // 9:16 format için fotoğrafı düzelt
        let correctedImage = correctImageOrientation(image)
        
        // Fotoğrafı sıkıştır
        let compressedImage = correctedImage.compressedForUpload() ?? correctedImage
        print("Photo captured, corrected and compressed successfully")
        completion(compressedImage)
    }
    
    // Fotoğraf yönünü düzelt
    private func correctImageOrientation(_ image: UIImage) -> UIImage {
        // Eğer fotoğraf zaten doğru yöndeyse, değiştirme
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