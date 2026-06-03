@testable import Presentation
import Domain
import DomainTesting
import XCTest

@MainActor
final class MockNavigationDelegate: OnboardingCoordinatorDelegate {
    var finishOnBoardingCalled = false
    var finishOnBoardingExpectation: XCTestExpectation?

    func finishOnBoarding() {
        finishOnBoardingCalled = true
        finishOnBoardingExpectation?.fulfill()
    }
}

@MainActor
final class OnBoardingViewModelTests: XCTestCase {
    // MARK: - SUT

    private struct SUT {
        let viewModel: OnBoardingViewModel
        let mockLanguageRepo: MockLanguageRepository
        let mockVoiceRecordRepo: MockVoiceRecordRepository
        let mockSTTRepo: MockSTTRepository
        let mockCheckFirstLaunchRepo: MockCheckFirstLaunchRepository
        let mockFolderRepo: MockFolderRepository
        let mockNavDelegate: MockNavigationDelegate
        let mockAvailableModelRepo: MockAvailableModelSupportRepository
        let mockMLXRepo: MockOnDeviceRepository
    }

    private func makeSUT() -> SUT {
        let mockLanguageRepo = MockLanguageRepository()
        let mockVoiceRecordRepo = MockVoiceRecordRepository()
        let mockSTTRepo = MockSTTRepository()
        let mockCheckFirstLaunchRepo = MockCheckFirstLaunchRepository()
        let mockFolderRepo = MockFolderRepository()
        let mockNavDelegate = MockNavigationDelegate()
        let mockAvailableModelRepo = MockAvailableModelSupportRepository()
        let mockMLXRepo = MockOnDeviceRepository()

        let viewModel = OnBoardingViewModel(
            languageRepository: mockLanguageRepo,
            voiceRecordRepository: mockVoiceRecordRepo,
            sttRepository: mockSTTRepo,
            checkFirstLaunchRepository: mockCheckFirstLaunchRepo,
            folderUseCase: DefaultFolderUseCase(repository: mockFolderRepo),
            availableSupportModelRepository: mockAvailableModelRepo,
            mlxRepository: mockMLXRepo
        )
        viewModel.onBoardingCoordinator = mockNavDelegate

        return SUT(
            viewModel: viewModel,
            mockLanguageRepo: mockLanguageRepo,
            mockVoiceRecordRepo: mockVoiceRecordRepo,
            mockSTTRepo: mockSTTRepo,
            mockCheckFirstLaunchRepo: mockCheckFirstLaunchRepo,
            mockFolderRepo: mockFolderRepo,
            mockNavDelegate: mockNavDelegate,
            mockAvailableModelRepo: mockAvailableModelRepo,
            mockMLXRepo: mockMLXRepo
        )
    }

    // MARK: - State Tests

    func test_뷰모델생성시_초기화된경우_초기값을확인한다() {
        let sut = makeSUT()

        XCTAssertEqual(sut.viewModel.currentStep, .first)
        XCTAssertEqual(sut.viewModel.steps.count, 5)
        XCTAssertEqual(sut.viewModel.primaryButtonTitle, "다음")
        XCTAssertEqual(sut.viewModel.secondButtonTitle, "건너뛰기")
        XCTAssertTrue(sut.viewModel.isSecondButtonEnabled)
        XCTAssertEqual(sut.viewModel.language, .ko)
    }

    func test_언어설정시_상태가_업데이트된다() {
        let sut = makeSUT()

        sut.viewModel.setLanguage(.en)
        XCTAssertEqual(sut.viewModel.language, .en)
    }

    func test_마지막스텝인경우_버튼타이틀과_상태가_변경된다() {
        let sut = makeSUT()

        sut.viewModel.syncPageState(nextStep: Step.finish.rawValue) // 4

        XCTAssertEqual(sut.viewModel.currentStep, .finish)
        XCTAssertEqual(sut.viewModel.primaryButtonTitle, "시작하기")
        XCTAssertEqual(sut.viewModel.secondButtonTitle, "")
        XCTAssertFalse(sut.viewModel.isSecondButtonEnabled)
    }

    // MARK: - Action Tests

    func test_syncPageState호출시_마이크권한스텝이면_권한을_요청한다() async {
        let sut = makeSUT()

        // Mic
        await sut.mockVoiceRecordRepo.setCheckPermissionResult(.notDetermined)
        await sut.mockVoiceRecordRepo.setRequestPermissionResult(.success(.authorized))
        // STT
        await sut.mockSTTRepo.setCheckResult(.notDetermined)
        await sut.mockSTTRepo.setRequestResult(.success(.authorized))

        sut.viewModel.syncPageState(nextStep: Step.micPermission.rawValue)

        // Task 내부 비동기 호출 대기 (안전하게 0.3초 대기)
        try? await Task.sleep(nanoseconds: 300_000_000)

        // Mic 검증
        await sut.mockVoiceRecordRepo.expectCheckPermission(callCount: 1)
        await sut.mockVoiceRecordRepo.expectRequestPermission(callCount: 1)
        await sut.mockVoiceRecordRepo.verify()

        // STT 검증
        await sut.mockSTTRepo.expectCheckSTTPermission(callCount: 1)
        await sut.mockSTTRepo.expectRequestSTTPermission(callCount: 1)
        await sut.mockSTTRepo.verify()
    }

