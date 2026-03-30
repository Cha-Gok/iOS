import Domain
import UIKit

/// UseCase 통합 테스트를 위한 샌드박스 목록 화면입니다.
public final class SandBoxTestViewController: UIViewController {
    private let dependency: SandboxDependency
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let waveformView = WaveformDisplayView()
    private var folder: Folder?

    public init(dependency: SandboxDependency) {
        self.dependency = dependency
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        title = "UseCase Sandbox"
        view.backgroundColor = .systemGroupedBackground

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UseCaseTestCell.self, forCellReuseIdentifier: UseCaseTestCell.identifier)
        tableView.translatesAutoresizingMaskIntoConstraints = false

        waveformView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(waveformView)
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            waveformView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            waveformView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            waveformView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            waveformView.heightAnchor.constraint(equalToConstant: 80),

            tableView.topAnchor.constraint(equalTo: waveformView.bottomAnchor, constant: 10),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func runTestCase(_ item: TestItem) {
        Task {
            do {
                let result = try await item.action(dependency)
                await showAlert(title: "성공", message: result)
            } catch {
                await showAlert(title: "실패", message: "\(error)")
            }
        }
    }

    private func showAlert(title: String, message: String) async {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - Section 구조 (권한, 언어, 폴더, 녹음, 기타 등등 추가 가능)

extension SandBoxTestViewController {
    /// Category 분류
    private enum Section: Int, CaseIterable {
        case authority = 0
        case language
        case folders
        case recording

        var title: String {
            switch self {
            case .authority: return "권한"
            case .language: return "언어"
            case .folders: return "폴더"
            case .recording: return "녹음"
            }
        }
    }
}

// MARK: - Items 구조 (권한, 언어, 폴더, 녹음, 기타 등등 추가 가능)

extension SandBoxTestViewController {
    private struct TestItem {
        let title: String
        let action: (SandboxDependency) async throws -> String
    }

    private var authorityItems: [TestItem] {
        [
            TestItem(title: "첫 진입 여부 확인", action: { dep in
                let result = dep.checkFirstLaunchUseCase.execute()
                return "첫 진입 여부: \(result)"
            }),
            TestItem(title: "마이크 권한 상태 확인", action: { dep in
                let status = try await dep.checkMicrophonePermissionUseCase.execute()
                return "현재 상태: \(status)"
            }),
            TestItem(title: "마이크 권한 요청", action: { dep in
                let status = try await dep.requestMicrophonePermissionUseCase.execute()
                return "요청 결과: \(status)"
            }),
            TestItem(title: "STT 권한 상태 확인", action: { dep in
                let status = try await dep.checkSTTPermissionUseCase.execute()
                return "현재 상태: \(status)"
            }),
            TestItem(title: "STT 권한 요청", action: { dep in
                let status = try await dep.requestSTTPermissionUseCase.execute()
                return "요청 결과: \(status)"
            })
        ]
    }

    private var languageItems: [TestItem] {
        [
            TestItem(title: "현재 언어 설정 조회", action: { dep in
                let lang = try await dep.fetchLanguageUseCase.execute()
                return "현재 언어: \(lang)"
            }),
            TestItem(title: "언어 변경 (임시: EN)", action: { dep in
                try await dep.selectLanguageUseCase.execute(lang: .en)
                return "영어로 변경 완료"
            }),
            TestItem(title: "언어 변경 (임시: KO)", action: { dep in
                try await dep.selectLanguageUseCase.execute(lang: .ko)
                return "한국어로 변경 완료"
            })
        ]
    }

    private var folderItems: [TestItem] {
        [
            TestItem(title: "새 폴더 '테스트 폴더' 생성", action: { dep in
                self.folder = try await dep.createFolderUseCase.execute(name: "테스트 폴더")
                return "생성됨: \(self.folder!.name)"
            }),

            TestItem(title: "모든 폴더 목록 조회", action: { dep in
                let folders = try await dep.readFolderUseCase.execute()
                return "총 \(folders.count)개의 폴더 발견"
            }),

            TestItem(title: "새 폴더 '테스트 폴더' 수정", action: { dep in
                let folder = try await dep.updateFolderUseCase.execute(self.folder!)
                return "수정됨: \(folder.name)"
            })
        ]
    }

    private var recordingItems: [TestItem] {
        [
            TestItem(title: "녹음 시작 (Start)", action: { [weak self] dep in
                let stream = try await dep.startRecordingUseCase.execute()
                self?.waveformView.reset()
                // 스트림을 소비하는 Task를 실행하여 녹음이 계속됨을 확인 (디버그 로그)
                Task {
                    for await waveform in stream {
                        self?.waveformView.update(with: waveform)
                    }
                    print("Sandbox: 파형 스트림 수신 종료")
                }
                return "녹음 세션 시작됨 (파형 스트림 생성 완료)"
            }),

            TestItem(title: "녹음 일시정지 (Pause)", action: { dep in
                try await dep.pauseRecordingUseCase.execute()
                return "녹음 일시정지됨"
            }),

            TestItem(title: "녹음 재시작 (Resume)", action: { dep in
                try await dep.resumeRecordingUseCase.execute()
                return "녹음 재개됨"
            }),

            TestItem(title: "녹음 종료 및 저장 (Finish)", action: { dep in
                let recorded = try await dep.finishRecordingUseCase.execute()
                return "완료!\n경로: \(recorded.audioFilePath.lastPathComponent)\n길이: \(String(format: "%.1f", recorded.duration))초"
            })
        ]
    }
}

extension SandBoxTestViewController: UITableViewDataSource, UITableViewDelegate {
    public func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sectionType = Section(rawValue: section) else { return 0 }
        switch sectionType {
        case .authority: return authorityItems.count
        case .language: return languageItems.count
        case .folders: return folderItems.count
        case .recording: return recordingItems.count
        }
    }

    public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return Section(rawValue: section)?.title
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: UseCaseTestCell.identifier,
            for: indexPath
        ) as? UseCaseTestCell,
            let sectionType = Section(rawValue: indexPath.section)
        else {
            return UITableViewCell()
        }

        let item: TestItem = switch sectionType {
        case .authority: authorityItems[indexPath.row]
        case .language: languageItems[indexPath.row]
        case .folders: folderItems[indexPath.row]
        case .recording: recordingItems[indexPath.row]
        }

        cell.configure(with: item.title)
        cell.onRunTapped = { [weak self] in
            self?.runTestCase(item)
        }

        return cell
    }
}
