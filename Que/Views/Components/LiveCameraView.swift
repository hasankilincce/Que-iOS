import SwiftUI
import AVFoundation

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