//
//  FileFormat.swift
//  Domain
//
//  Created by Tom Choi on 2/9/26.
//

import Foundation

/// FileFormat은 녹음 파일의 파일 형식을 나타내는 열거형입니다.
/// - mp3: MP3 파일.
/// - wav: WAV 파일.
/// - aac: AAC 파일.
/// - m4a: M4A 파일.
/// - other: 기타 파일 형식.
public enum FileFormat {
    case mp3
    case wav
    case aac
    case m4a
    case other(String)
}
