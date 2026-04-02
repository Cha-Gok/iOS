@testable import Presentation
import Domain
import DomainTests
import XCTest

@MainActor
final class MockNavigationDelegate: NavigationDelegate {
    var finishOnBoardingCalled = false
    var finishOnBoardingExpectation: XCTestExpectation?

    func finishOnBoarding() {
        finishOnBoardingCalled = true
        finishOnBoardingExpectation?.fulfill()
    }
}

@MainActor
final class OnBoardingViewModelTests: XCTestCase {
    // MARK: - Helpers

    private func makeSUT() -> (
        sut: OnBoardingViewModel,
        mockLanguageRepo: MockLanguageRepository,
        mockVoiceRecordRepo: MockVoiceRecordRepository,
        mockCheckFirstLaunchRepo: MockCheckFirstLaunchRepository,
        mockNavDelegate: MockNavigationDelegate
    ) {
        let mockLanguageRepo = MockLanguageRepository()
        let mockVoiceRecordRepo = MockVoiceRecordRepository()
        let mockCheckFirstLaunchRepo = MockCheckFirstLaunchRepository()
        let mockNavDelegate = MockNavigationDelegate()

        let sut = OnBoardingViewModel(
            selectLanguageUseCase: DefaultSelectLanguageUseCase(repository: mockLanguageRepo),
            checkMicrophonePermissionUseCase: DefaultCheckMicrophonePermissionUseCase(
                repository: mockVoiceRecordRepo
            ),
            requestMicrophonePermissionUseCase: DefaultRequestMicrophonePermissionUseCase(
                repository: mockVoiceRecordRepo
            ),
            checkFirstLaunchUseCase: DefaultCheckFirstLaunchUseCase(repository: mockCheckFirstLaunchRepo)
        )
        sut.navDelegate = mockNavDelegate

        return (sut, mockLanguageRepo, mockVoiceRecordRepo, mockCheckFirstLaunchRepo, mockNavDelegate)
    }

    // MARK: - State Tests

    func test_뷰모델생성시_초기화된경우_초기값을확인한다() {
        let (sut, _, _, _, _) = makeSUT()

        XCTAssertEqual(sut.currentStep, .first)
        XCTAssertEqual(sut.steps.count, 4)
        XCTAssertEqual(sut.getMaxIndex(), 4)
        XCTAssertEqual(sut.primaryButtonTitle, "다음")
        XCTAssertEqual(sut.secondButtonTitle, "건너뛰기")
        XCTAssertTrue(sut.isSecondButtonEnabled)
        XCTAssertFalse(sut.isFinalStep)
        XCTAssertEqual(sut.language, .ko)
    }

    func test_언어설정시_상태가_업데이트된다() {
        let (sut, _, _, _, _) = makeSUT()

        sut.setLanguage(.en)
        XCTAssertEqual(sut.language, .en)
    }

    func test_마지막스텝인경우_버튼타이틀과_상태가_변경된다() {
        let (sut, _, _, _, _) = makeSUT()

        sut.syncPageState(nextStep: Step.finish.rawValue) // 3

        XCTAssertEqual(sut.currentStep, .finish)
        XCTAssertEqual(sut.primaryButtonTitle, "시작하기")
        XCTAssertEqual(sut.secondButtonTitle, "")
        XCTAssertFalse(sut.isSecondButtonEnabled)
        XCTAssertTrue(sut.isFinalStep)
    }

    // MARK: - Action Tests

    func test_syncPageState호출시_마이크권한스텝이면_권한을_요청한다() async {
        let (sut, _, mockVoiceRecordRepo, _, _) = makeSUT()

        await mockVoiceRecordRepo.setCheckPermissionResult(.success(.notDetermined))
        await mockVoiceRecordRepo.setRequestPermissionResult(.success(.authorized))

        sut.syncPageState(nextStep: Step.micPermission.rawValue)

        // Task 내부 비동기 호출 대기 (안전하게 0.3초 대기)
        try? await Task.sleep(nanoseconds: 300_000_000)

        await mockVoiceRecordRepo.expectCheckPermission(callCount: 1)
        await mockVoiceRecordRepo.expectRequestPermission(callCount: 1)
        await mockVoiceRecordRepo.verify()
    }

    func test_primaryButtonAction_첫스텝에서_다음스텝으로_이동한다() {
        let (sut, _, _, _, _) = makeSUT()

        var scrolledIndex: Int?
        sut.primaryButtonAction { nextIndex in
            scrolledIndex = nextIndex
        }

        XCTAssertEqual(scrolledIndex, Step.second.rawValue) // 1
    }

    func test_primaryButtonAction_마지막스텝에서_온보딩을_완료하고_화면을_전환한다() async {
        let (sut, mockLanguageRepo, _, mockCheckFirstLaunchRepo, mockNavDelegate) = makeSUT()

        sut.syncPageState(nextStep: Step.finish.rawValue)

        await mockLanguageRepo.setSaveResult(.success(()))
        mockCheckFirstLaunchRepo.setReturnValue(true)

        let expectation = XCTestExpectation(description: "finishOnBoarding 호출")
        mockNavDelegate.finishOnBoardingExpectation = expectation

        sut.primaryButtonAction { _ in }

        await fulfillment(of: [expectation], timeout: 1.0)

        XCTAssertTrue(mockNavDelegate.finishOnBoardingCalled)

        // 언어 저장 확인
        await mockLanguageRepo.expectSave(language: .ko, callCount: 1)
        await mockLanguageRepo.verify()

        // 첫 실행 마킹 확인
        mockCheckFirstLaunchRepo.expectCheckAndMarkFirstLaunch(callCount: 1)
        mockCheckFirstLaunchRepo.verify()
    }

    func test_secondButtonAction_첫스텝에서_건너뛰기를_누르면_마이크권한화면으로_이동한다() {
        let (sut, _, _, _, _) = makeSUT()

        var scrolledIndex: Int?
        sut.secondButtonAction { nextIndex in
            scrolledIndex = nextIndex
        }

        XCTAssertEqual(scrolledIndex, Step.micPermission.rawValue)
    }

    func test_secondButtonAction_중간스텝에서_이전버튼을_누르면_이전스텝으로_이동한다() async {
        let (sut, _, mockVoiceRecordRepo, _, _) = makeSUT()

        // Background Task가 실행되므로 미리 모의 객체(Mock) 응답을 세팅해 두어야 에러(미설정)가 나지 않습니다.
        await mockVoiceRecordRepo.setCheckPermissionResult(.success(.notDetermined))
        await mockVoiceRecordRepo.setRequestPermissionResult(.success(.authorized))

        sut.syncPageState(nextStep: Step.micPermission.rawValue)

        // 백그라운드 Task가 안전하게 완료될 수 있도록 약간의 딜레이 부여
        try? await Task.sleep(nanoseconds: 300_000_000)

        var scrolledIndex: Int?
        sut.secondButtonAction { nextIndex in
            scrolledIndex = nextIndex
        }

        XCTAssertEqual(scrolledIndex, Step.second.rawValue)
    }
}
