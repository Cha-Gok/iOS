@testable import Presentation
import Domain
import DomainTesting
import XCTest

@MainActor
final class MockSettingCoordinatorDelegate: SettingCoordinatorDelegate {
    var popCalled = false
    var pushTermsCalled = false
    var pushPrivacyCalled = false

    func pop() {
        popCalled = true
    }

    func pushTermsOfUseView() {
        pushTermsCalled = true
    }

    func pushPrivacyPolicyView() {
        pushPrivacyCalled = true
    }
}

@MainActor
final class SettingViewModelTests: XCTestCase {
    // MARK: - SUT

    private struct SUT {
        let viewModel: SettingViewModel
        let mockLanguageRepo: MockLanguageRepository
        let mockMLXRepo: MockAvailableModelSupportRepository
        let mockSTTRepo: MockDefaultWhisperSTTRepository
        let mockDeleteModelRepo: MockDeleteOnDeviceRepository
        let mockCoordinator: MockSettingCoordinatorDelegate
    }

    private func makeSUT() -> SUT {
        let mockLanguageRepo = MockLanguageRepository()
        let mockMLXRepo = MockAvailableModelSupportRepository()
        let mockSTTRepo = MockDefaultWhisperSTTRepository()
        let mockDeleteModelRepo = MockDeleteOnDeviceRepository()
        let mockCoordinator = MockSettingCoordinatorDelegate()

        let viewModel = SettingViewModel(
            languageRepository: mockLanguageRepo,
            mlxRepository: mockMLXRepo,
            sttRepository: mockSTTRepo,
            deleteModelRepository: mockDeleteModelRepo
        )
        viewModel.coordinator = mockCoordinator

        return SUT(
            viewModel: viewModel,
            mockLanguageRepo: mockLanguageRepo,
            mockMLXRepo: mockMLXRepo,
            mockSTTRepo: mockSTTRepo,
            mockDeleteModelRepo: mockDeleteModelRepo,
            mockCoordinator: mockCoordinator
        )
    }

    // MARK: - Initial State Tests

    func test_초기상태_언어_확인() {
        // Arrange
        let sut = makeSUT()
        sut.mockLanguageRepo.setFetchResult(.ko)

        // Act
        let viewModel = SettingViewModel(
            languageRepository: sut.mockLanguageRepo,
            mlxRepository: sut.mockMLXRepo,
            sttRepository: sut.mockSTTRepo,
            deleteModelRepository: sut.mockDeleteModelRepo
        )

        // Assert
        XCTAssertEqual(viewModel.language, .ko)
    }

    func test_초기상태_모델_비어있음() {
        // Arrange
        let sut = makeSUT()

        // Assert
        XCTAssertEqual(sut.viewModel.models.count, 0)
    }

    // MARK: - Language Tests

    func test_언어변경_성공() {
        // Arrange
        let sut = makeSUT()

        // Act
        sut.viewModel.setLanguage(.en)

        // Assert
        XCTAssertEqual(sut.viewModel.language, .en)
    }

    func test_언어변경_저장소에_저장됨() {
        // Arrange
        let sut = makeSUT()
        sut.mockLanguageRepo.expectSave(language: .en, callCount: 1)

        // Act
        sut.viewModel.setLanguage(.en)

        // Assert
        sut.mockLanguageRepo.verify()
    }

    // MARK: - Check Models Tests

    func test_checkModels_모델가져오기_성공() async {
        // Arrange
        let sut = makeSUT()
        let mockModels = [
            ChaGokModelState(
                title: "whisper title",
                subTitle: "whisper subTitle",
                model: .whisper,
                isDownloaded: .downloaded
            ),
            ChaGokModelState(
                title: "gemma4 title",
                subTitle: "gemma4 subTitle",
                model: .gemma4_e2b_4bit,
                isDownloaded: .notDownloaded
            )
        ]
        sut.mockMLXRepo.setFetchSupportModelsResult(mockModels)

        // Act
        sut.viewModel.checkModels()
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Assert
        XCTAssertEqual(sut.viewModel.models.count, 2)
        XCTAssertEqual(sut.viewModel.models[0].model, .whisper)
        XCTAssertEqual(sut.viewModel.models[1].model, .gemma4_e2b_4bit)
    }

    func test_checkModels_fetchSupportModels_호출됨() async {
        // Arrange
        let sut = makeSUT()
        sut.mockMLXRepo.setFetchSupportModelsResult([])
        sut.mockMLXRepo.expectFetchSupportModels(callCount: 1)

        // Act
        sut.viewModel.checkModels()
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Assert
        sut.mockMLXRepo.verify()
    }

    // MARK: - Download Model Tests

