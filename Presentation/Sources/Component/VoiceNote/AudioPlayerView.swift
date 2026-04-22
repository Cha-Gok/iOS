import Domain
import UIKit

final class AudioPlayerView: UIView {
    var onPlayPause: (() -> Void)?
    var onRewind: (() -> Void)?
    var onForward: (() -> Void)?
    var onSeekBegan: (() -> Void)?
    var onSeekEnded: ((TimeInterval) -> Void)?

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

    private let progressView = PlaybackProgressView()

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

    func apply(_ state: AudioPlaybackState) {
        totalDurationLabel.text = state.duration.durationString
        var config = playPauseButton.configuration
        config?.image = state.status == .playing ? UIImage(systemName: "pause.fill") : UIImage(systemName: "play.fill")
        playPauseButton.configuration = config
        progressView.setDuration(state.duration)
        progressView.setCurrentTime(state.currentTime)
        if !progressView.isInteracting {
            currentTimeLabel.text = state.currentTime.durationString
        }
    }

    private func setupUI() {
        backgroundColor = .gray0

        for view in [progressView, durationStackView, buttonStackView] {
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

            progressView.topAnchor.constraint(equalTo: topAnchor),
            progressView.leadingAnchor.constraint(equalTo: leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: trailingAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 8),

            durationStackView.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 18),
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

        progressView.onSeekBegan = { [weak self] in self?.onSeekBegan?() }
        progressView.onValueChanging = { [weak self] time in
            self?.currentTimeLabel.text = time.durationString
        }
        progressView.onSeekEnded = { [weak self] time in self?.onSeekEnded?(time) }
    }
}

#Preview("정지") {
    let view = AudioPlayerView()
    view.apply(AudioPlaybackState(status: .idle, currentTime: 0, duration: 180))
    return view
}

#Preview("재생 중") {
    let view = AudioPlayerView()
    view.apply(AudioPlaybackState(status: .playing, currentTime: 72, duration: 180))
    return view
}
