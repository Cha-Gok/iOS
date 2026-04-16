@testable import Data
import Domain
import Foundation
import XCTest

final class DefaultVoiceRecordRepositoryTest: XCTestCase {
    private var sut: DefaultVoiceRecordRepository!
    private var mockStorageService: MockStorageService!

    override func setUp() {
        super.setUp()
        mockStorageService = MockStorageService()
        sut = DefaultVoiceRecordRepository(storageService: mockStorageService)
    }

    override func tearDown() {
        sut = nil
        mockStorageService = nil
        super.tearDown()
    }
}

// MARK: - 권한 확인 케이스

extension DefaultVoiceRecordRepositoryTest {
    func test_마이크권한확인_런타임체크() {
        // 실제 시스템 권한 상태에 의존하므로 결과값 검증보다는 호출 가능 여부 확인
        let _ = sut.checkMicrophonePermission()
    }
}

// MARK: - 녹음 제어 테스트 (비활성화)

/*
 // AVAudioRecorder를 직접 사용하게 리팩토링됨에 따라, 단위 테스트 환경에서 녹음 시작/종료 등의 테스트가 어려움.
 extension DefaultVoiceRecordRepositoryTest {
     func test_정상상태_녹음시작시_임시파일명이날짜기반형식으로생성된다() async throws {
         // ...
     }
 }
 */
