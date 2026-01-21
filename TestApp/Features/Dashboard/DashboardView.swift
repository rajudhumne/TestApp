//
//  DashboardView.swift
//  TestApp
//
//  Created by Raju Dhumne on 16/01/26.
//

import SwiftUI

struct DashboardView: View {
    let userId: String
    let onLogout: () -> Void
    
    @State private var viewModel: DashboardViewModel
    
    // UI State for the "Push notification reception indicator"
    @State private var pushIndicatorColor: Color = .gray
    
    @MainActor
    init(userId: String, onLogout: @escaping () -> Void) {
        self.userId = userId
        self.onLogout = onLogout
        let recordRepo = RecordRepository(db: LocalDatabaseService.shared.getDBConnection())
        _viewModel = State(wrappedValue:
                            DashboardViewModel(userId: userId,
                                                            dataGeneratorService: DataGeneratorService(),
                                               llmClient: OllamaLLM(networkService: NetworkService()), recordsDbService: recordRepo, remoteRecordSync: SyncService(recordsRepository: recordRepo)))
    }
    
    var body: some View {
        HSplitView {
            // LEFT PANEL: Data Stream
            VStack(alignment: .leading) {
                Text("Live Data Stream")
                    .font(.headline)
                    .padding(.horizontal)
                
                List(viewModel.recentRecords) { record in
                    HStack {
                        Text("\(record.value)")
                            .font(.system(.body, design: .monospaced))
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                        
                        Spacer()
                        
                        Text(record.timestamp, style: .time)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        // Sync Status Icon
                        Image(systemName: record.isSynced ? "checkmark.icloud.fill" : "externaldrive.fill")
                            .foregroundColor(record.isSynced ? .green : .orange)
                            .help(record.isSynced ? "Synced to Cloud" : "Local Only")
                    }
                }
                .listStyle(.inset)
            }
            .frame(minWidth: 250, maxWidth: 350)
            
            // RIGHT PANEL: AI & Controls
            VStack(alignment: .leading, spacing: 20) {
                
                // 1. Header & Controls
                HStack {
                    VStack(alignment: .leading) {
                        Text("Dashboard")
                            .font(.largeTitle)
                        Text("User ID: \(userId.prefix(8))...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Push Notification Indicator
                    HStack {
                        Circle()
                            .fill(pushIndicatorColor)
                            .frame(width: 12, height: 12)
                        Text("Push Status")
                            .font(.caption)
                    }
                    .padding(8)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(8)
                    
                    Button("Logout", action: onLogout)
                }
                .padding()
                
                Divider()
                
                // 2. AI Section
                VStack(alignment: .leading, spacing: 10) {
                    Label("Latest AI Analysis", systemImage: "brain.head.profile")
                        .font(.title2)
                    
                    ScrollView {
                        Text(viewModel.latestAIResponse)
                            .font(.title3)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(nsColor: .textBackgroundColor))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                    }
                    .frame(height: 150)
                }
                .padding()
                
                Spacer()
                
                // Control Bar
                HStack {
                    Button(action: {  viewModel.start() }) {
                        Label("Start Stream", systemImage: "play.fill")
                    }
                    
                    Button(action: { viewModel.stop() }) {
                        Label("Stop Stream", systemImage: "stop.fill")
                    }
                }
                .padding()
            }
        }
        .onAppear {
            viewModel.start()
        }
        .onDisappear(perform: {
            viewModel.stop()
        })
        .onReceive(NotificationCenter.default.publisher(for: .syncCompleted)) { _ in
            // Flash the indicator Green when push arrives
            withAnimation { pushIndicatorColor = .green }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation { pushIndicatorColor = .gray }
            }
        }
    }
}

#Preview {
    DashboardView(userId: "raju") {
        
    }
}
