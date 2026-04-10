import Domain
import UIKit

final class AudioPlayerView: UIView {
    var onPlayPause: (() -> Void)?
    var onRewind: (() -> Void)?
    var onForward: (() -> Void)?

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
            buttonStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -46),
        ])
    }

    private func setupActions() {
        rewindButton.addAction(UIAction { [weak self] _ in self?.onRewind?() }, for: .touchUpInside)
        playPauseButton.addAction(UIAction { [weak self] _ in self?.onPlayPause?() }, for: .touchUpInside)
        forwardButton.addAction(UIAction { [weak self] _ in self?.onForward?() }, for: .touchUpInside)
    }

    func apply(_ state: AudioPlaybackState) {
        currentTimeLabel.text = state.currentTime.durationString
        totalDurationLabel.text = state.duration.durationString
        if state.status == .playing {
            playPauseButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
        } else {
            playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        }
    }
}

#Preview(traits: .portrait) {
    AudioPlayerView()
}

#Preview("재생 중 - 중간 지점") {
    let view = AudioPlayerView()
    view.apply(AudioPlaybackState(status: .playing, currentTime: 75, duration: 180))
    return view
}

#Preview("일시정지 - 초반") {
    let view = AudioPlayerView()
    view.apply(AudioPlaybackState(status: .paused, currentTime: 20, duration: 180))
    return view
}

#Preview("Idle - 시작 전") {
    let view = AudioPlayerView()
    view.apply(AudioPlaybackState(status: .idle, currentTime: 0, duration: 0))
    return view
}

#Preview("1시간 이상 - 포맷 확인") {
    let view = AudioPlayerView()
    view.apply(AudioPlaybackState(status: .playing, currentTime: 3720, duration: 7260))
    return view
}
