import SwiftUI
import Charts

struct AnalyticsDashboardView: View {
    @ObservedObject var analyticsService = AnalyticsService.shared
    @State private var analyticsReport: [String: Any] = [:]
    @State private var isLoading = false
    @State private var selectedTimeRange = "7d"
    
    private let timeRanges = [
        ("7d", "Son 7 Gün"),
        ("30d", "Son 30 Gün"),
        ("90d", "Son 90 Gün")
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    headerSection
                    
                    // Time Range Picker
                    timeRangeSection
                    
                    // Analytics Cards
                    if isLoading {
                        ProgressView("Analytics yükleniyor...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        analyticsCardsSection
                        
                        // Charts
                        chartsSection
                        
                        // User Behavior
                        userBehaviorSection
                    }
                }
                .padding()
            }
            .navigationTitle("Analytics Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                loadAnalyticsReport()
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Analytics Dashboard")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Kullanıcı davranış analizi ve performans metrikleri")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: {
                    loadAnalyticsReport()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.blue)
                }
            }
            
            if let session = analyticsService.currentSession {
                HStack {
                    Text("Aktif Session:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(session.id.prefix(8))
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text("\(Int(session.duration))s")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }
    
    // MARK: - Time Range Section
    
    private var timeRangeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Zaman Aralığı")
                .font(.headline)
            
            HStack {
                ForEach(timeRanges, id: \.0) { range in
                    Button(action: {
                        selectedTimeRange = range.0
                        loadAnalyticsReport()
                    }) {
                        Text(range.1)
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(selectedTimeRange == range.0 ? Color.blue : Color.gray.opacity(0.2))
                            .foregroundColor(selectedTimeRange == range.0 ? .white : .primary)
                            .cornerRadius(8)
                    }
                }
            }
        }
    }
    
    // MARK: - Analytics Cards Section
    
    private var analyticsCardsSection: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            AnalyticsCard(
                title: "Toplam Görüntüleme",
                value: "\(analyticsReport["total_views"] as? Int ?? 0)",
                icon: "eye.fill",
                color: .blue
            )
            
            AnalyticsCard(
                title: "Beğeni Sayısı",
                value: "\(analyticsReport["total_likes"] as? Int ?? 0)",
                icon: "heart.fill",
                color: .red
            )
            
            AnalyticsCard(
                title: "Paylaşım Sayısı",
                value: "\(analyticsReport["total_shares"] as? Int ?? 0)",
                icon: "square.and.arrow.up.fill",
                color: .green
            )
            
            AnalyticsCard(
                title: "Yorum Sayısı",
                value: "\(analyticsReport["total_comments"] as? Int ?? 0)",
                icon: "message.fill",
                color: .orange
            )
        }
    }
    
    // MARK: - Charts Section
    
    private var chartsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Trend Analizi")
                .font(.headline)
            
            // Engagement Rate Chart
            VStack(alignment: .leading, spacing: 8) {
                Text("Engagement Rate")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Chart {
                    if let engagementData = analyticsReport["engagement_data"] as? [[String: Any]] {
                        ForEach(engagementData.indices, id: \.self) { index in
                            let data = engagementData[index]
                            if let date = data["date"] as? String,
                               let rate = data["rate"] as? Double {
                                LineMark(
                                    x: .value("Date", date),
                                    y: .value("Rate", rate)
                                )
                                .foregroundStyle(.blue)
                            }
                        }
                    }
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
    }
    
    // MARK: - User Behavior Section
    
    private var userBehaviorSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Kullanıcı Davranışı")
                .font(.headline)
            
            VStack(spacing: 12) {
                BehaviorRow(
                    title: "Ortalama Session Süresi",
                    value: "\(analyticsReport["avg_session_duration"] as? Int ?? 0) saniye",
                    icon: "clock.fill",
                    color: .blue
                )
                
                BehaviorRow(
                    title: "Günlük Aktif Kullanıcı",
                    value: "\(analyticsReport["daily_active_users"] as? Int ?? 0)",
                    icon: "person.2.fill",
                    color: .green
                )
                
                BehaviorRow(
                    title: "Retention Rate",
                    value: "%\(analyticsReport["retention_rate"] as? Int ?? 0)",
                    icon: "arrow.up.right.circle.fill",
                    color: .orange
                )
                
                BehaviorRow(
                    title: "Bounce Rate",
                    value: "%\(analyticsReport["bounce_rate"] as? Int ?? 0)",
                    icon: "arrow.down.right.circle.fill",
                    color: .red
                )
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadAnalyticsReport() {
        isLoading = true
        
        Task {
            do {
                let report = try await analyticsService.getAnalyticsReport(dateRange: selectedTimeRange)
                
                await MainActor.run {
                    self.analyticsReport = report
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                }
                print("Analytics report error: \(error)")
            }
        }
    }
}

// MARK: - Analytics Card

struct AnalyticsCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Behavior Row

struct BehaviorRow: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                
                Text(value)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
} 