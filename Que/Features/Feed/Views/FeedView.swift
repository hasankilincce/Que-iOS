import SwiftUI
import FirebaseAuth

struct FeedView: View {
    @ObservedObject var viewModel: FeedViewModel
    @State private var showPersonalizationSettings = false
    @State private var showAnalyticsDashboard = false
    @State private var showTestFunctions = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.black.ignoresSafeArea()
                
                if viewModel.showSkeleton {
                    // Skeleton loading
                    VStack(spacing: 20) {
                        ForEach(0..<5, id: \.self) { _ in
                            FeedShimmerLoadingView()
                        }
                    }
                    .padding(.horizontal)
                } else {
                    // Main feed
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(viewModel.posts) { post in
                                PostRowView(post: post, onLike: {
                                    Task {
                                        await viewModel.toggleLike(for: post)
                                    }
                                })
                                    .onAppear {
                                        // Prefetch next videos if needed
                                        // viewModel.prefetchVideo(for: post)
                                    }
                            }
                            
                            // Load more indicator
                            if viewModel.hasMorePosts && !viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .padding()
                                .onAppear {
                                        viewModel.loadMorePosts()
                                    }
                            }
                        }
                    }
                    .refreshable {
                        await viewModel.loadFeed()
                    }
                }
                
                // Error overlay
                if let errorMessage = viewModel.errorMessage {
                    VStack {
                        Text("Hata")
                            .font(.headline)
                                .foregroundColor(.white)
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                                .padding()
                                .background(Color.red.opacity(0.8))
                    .cornerRadius(10)
                    .padding()
                }
            }
            .navigationTitle("Feed")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Test Functions") {
                        showTestFunctions = true
                    }
                    .foregroundColor(.blue)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Kişiselleştirme Ayarları") {
                            showPersonalizationSettings = true
                        }
                        
                        Button("Analytics Dashboard") {
                            showAnalyticsDashboard = true
                        }
                        
                        Button(viewModel.isPersonalized ? "Genel Feed" : "Kişiselleştirilmiş Feed") {
                            viewModel.togglePersonalization()
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .sheet(isPresented: $showPersonalizationSettings) {
            PersonalizationSettingsView(viewModel: viewModel)
        }
        .sheet(isPresented: $showAnalyticsDashboard) {
            AnalyticsDashboardView()
        }
        .sheet(isPresented: $showTestFunctions) {
            FunctionsTestView(viewModel: viewModel)
        }
    }
}

struct FunctionsTestView: View {
    @ObservedObject var viewModel: FeedViewModel
    @State private var testResults: [String: String] = [:]
    @State private var isTesting = false
    
    var body: some View {
        NavigationView {
            List {
                Section("Functions Test") {
                    Button("Test Connection") {
                        testConnection()
                    }
                    .disabled(isTesting)
                    
                    Button("Test Toggle Like") {
                        Task {
                            await testToggleLike()
                        }
                    }
                    .disabled(isTesting)
                    
                    Button("Test Record Interaction") {
                        testRecordInteraction()
                    }
                    .disabled(isTesting)
                    
                    Button("Test Track Behavior") {
                        testTrackBehavior()
                    }
                    .disabled(isTesting)
                }
                
                Section("Test Results") {
                    ForEach(Array(testResults.keys.sorted()), id: \.self) { key in
                        VStack(alignment: .leading) {
                            Text(key)
                                .font(.headline)
                            Text(testResults[key] ?? "")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Functions Test")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func testConnection() {
        isTesting = true
        Task {
            do {
                let success = try await viewModel.mlFunctions.testConnection()
                await MainActor.run {
                    testResults["Connection"] = success ? "✅ Success" : "❌ Failed"
                    isTesting = false
                }
            } catch {
                await MainActor.run {
                    testResults["Connection"] = "❌ Error: \(error.localizedDescription)"
                    isTesting = false
                }
            }
        }
    }
    
    private func testToggleLike() async {
        guard let firstPost = viewModel.posts.first else {
            testResults["Toggle Like"] = "❌ No posts available"
            return
        }
        
        isTesting = true
        await viewModel.toggleLike(for: firstPost)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            testResults["Toggle Like"] = "✅ Test completed"
            isTesting = false
        }
    }
    
    private func testRecordInteraction() {
        guard let userId = Auth.auth().currentUser?.uid else {
            testResults["Record Interaction"] = "❌ User not authenticated"
            return
        }
        
        isTesting = true
        Task {
            do {
                let success = try await viewModel.mlFunctions.recordUserInteraction(
                    userId: userId,
                    postId: "test_post_id",
                    interactionType: "view",
                    duration: 5.0,
                    metadata: ["test": "true"]
                )
                await MainActor.run {
                    testResults["Record Interaction"] = success ? "✅ Success" : "❌ Failed"
                    isTesting = false
                }
            } catch {
                await MainActor.run {
                    testResults["Record Interaction"] = "❌ Error: \(error.localizedDescription)"
                    isTesting = false
                }
            }
        }
    }
    
    private func testTrackBehavior() {
        guard let userId = Auth.auth().currentUser?.uid else {
            testResults["Track Behavior"] = "❌ User not authenticated"
            return
        }
        
        isTesting = true
        Task {
            do {
                let success = try await viewModel.mlFunctions.trackUserBehavior(
                    userId: userId,
                    eventType: "test_event",
                    eventData: ["test": "true"],
                    sessionId: "test_session"
                )
                await MainActor.run {
                    testResults["Track Behavior"] = success ? "✅ Success" : "❌ Failed"
                    isTesting = false
                }
            } catch {
                await MainActor.run {
                    testResults["Track Behavior"] = "❌ Error: \(error.localizedDescription)"
                    isTesting = false
                }
            }
        }
    }
} 