import SwiftUI
import UniformTypeIdentifiers

// MARK: - Feature Menu (Entry Point)

public struct MLXGemma4TestDetailView: View {
    @Bindable
    var viewModel: MLXGemma4TestViewModel

    public init(viewModel: MLXGemma4TestViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ZStack {
            LinearGradient(
                colors: [.black, .gray.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.green, .teal],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )

                        Text("모델 준비 완료")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)

                        Text("테스트할 기능을 선택하세요")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 10)

                    // Feature Cards
                    NavigationLink(destination: ChatFeatureView(viewModel: viewModel)) {
                        FeatureCard(
                            icon: "bubble.left.and.bubble.right.fill",
                            title: "채팅",
                            description: "Gemma 4와 자유롭게 대화하세요",
                            gradientColors: [.blue, .cyan]
                        )
                    }

                    NavigationLink(destination: SummarizeFeatureView(viewModel: viewModel)) {
                        FeatureCard(
                            icon: "doc.text.magnifyingglass",
                            title: "3줄 요약",
                            description: "긴 텍스트를 3줄로 요약합니다",
                            gradientColors: [.purple, .indigo]
                        )
                    }

                    NavigationLink(destination: GrammarFixView(viewModel: viewModel)) {
                        FeatureCard(
                            icon: "pencil.and.outline",
                            title: "문법 교정",
                            description: "어색한 문장을 자연스럽게 다듬어줍니다",
                            gradientColors: [.orange, .yellow]
                        )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("테스트 기능")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Feature Card Component

private struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String
    let gradientColors: [Color]

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundStyle(
                    LinearGradient(
                        colors: gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 56, height: 56)
                .background(gradientColors[0].opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 16))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)

                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.gray.opacity(0.5))
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

// MARK: - 1) Chat Feature View

struct ChatFeatureView: View {
    @Bindable
    var viewModel: MLXGemma4TestViewModel
    @State
    private var inputText: String = ""

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 16) {
                            if viewModel.messages.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "bubble.left.and.bubble.right")
                                        .font(.system(size: 40))
                                        .foregroundColor(.gray.opacity(0.3))
                                    Text("Gemma 4와 대화를 시작해보세요")
                                        .foregroundColor(.gray)
                                }
                                .padding(.top, 60)
                            }

                            ForEach(viewModel.messages) { message in
                                HStack {
                                    if message.role == .user { Spacer() }

                                    Text(message.content)
                                        .padding(12)
                                        .background(
                                            message.role == .user
                                                ? AnyShapeStyle(LinearGradient(
                                                    colors: [.blue, .cyan],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ))
                                                : AnyShapeStyle(Color.white.opacity(0.1))
                                        )
                                        .foregroundColor(.white)
                                        .cornerRadius(16)
                                        .id(message.id)

                                    if message.role == .assistant { Spacer() }
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                    }
                    .onChange(of: viewModel.messages) {
                        if let last = viewModel.messages.last {
                            withAnimation {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                }

                // Input
                VStack(spacing: 8) {
                    HStack(alignment: .bottom) {
                        TextField("메시지를 입력하세요...", text: $inputText, axis: .vertical)
                            .lineLimit(1 ... 5)
                            .padding(12)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                            .foregroundColor(.white)

                        Button {
                            let text = inputText
                            inputText = ""
                            Task {
                                await viewModel.generateResponse(prompt: text)
                            }
                        } label: {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .padding(12)
                                .background(
                                    LinearGradient(
                                        colors: [.blue, .cyan],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .clipShape(Circle())
                        }
                        .disabled(inputText.isEmpty || viewModel.status == "Generating...")
                    }
                    .padding(.horizontal)

                    if viewModel.status == "Generating..." {
                        HStack(spacing: 6) {
                            ProgressView().tint(.gray).scaleEffect(0.8)
                            Text(viewModel.status)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(.vertical, 12)
                .background(Color.gray.opacity(0.1))
            }
        }
        .navigationTitle("채팅")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - 2) Summarize Feature View

struct SummarizeFeatureView: View {
    @Bindable
    var viewModel: MLXGemma4TestViewModel
    @State
    private var inputText: String = ""

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Input section
                    VStack(alignment: .leading, spacing: 8) {
                        Label("원문 입력", systemImage: "text.alignleft")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.gray)

                        TextEditor(text: $inputText)
                            .scrollContentBackground(.hidden)
                            .foregroundColor(.white)
                            .padding(12)
                            .frame(minHeight: 150)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                    }

                    // Action button
                    Button {
                        Task {
                            await viewModel.summarizeToThreeLines(text: inputText)
                        }
                    } label: {
                        HStack {
                            if viewModel.isSummarizing {
                                ProgressView().tint(.white).padding(.trailing, 4)
                            }
                            Image(systemName: "sparkles")
                            Text(viewModel.isSummarizing ? "요약 중..." : "3줄 요약하기")
                        }
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            LinearGradient(
                                colors: [.purple, .indigo],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                    }
                    .disabled(inputText.isEmpty || viewModel.isSummarizing)

                    // Result section
                    if !viewModel.summaryOutput.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("요약 결과", systemImage: "doc.text")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.purple)

                            Text(viewModel.summaryOutput)
                                .foregroundColor(.white)
                                .padding(16)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.purple.opacity(0.1))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.purple.opacity(0.2), lineWidth: 1)
                                )
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .padding(24)
            }
        }
        .navigationTitle("3줄 요약")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - 3) Grammar Fix View

struct GrammarFixView: View {
    @Bindable
    var viewModel: MLXGemma4TestViewModel
    @State
    private var inputText: String = ""

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Input section
                    VStack(alignment: .leading, spacing: 8) {
                        Label("원문 입력", systemImage: "text.badge.plus")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.gray)

                        TextEditor(text: $inputText)
                            .scrollContentBackground(.hidden)
                            .foregroundColor(.white)
                            .padding(12)
                            .frame(minHeight: 150)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                    }

                    // Action button
                    Button {
                        Task {
                            await viewModel.fixGrammar(text: inputText)
                        }
                    } label: {
                        HStack {
                            if viewModel.isFixingGrammar {
                                ProgressView().tint(.white).padding(.trailing, 4)
                            }
                            Image(systemName: "wand.and.stars")
                            Text(viewModel.isFixingGrammar ? "교정 중..." : "문법 교정하기")
                        }
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            LinearGradient(
                                colors: [.orange, .yellow],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                    }
                    .disabled(inputText.isEmpty || viewModel.isFixingGrammar)

                    // Result section
                    if !viewModel.grammarResult.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("교정 결과", systemImage: "checkmark.circle.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.orange)

                            Text(viewModel.grammarResult)
                                .foregroundColor(.white)
                                .padding(16)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.orange.opacity(0.1))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                                )
                                .textSelection(.enabled)
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .padding(24)
            }
        }
        .navigationTitle("문법 교정")
        .navigationBarTitleDisplayMode(.inline)
    }
}