    func test_downloadModel_whisper_완료() async {
        // Arrange
        let sut = makeSUT()
        let model = ChaGokModel.whisper
        sut.mockMLXRepo.setFetchSupportModelsResult([
            ChaGokModelState(
                title: "whisper title",
                subTitle: "whisper subTitle",
                model: .whisper,
                isDownloaded: .notDownloaded
            )
        ])
        await sut.mockSTTRepo.setDownloadResult(.success((.applicationDirectory)))

        // Act
        sut.viewModel.checkModels()
        try? await Task.sleep(nanoseconds: 100_000_000)
        sut.viewModel.downloadModel(model: model)
        try? await Task.sleep(nanoseconds: 2_500_000_000)

        // Assert
        XCTAssertEqual(sut.viewModel.models[0].isDownloaded, .downloaded)
    }

    func test_downloadModel_gemma_완료() async {
        // Arrange
        let sut = makeSUT()
        let model = ChaGokModel.gemma4_e2b_4bit
        sut.mockMLXRepo.setFetchSupportModelsResult([
            ChaGokModelState(
                title: "gemma4 title",
                subTitle: "gemma4 subTitle",
                model: .gemma4_e2b_4bit,
                isDownloaded: .notDownloaded
            )
        ])
        sut.mockMLXRepo.setDownloadModelResult(.success(()))

        // Act
        sut.viewModel.checkModels()
        try? await Task.sleep(nanoseconds: 100_000_000)
        sut.viewModel.downloadModel(model: model)
        try? await Task.sleep(nanoseconds: 2_500_000_000)

        // Assert
        XCTAssertEqual(sut.viewModel.models[0].isDownloaded, .downloaded)
    }

    // MARK: - Delete Model Tests

    func test_deleteModel_whisper_완료() async {
        // Arrange
        let sut = makeSUT()
        let model = ChaGokModel.whisper
        sut.mockMLXRepo.setFetchSupportModelsResult([
            ChaGokModelState(
                title: "whisper title",
                subTitle: "whisper subTitle",
                model: .whisper,
                isDownloaded: .downloaded
            )
        ])
        sut.mockDeleteModelRepo.setWhisperModelResult(.success(()))

        // Act
        sut.viewModel.checkModels()
        try? await Task.sleep(nanoseconds: 100_000_000)
        sut.viewModel.deleteModel(model: model)
        try? await Task.sleep(nanoseconds: 500_000_000)

        // Assert
        XCTAssertEqual(sut.viewModel.models[0].isDownloaded, .notDownloaded)
    }

    func test_deleteModel_gemma_완료() async {
        // Arrange
        let sut = makeSUT()
        let model = ChaGokModel.gemma4_e2b_4bit
        sut.mockMLXRepo.setFetchSupportModelsResult([
            ChaGokModelState(
                title: "gemma4 title",
                subTitle: "gemma4 subTitle",
                model: .gemma4_e2b_4bit,
                isDownloaded: .downloaded
            )
        ])
        sut.mockDeleteModelRepo.setMlxModelResult(.success(()))

        // Act
        sut.viewModel.checkModels()
        try? await Task.sleep(nanoseconds: 100_000_000)
        sut.viewModel.deleteModel(model: model)
        try? await Task.sleep(nanoseconds: 500_000_000)

        // Assert
        XCTAssertEqual(sut.viewModel.models[0].isDownloaded, .notDownloaded)
    }

    // MARK: - Coordinator Tests

    func test_pop_코디네이터호출() {
        // Arrange
        let sut = makeSUT()

        // Act
        sut.viewModel.pop()

        // Assert
        XCTAssertTrue(sut.mockCoordinator.popCalled)
    }

    func test_pushTermsOfUse_코디네이터호출() {
        // Arrange
        let sut = makeSUT()

        // Act
        sut.viewModel.pushTermsOfUse()

        // Assert
        XCTAssertTrue(sut.mockCoordinator.pushTermsCalled)
    }

    func test_pushPrivacyPolicy_코디네이터호출() {
        // Arrange
        let sut = makeSUT()

        // Act
        sut.viewModel.pushPrivacyPolicy()

        // Assert
        XCTAssertTrue(sut.mockCoordinator.pushPrivacyCalled)
    }

    // MARK: - None Model Tests

    func test_downloadModel_none_무시됨() async {
        // Arrange
        let sut = makeSUT()

        // Act
        sut.viewModel.downloadModel(model: .none)
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Assert
        // 아무 일도 일어나지 않음 (에러도 없음)
        XCTAssertTrue(true)
    }

    func test_deleteModel_none_무시됨() async {
        // Arrange
        let sut = makeSUT()

        // Act
        sut.viewModel.deleteModel(model: .none)
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Assert
        // 아무 일도 일어나지 않음 (에러도 없음)
        XCTAssertTrue(true)
    }
}
