import Domain
import UIKit

final class AudioPlayerView: UIView {
    var onPlayPause: (() -> Void)?
    var onRewind: (() -> Void)?
    var onForward: (() -> Void)?
    var onSeekBegan: (() -> Void)?
    var onSeekEnded: ((TimeInterval) -> Void)?

    var audioPlayerObservable: VoiceNoteViewModel.AudioPlayerObservable?

    private let currentTimeLabel: UILabel = {
        let label = UILabel()
        label.setTypography(style: .label)
        label.textColor = .gray750
        return label
    }()

    private let totalDurationLabel: UILabel = {
        let label = UILabel()
        label.setTypography(style: .label)
        label.textColor = .gray750

        return label
    }()

    private let rewindButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.image = .rewind
        config.baseForegroundColor = .gray900

        return UIButton(configuration: config)
    }()

    private let playPauseButton: UIButton = {
        var config = UIButton.Configuration.clearGlass()
        config.image = .play
        config.baseForegroundColor = .white
        config.background.backgroundColor = .point700
        config.background.cornerRadius = 99

        return UIButton(configuration: config)
    }()

    private let forwardButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.image = .forward
        config.baseForegroundColor = .gray900

        return UIButton(configuration: config)
    }()

    private let progressSlider = UISlider()

    private lazy var durationStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .equalSpacing
        stackView.addArrangedSubview(currentTimeLabel)
        stackView.addArrangedSubview(totalDurationLabel)

        return stackView
    }()

    private lazy var buttonStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .equalSpacing
        stackView.spacing = 35
        stackView.addArrangedSubview(rewindButton)
        stackView.addArrangedSubview(playPauseButton)
        stackView.addArrangedSubview(forwardButton)

        return stackView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupActions()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    private func setupUI() {
        backgroundColor = .gray0

        for view in [progressSlider, durationStackView, buttonStackView] {
            view.translatesAutoresizingMaskIntoConstraints = false
            addSubview(view)
        }

        NSLayoutConstraint.activate([
            rewindButton.widthAnchor.constraint(equalToConstant: 60),
            rewindButton.heightAnchor.constraint(equalToConstant: 60),

            playPauseButton.widthAnchor.constraint(equalToConstant: 120),
            playPauseButton.heightAnchor.constraint(equalToConstant: 60),

            forwardButton.widthAnchor.constraint(equalToConstant: 60),
            forwardButton.heightAnchor.constraint(equalToConstant: 60),

            progressSlider.topAnchor.constraint(equalTo: topAnchor),
            progressSlider.leadingAnchor.constraint(equalTo: leadingAnchor),
            progressSlider.trailingAnchor.constraint(equalTo: trailingAnchor),

            durationStackView.topAnchor.constraint(equalTo: progressSlider.bottomAnchor, constant: 18),
            durationStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            durationStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),

            buttonStackView.topAnchor.constraint(equalTo: durationStackView.bottomAnchor, constant: 9),
            buttonStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 40),
            buttonStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -40),
            buttonStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -46)
        ])
    }

    private func setupActions() {
        rewindButton.addAction(UIAction { [weak self] _ in self?.onRewind?() }, for: .touchUpInside)
        playPauseButton.addAction(UIAction { [weak self] _ in self?.onPlayPause?() }, for: .touchUpInside)
        forwardButton.addAction(UIAction { [weak self] _ in self?.onForward?() }, for: .touchUpInside)
        progressSlider.addAction(UIAction { [weak self] _ in
            self?.onSeekBegan?()
        }, for: .touchDown)
        progressSlider.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            onSeekEnded?(TimeInterval(progressSlider.value))
        }, for: [.touchUpInside, .touchUpOutside])
        // 드래그 중 시간 레이블만 실시간 업데이트
        progressSlider.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            currentTimeLabel.text = TimeInterval(progressSlider.value).durationString
        }, for: .valueChanged)
    }

    // MARK: - UIView Update Cycle

    /// @Observable AudioPlayerObservable를 자동 추적합니다.
    /// playbackState가 변경될 때마다 UIKit이 재호출합니다.
    override func updateProperties() {
        super.updateProperties()
        guard let state = audioPlayerObservable?.playbackState else { return }
        apply(state)
    }

    // MARK: - Apply

    private func apply(_ state: AudioPlaybackState) {
        currentTimeLabel.text = state.currentTime.durationString
        totalDurationLabel.text = state.duration.durationString
        var config = playPauseButton.configuration
        config?.image = state.status == .playing ? UIImage(systemName: "pause.fill") : UIImage(systemName: "play.fill")
        playPauseButton.configuration = config
        // 슬라이더를 드래그 중이 아닐 때만 업데이트
        if !progressSlider.isTracking {
            progressSlider.maximumValue = Float(state.duration)
            progressSlider.value = Float(state.currentTime)
        }
    }
}
