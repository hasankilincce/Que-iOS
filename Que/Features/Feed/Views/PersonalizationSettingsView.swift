import SwiftUI

struct PersonalizationSettingsView: View {
    @ObservedObject var viewModel: FeedViewModel
    @State private var selectedInterests: Set<String> = []
    @State private var showInterestSelector = false
    
    private let availableInterests = [
        "teknoloji", "spor", "müzik", "sanat", "bilim", "tarih", "felsefe",
        "psikoloji", "ekonomi", "siyaset", "sağlık", "eğitim", "oyun",
        "film", "kitap", "yemek", "seyahat", "fotoğrafçılık", "mimari",
        "moda", "güzellik", "fitness", "meditasyon", "yoga", "dans"
    ]
    
    var body: some View {
        NavigationView {
            Form {
                // Kişiselleştirme Durumu
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Kişiselleştirme")
                                .font(.headline)
                            Text(viewModel.isPersonalized ? "Aktif" : "Pasif")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: $viewModel.isPersonalized)
                            .onChange(of: viewModel.isPersonalized) { _, newValue in
                                viewModel.togglePersonalization()
                            }
                    }
                } header: {
                    Text("Durum")
                } footer: {
                    Text("Kişiselleştirme aktifken, ilgi alanlarınıza göre önerilen içerikler gösterilir.")
                }
                
                // İlgi Alanları
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        if selectedInterests.isEmpty {
                            Text("Henüz ilgi alanı seçilmedi")
                                .foregroundColor(.secondary)
                                .italic()
                        } else {
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                                ForEach(Array(selectedInterests), id: \.self) { interest in
                                    InterestChip(
                                        title: interest.capitalized,
                                        isSelected: true
                                    ) {
                                        selectedInterests.remove(interest)
                                        updateInterests()
                                    }
                                }
                            }
                        }
                        
                        Button("İlgi Alanları Ekle") {
                            showInterestSelector = true
                        }
                        .buttonStyle(.bordered)
                    }
                } header: {
                    Text("İlgi Alanları")
                } footer: {
                    Text("İlgi alanlarınız, size gösterilen içerikleri kişiselleştirmek için kullanılır.")
                }
                
                // İçerik Tercihleri
                if let userProfile = RecommendationEngine.shared.userProfile {
                    Section {
                        VStack(spacing: 12) {
                            PreferenceRow(
                                title: "Sorular",
                                subtitle: "Soru postlarını göster",
                                isEnabled: userProfile.preferences.showQuestions
                            ) {
                                // Toggle logic
                            }
                            
                            PreferenceRow(
                                title: "Cevaplar",
                                subtitle: "Cevap postlarını göster",
                                isEnabled: userProfile.preferences.showAnswers
                            ) {
                                // Toggle logic
                            }
                            
                            PreferenceRow(
                                title: "Videolar",
                                subtitle: "Video içerikli postları göster",
                                isEnabled: userProfile.preferences.showVideos
                            ) {
                                // Toggle logic
                            }
                            
                            PreferenceRow(
                                title: "Resimler",
                                subtitle: "Resim içerikli postları göster",
                                isEnabled: userProfile.preferences.showImages
                            ) {
                                // Toggle logic
                            }
                        }
                    } header: {
                        Text("İçerik Tercihleri")
                    }
                    
                    // İçerik Filtresi
                    Section {
                        Picker("İçerik Filtresi", selection: .constant(userProfile.preferences.contentFilter)) {
                            ForEach(UserContentFilter.allCases, id: \.self) { filter in
                                Text(filter.displayName).tag(filter)
                            }
                        }
                        .pickerStyle(.segmented)
                    } header: {
                        Text("İçerik Filtresi")
                    } footer: {
                        Text("Sıkı: Sadece güvenli içerikler\nOrta: Çoğu içerik\nRahat: Tüm içerikler")
                    }
                }
                
                // Algoritma Seçimi
                Section {
                    Picker("Öneri Algoritması", selection: $viewModel.currentAlgorithm) {
                        ForEach(RecommendationAlgorithm.allCases, id: \.self) { algorithm in
                            Text(algorithm.displayName).tag(algorithm)
                        }
                    }
                    .pickerStyle(.menu)
                } header: {
                    Text("Algoritma")
                } footer: {
                    Text("Hangi algoritmanın kullanılacağını seçin.")
                }
                
                // İstatistikler
                Section {
                    VStack(spacing: 8) {
                        StatRow(title: "Toplam Etkileşim", value: "\(viewModel.getUserInteractionHistory().count)")
                        StatRow(title: "Beğenilen Post", value: "\(viewModel.getUserInteractionHistory().filter { $0.interactionType == .like }.count)")
                        StatRow(title: "İzlenen Video", value: "\(viewModel.getUserInteractionHistory().filter { $0.interactionType == .view }.count)")
                    }
                } header: {
                    Text("İstatistikler")
                }
            }
            .navigationTitle("Kişiselleştirme")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showInterestSelector) {
                InterestSelectorView(
                    selectedInterests: $selectedInterests,
                    availableInterests: availableInterests,
                    onSave: updateInterests
                )
            }
            .onAppear {
                loadCurrentInterests()
            }
        }
    }
    
    private func loadCurrentInterests() {
        if let userProfile = RecommendationEngine.shared.userProfile {
            selectedInterests = Set(userProfile.interests)
        }
    }
    
    private func updateInterests() {
        viewModel.updateUserInterests(Array(selectedInterests))
    }
}

// MARK: - Supporting Views

struct InterestChip: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundColor(isSelected ? .white : .primary)
            
            if isSelected {
                Button(action: onTap) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white)
                        .font(.caption)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(isSelected ? Color.blue : Color(.systemGray5))
        .cornerRadius(16)
    }
}

struct PreferenceRow: View {
    let title: String
    let subtitle: String
    let isEnabled: Bool
    let onToggle: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: .constant(isEnabled))
                .onChange(of: isEnabled) { _, _ in
                    onToggle()
                }
        }
    }
}

struct StatRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
            Spacer()
            Text(value)
                .font(.subheadline.bold())
                .foregroundColor(.blue)
        }
    }
}

struct InterestSelectorView: View {
    @Binding var selectedInterests: Set<String>
    let availableInterests: [String]
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(availableInterests, id: \.self) { interest in
                    HStack {
                        Text(interest.capitalized)
                        Spacer()
                        if selectedInterests.contains(interest) {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if selectedInterests.contains(interest) {
                            selectedInterests.remove(interest)
                        } else {
                            selectedInterests.insert(interest)
                        }
                    }
                }
            }
            .navigationTitle("İlgi Alanları")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kaydet") {
                        onSave()
                        dismiss()
                    }
                }
            }
        }
    }
} 