    func test_primaryButtonAction_첫스텝에서_다음스텝으로_이동한다() {
        let sut = makeSUT()

        var scrolledIndex: Int?
        sut.viewModel.primaryButtonAction { nextIndex in
            scrolledIndex = nextIndex
        }

        XCTAssertEqual(scrolledIndex, Step.second.rawValue) // 1
    }

    func test_primaryButtonAction_마지막스텝에서_온보딩을_완료하고_화면을_전환한다() async {
        let sut = makeSUT()

        sut.viewModel.syncPageState(nextStep: Step.finish.rawValue)

        sut.mockCheckFirstLaunchRepo.setReturnValue(true)
        sut.mockFolderRepo.setCreateResult(.success(Folder(name: Policy.defaultFolderName, kind: .default)))
        // 기본 폴더 + 휴지통 폴더 두 번 생성됨
        sut.mockFolderRepo.expectCreate(callCount: 2)

        let expectation = XCTestExpectation(description: "finishOnBoarding 호출")
        sut.mockNavDelegate.finishOnBoardingExpectation = expectation

        sut.viewModel.primaryButtonAction { _ in }

        await fulfillment(of: [expectation], timeout: 1.0)

        XCTAssertTrue(sut.mockNavDelegate.finishOnBoardingCalled)

        // 언어 저장 확인
        sut.mockLanguageRepo.expectSave(language: .ko, callCount: 1)
        sut.mockLanguageRepo.verify()

        // 첫 실행 마킹 확인
        sut.mockCheckFirstLaunchRepo.expectCheckAndMarkFirstLaunch(callCount: 1)
        sut.mockCheckFirstLaunchRepo.verify()

        // 기본 폴더 생성 확인
        sut.mockFolderRepo.verify()
    }

    func test_secondButtonAction_첫스텝에서_건너뛰기를_누르면_마이크권한화면으로_이동한다() {
        let sut = makeSUT()

        var scrolledIndex: Int?
        sut.viewModel.secondButtonAction { nextIndex in
            scrolledIndex = nextIndex
        }

        XCTAssertEqual(scrolledIndex, Step.micPermission.rawValue)
    }

    func test_secondButtonAction_중간스텝에서_이전버튼을_누르면_이전스텝으로_이동한다() async {
        let sut = makeSUT()

        // Background Task가 실행되므로 미리 모의 객체(Mock) 응답을 세팅해 두어야 에러(미설정)가 나지 않습니다.
        // Mic
        await sut.mockVoiceRecordRepo.setCheckPermissionResult(.notDetermined)
        await sut.mockVoiceRecordRepo.setRequestPermissionResult(.success(.authorized))
        // STT
        await sut.mockSTTRepo.setCheckResult(.notDetermined)
        await sut.mockSTTRepo.setRequestResult(.success(.authorized))

        sut.viewModel.syncPageState(nextStep: Step.micPermission.rawValue)

        // 백그라운드 Task가 안전하게 완료될 수 있도록 약간의 딜레이 부여
        try? await Task.sleep(nanoseconds: 300_000_000)

        var scrolledIndex: Int?
        sut.viewModel.secondButtonAction { nextIndex in
            scrolledIndex = nextIndex
        }

        XCTAssertEqual(scrolledIndex, Step.second.rawValue)
    }

    func test_checkModelSupport호출시_지원하는기기이면_modelSupport가true가된다() async {
        let sut = makeSUT()

        sut.mockAvailableModelRepo.setCheckSupportModelResult(ChaGokModelSupport(ramSizeGB: 8, isProUser: false))
        sut.mockAvailableModelRepo.expectCheckSupportModel(callCount: 1)

        await sut.viewModel.checkModelSupport()

        sut.mockAvailableModelRepo.verify()
        XCTAssertTrue(sut.viewModel.modelSupport)
        XCTAssertEqual(sut.viewModel.status.storage, .notDownloaded)
    }

    func test_primaryButtonAction_다운로드스텝에서_성공적으로_다운로드하면_상태가_downloaded가된다() async {
        let sut = makeSUT()

        sut.mockAvailableModelRepo.setCheckSupportModelResult(ChaGokModelSupport(ramSizeGB: 8, isProUser: false))
        sut.mockAvailableModelRepo.expectCheckSupportModel(callCount: 1)
        sut.mockMLXRepo.downloadResult = .success(())

        await sut.viewModel.checkModelSupport()
        sut.viewModel.syncPageState(nextStep: Step.download.rawValue)

        sut.viewModel.primaryButtonAction { _ in }
        try? await Task.sleep(nanoseconds: 300_000_000) // 다운로드 완료 비동기 대기

        sut.mockAvailableModelRepo.verify()
        XCTAssertEqual(sut.mockMLXRepo.actualDownloadCallCount, 1)
        XCTAssertEqual(sut.viewModel.status.storage, .downloaded)
    }

    func test_checkModelSupport호출시_RAM이4GB이하로부족하면_modelSupport가false가된다() async {
        let sut = makeSUT()

        sut.mockAvailableModelRepo.setCheckSupportModelResult(ChaGokModelSupport(ramSizeGB: 4, isProUser: false))
        sut.mockAvailableModelRepo.expectCheckSupportModel(callCount: 1)

        await sut.viewModel.checkModelSupport()

        sut.mockAvailableModelRepo.verify()
        XCTAssertFalse(sut.viewModel.modelSupport)
    }
}
