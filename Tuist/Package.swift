// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ChaGok",
    dependencies: [
        .package(url: "https://github.com/argmaxinc/argmax-oss-swift.git", from: "1.0.0"),
        .package(
            url: "https://github.com/ml-explore/mlx-swift-lm",
            .upToNextMajor(from: "3.31.3")
        ),
        .package(url: "https://github.com/huggingface/swift-huggingface", from: "0.9.0"),
        .package(url: "https://github.com/huggingface/swift-transformers", from: "1.3.0")
    ]
)
