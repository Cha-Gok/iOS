import SwiftUI

public struct MLXGemma4TestView: View {
    @State
    private var viewModel = MLXGemma4TestViewModel()

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                // Background Gradient
                LinearGradient(
                    colors: [.gray, .black],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 32) {
                    // Title Section
                    VStack(spacing: 8) {
                        Text("Gemma 4")
                            .font(.system(size: 42, weight: .black, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.point600, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )

                        Text("On-Device LLM Download Test")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 40)

                    Spacer()

                    // Status Card
                    VStack(spacing: 24) {
                        Image(systemName: viewModel.isLoaded ? "checkmark.circle.fill" : "cpu.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(
                                viewModel.isLoaded ? AnyShapeStyle(Color.green) :
                                    viewModel.isDownloading ? AnyShapeStyle(LinearGradient(
                                        colors: [Color.blue, Color.cyan],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )) :
                                    AnyShapeStyle(Color.gray.opacity(0.5))
                            )
                            .symbolEffect(.pulse, isActive: viewModel.isDownloading)

                        VStack(spacing: 12) {
                            Text(viewModel.status)
                                .font(.system(size: 18, weight: .semibold, design: .monospaced))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)

                            if !viewModel.modelInfo.isEmpty {
                                Text(viewModel.modelInfo)
                                    .font(.system(size: 14))
                                    .foregroundColor(.green.opacity(0.8))
                                    .padding(8)
                                    .background(Color.green.opacity(0.1))
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding(40)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 32))
                    .overlay(
                        RoundedRectangle(cornerRadius: 32)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    .padding(.horizontal, 24)

                    Spacer()

                    // Action Buttons
                    Group {
                        if viewModel.isLoaded {
                            NavigationLink(destination: MLXGemma4TestDetailView(viewModel: viewModel)) {
                                HStack {
                                    Image(systemName: "play.fill")
                                    Text("Test Model Features")
                                }
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 64)
                                .background(
                                    LinearGradient(
                                        colors: [.point600, .purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(Capsule())
                                .shadow(color: Color.green.opacity(0.3), radius: 10, x: 0, y: 5)
                            }
                        } else {
                            Button {
                                Task {
                                    await viewModel.download()
                                }
                            } label: {
                                HStack {
                                    if viewModel.isDownloading {
                                        ProgressView()
                                            .tint(.white)
                                            .padding(.trailing, 8)
                                    } else {
                                        Image(systemName: "arrow.down.circle.fill")
                                    }

                                    Text(viewModel.isDownloading ? "Downloading..." : "Start Download")
                                }
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 64)
                                .background(
                                    LinearGradient(
                                        colors: viewModel.isDownloading ? [Color.gray, Color.gray.opacity(0.5)] : [
                                            .point600,
                                            .purple
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(Capsule())
                                .shadow(color: Color.blue.opacity(0.3), radius: 10, x: 0, y: 5)
                            }
                            .disabled(viewModel.isDownloading)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
        }
    }
}
