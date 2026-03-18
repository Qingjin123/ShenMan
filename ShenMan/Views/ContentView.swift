import SwiftUI

/// 主内容视图
/// 根据应用状态显示不同的页面
struct ContentView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        ZStack {
            // 根据当前视图状态显示不同页面
            switch appState.currentView {
            case .home:
                HomeView()

            case .transcribing:
                TranscribingView()

            case .result:
                ResultView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .fileImporter(
            isPresented: $appState.showFileImporter,
            allowedContentTypes: [.audio, .movie, .mp3, .wav, .mpeg4Movie, .quickTimeMovie],
            allowsMultipleSelection: false,
            onCompletion: { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first {
                        // 需要访问安全书卷才能读取文件
                        guard url.startAccessingSecurityScopedResource() else {
                            appState.showError("无法访问文件")
                            return
                        }
                        
                        Task {
                            await appState.loadAndTranscribeAudioFile(url: url)
                            url.stopAccessingSecurityScopedResource()
                        }
                    }
                case .failure(let error):
                    appState.showError(error.localizedDescription)
                }
            }
        )
        .alert("错误", isPresented: .init(
            get: { appState.errorMessage != nil },
            set: { if !$0 { appState.clearError() } }
        )) {
            Button("确定", role: .cancel) {
                appState.clearError()
            }
        } message: {
            if let message = appState.errorMessage {
                Text(message)
            }
        }
        .sheet(isPresented: $appState.showHistory) {
            HistoryListView()
                .environmentObject(appState)
        }
        .sheet(isPresented: $appState.showModelPicker) {
            ModelPickerView()
                .environmentObject(appState)
        }
        .sheet(isPresented: $appState.showBatchImport) {
            BatchImportView()
                .environmentObject(appState)
        }
        .sheet(isPresented: $appState.showBatchExport) {
            BatchExportView(results: appState.batchExportResults)
                .environmentObject(appState)
        }
        .sheet(isPresented: $appState.showSettings) {
            SettingsView()
                .environmentObject(appState)
        }
    }
}
