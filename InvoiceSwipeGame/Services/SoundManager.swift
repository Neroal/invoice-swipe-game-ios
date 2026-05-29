import AVFoundation

/// Synthesises simple tones via AVAudioEngine – no audio files needed.
final class SoundManager {

    private let engine     = AVAudioEngine()
    private let mixer      = AVAudioMixerNode()
    private var isSetUp    = false

    var isEnabled: Bool {
        get { UserDefaults.standard.object(forKey: "sound_enabled") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "sound_enabled") }
    }

    // MARK: – Setup

    private func setup() {
        guard !isSetUp else { return }
        engine.attach(mixer)
        engine.connect(mixer, to: engine.mainMixerNode,
                       format: AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1))
        do {
            try engine.start()
            isSetUp = true   // 只有在成功後才標記，失敗時下次 play() 仍可重試
        } catch {
            // 常見原因：來電中、其他 app 佔用 AVAudioSession（Spotify 等）
            // 不設 isSetUp = true，讓下一次 play() 再嘗試啟動
            print("[SoundManager] 引擎啟動失敗，將於下次播放時重試: \(error.localizedDescription)")
        }
    }

    // MARK: – Tone generation

    private func makeTone(frequency: Float,
                          duration: Double,
                          volume: Float = 0.3,
                          wave: WaveShape = .sine) -> AVAudioPCMBuffer? {
        let sampleRate: Double = 44100
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard let fmt = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1),
              let buf = AVAudioPCMBuffer(pcmFormat: fmt, frameCapacity: frameCount) else { return nil }
        buf.frameLength = frameCount
        let data = buf.floatChannelData![0]
        let total   = Int(frameCount)
        // Proportional envelope — prevents click/pop on very short tones
        let attack  = min(Int(sampleRate * 0.008), Int(Double(total) * 0.12))
        let release = min(Int(sampleRate * 0.045), Int(Double(total) * 0.28))
        for i in 0..<total {
            let phase = 2.0 * Float.pi * frequency * Float(i) / Float(sampleRate)
            var s: Float
            switch wave {
            case .sine:     s = sin(phase)
            case .square:   s = sin(phase) >= 0 ? 1 : -1
            case .sawtooth:
                let p = (Double(i) * Double(frequency) / sampleRate).truncatingRemainder(dividingBy: 1)
                s = Float(p) * 2 - 1
            case .triangle:
                let p = (Double(i) * Double(frequency) / sampleRate).truncatingRemainder(dividingBy: 1)
                s = Float(abs(p * 2 - 1) * 2 - 1)
            }
            var env: Float = 1
            if i < attack               { env = Float(i) / Float(max(attack, 1)) }
            else if i > total - release { env = Float(total - i) / Float(max(release, 1)) }
            data[i] = s * volume * env
        }
        return buf
    }

    enum WaveShape { case sine, square, sawtooth, triangle }

    // MARK: – Play helpers

    private func play(_ buf: AVAudioPCMBuffer, delay: Double = 0) {
        guard isEnabled else { return }
        setup()
        if !engine.isRunning { try? engine.start() }
        let node = AVAudioPlayerNode()
        engine.attach(node)
        engine.connect(node, to: mixer, format: buf.format)
        node.scheduleBuffer(buf) { [weak self, weak node] in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if let n = node { self?.engine.detach(n) }
            }
        }
        if delay > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { node.play() }
        } else {
            node.play()
        }
    }

    private func tone(_ f: Float, _ dur: Double, _ vol: Float = 0.3,
                      _ wave: WaveShape = .sine, delay: Double = 0) {
        if let b = makeTone(frequency: f, duration: dur, volume: vol, wave: wave) {
            play(b, delay: delay)
        }
    }

    // MARK: – Public API

    // 滑動：高頻短 sine，乾淨俐落
    func playSwipe()   { tone(780, 0.055, 0.14, .sine) }

    // 答對：小三度上行雙音，清脆
    func playCorrect() {
        tone(880,  0.10, 0.28, .sine)
        tone(1108, 0.09, 0.22, .sine, delay: 0.07)
    }

    // 答錯：可聽見的下行雙音（350 → 262 Hz），不刺耳
    func playWrong() {
        tone(350, 0.13, 0.32, .sine)
        tone(262, 0.17, 0.28, .sine, delay: 0.10)
    }

    // 小獎：明亮硬幣音
    func playCoin() {
        tone(1047, 0.08, 0.36, .sine)
        tone(1319, 0.07, 0.26, .sine, delay: 0.09)
    }

    // 失命：三音下行 sine，沉但不刺
    func playLifeLost() {
        for (i, f) in [392, 294, 196].enumerated() {
            tone(Float(f), 0.16, 0.36, .sine, delay: Double(i) * 0.13)
        }
    }

    // 倒數 beep：sine 波，輕重分明
    func playBeep(heavy: Bool = false) {
        tone(heavy ? 700 : 520, 0.08, heavy ? 0.44 : 0.26, .sine)
    }

    // 最後 5 秒 tick：高頻 sine，清晰不刺耳
    func playTick()   { tone(1050, 0.035, 0.20, .sine) }

    // 時間到：三音下行，乾淨收尾
    func playTimeUp() {
        for (i, f) in [440, 330, 220].enumerated() {
            tone(Float(f), 0.28, 0.46, .sine, delay: Double(i) * 0.16)
        }
    }

    // 頭獎：C-E-G-C 大調上行琶音
    func playFirstPrize() {
        for (i, f) in [523, 659, 784, 1047].enumerated() {
            tone(Float(f), 0.26, 0.36, .sine, delay: Double(i) * 0.13)
        }
    }

    // 特獎：C-E-G-C-E 五音上行，稍長稍強
    func playGrandPrize() {
        for (i, f) in [523, 659, 784, 1047, 1319].enumerated() {
            tone(Float(f), 0.30, 0.38, .sine, delay: Double(i) * 0.10)
        }
    }

    // 特別獎：全大調上行旋律，純粹歡快（移除降半音 415Hz）
    func playSpecialPrize() {
        // C5 - E5 - G5 - C6 - G5 - C6 - E6 - C6
        let mel: [Float] = [523, 659, 784, 1047, 784, 1047, 1319, 1047]
        for (i, f) in mel.enumerated() {
            tone(f, 0.32, 0.40, .sine, delay: Double(i) * 0.14)
        }
    }

    // Combo 里程碑：音調隨 phase 升高（5 / 10 / 20+）
    func playCombo(streak: Int) {
        switch streak {
        case 5:     // phase 2
            tone(1047, 0.09, 0.30, .sine)
            tone(1319, 0.08, 0.25, .sine, delay: 0.06)
            tone(1568, 0.07, 0.20, .sine, delay: 0.12)
        case 10:    // phase 3
            tone(1175, 0.08, 0.32, .sine)
            tone(1480, 0.08, 0.28, .sine, delay: 0.06)
            tone(1760, 0.07, 0.24, .sine, delay: 0.12)
            tone(2093, 0.06, 0.18, .sine, delay: 0.18)
        default:    // phase 4 (20+) 及後續每 10 連
            for (i, f) in ([1047, 1319, 1568, 2093, 2637] as [Float]).enumerated() {
                tone(f, 0.10, 0.34, .sine, delay: Double(i) * 0.06)
            }
        }
    }
}
