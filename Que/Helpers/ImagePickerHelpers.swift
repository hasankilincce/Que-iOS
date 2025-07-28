import SwiftUI
import TOCropViewController

// Sadece fotoğraf seçimi için
struct UIKitImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Binding var isPresented: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: UIKitImagePicker
        init(_ parent: UIKitImagePicker) { self.parent = parent }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                // Orientation'ı düzelt
                let correctedImage = uiImage.fixOrientation()
                // Fotoğrafı sıkıştır
                let compressedImage = correctedImage.compressedForUpload() ?? correctedImage
                parent.image = compressedImage
            }
            parent.isPresented = false
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.isPresented = false
        }
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
}

// Fotoğraf seçimi + crop için tam UIKit zinciri
struct UIKitCropImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Binding var isPresented: Bool
    var cropSize: CGSize = CGSize(width: 256, height: 256)

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate, TOCropViewControllerDelegate {
        let parent: UIKitCropImagePicker
        var pickedImage: UIImage?
        init(_ parent: UIKitCropImagePicker) { self.parent = parent }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                // Orientation'ı düzelt
                let correctedImage = uiImage.fixOrientation()
                // Fotoğrafı sıkıştır
                let compressedImage = correctedImage.compressedForUpload() ?? correctedImage
                pickedImage = compressedImage
                let cropVC = TOCropViewController(croppingStyle: .circular, image: compressedImage)
                cropVC.delegate = self
                picker.present(cropVC, animated: true)
            } else {
                parent.isPresented = false
            }
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.isPresented = false
        }
        func cropViewController(_ cropViewController: TOCropViewController, didCropToCircularImage image: UIImage, with cropRect: CGRect, angle: Int) {
            let resized = image.resize(to: parent.cropSize)
            // Sıkıştırılmış fotoğrafı kullan
            let compressed = resized.compressedForUpload() ?? resized
            parent.image = compressed
            cropViewController.dismiss(animated: true) {
                self.parent.isPresented = false
            }
        }
        func cropViewControllerDidCancel(_ cropViewController: TOCropViewController) {
            cropViewController.dismiss(animated: true) {
                self.parent.isPresented = false
            }
        }
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
}

extension UIImage {
    func resize(to size: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        self.draw(in: CGRect(origin: .zero, size: size))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage ?? self
    }
    
    /// Fotoğraf orientation'ını düzelt
    func fixOrientation() -> UIImage {
        // Eğer orientation zaten doğruysa, değiştirme
        if self.imageOrientation == .up {
            return self
        }
        
        // Yeni bir context oluştur
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
        self.draw(in: CGRect(origin: .zero, size: self.size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return normalizedImage ?? self
    }
    
    /// Fotoğraf seçimi sonrası otomatik sıkıştırma
    func compressedForUpload() -> UIImage? {
        // 9:16 format için özel sıkıştırma
        return ImageCompressionHelper.compressImageForPostWithAspectRatio(self)
    }
} 