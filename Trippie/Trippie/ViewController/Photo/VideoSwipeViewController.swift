//
//  VideoSwipeViewController.swift
//  Trippie
//
//  Created by Nguyen Huy Hoang on 14/2/26.
//

import UIKit
import AVFoundation

class VideoSwipeViewController: UIViewController {
    
    deinit {
        print("\(String(describing: self)) đã bị hủy!")
    }
    
    // ĐẦU VÀO: Mảng link video và vị trí đang chọn
    var videoUrls: [String] = []
    var currentIndex: Int = 0
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical // LƯỚT DỌC NHƯ TIKTOK
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.isPagingEnabled = true
        cv.backgroundColor = .black
        cv.showsVerticalScrollIndicator = false
        cv.contentInsetAdjustmentBehavior = .never // Bỏ khoảng trắng tai thỏ
        cv.register(VideoSwipeCell.self, forCellWithReuseIdentifier: "VideoSwipeCell")
        cv.delegate = self
        cv.dataSource = self
        cv.translatesAutoresizingMaskIntoConstraints = false
        return cv
    }()
    
    private let closeButton = UIButton.customButton(image: UIImage(systemName: "xmark"), backgroundColor: .black.withAlphaComponent(0.3))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        
        // Cuộn đến video được click ban đầu và phát nó
        DispatchQueue.main.async {
            if !self.videoUrls.isEmpty {
                self.collectionView.scrollToItem(at: IndexPath(item: self.currentIndex, section: 0), at: .centeredVertically, animated: false)
                self.playVideo(at: self.currentIndex)
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        pauseAllVideos() // Đảm bảo âm thanh tắt cái rụp khi đóng màn hình
    }
    
    private func setupUI() {
        view.addSubview(collectionView)
        view.addSubview(closeButton)
        
        closeButton.addTarget(self, action: #selector(didTapClose), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            closeButton.widthAnchor.constraint(equalToConstant: 40),
            closeButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    @objc private func didTapClose() {
        pauseAllVideos()
        dismiss(animated: true)
    }
    
    // MARK: - Quản lý phát/dừng Video tự động
    private func playVideo(at index: Int) {
        // 1. Tạm dừng TẤT CẢ các cell đang hiển thị
        for cell in collectionView.visibleCells {
            if let videoCell = cell as? VideoSwipeCell {
                videoCell.pause()
            }
        }
        
        // 2. Chỉ phát video của Cell hiện tại
        if let cell = collectionView.cellForItem(at: IndexPath(item: index, section: 0)) as? VideoSwipeCell {
            cell.play()
        }
    }
    
    private func pauseAllVideos() {
        for cell in collectionView.visibleCells {
            if let videoCell = cell as? VideoSwipeCell {
                videoCell.pause()
            }
        }
    }
}

// MARK: - CollectionView Delegate & DataSource
extension VideoSwipeViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return videoUrls.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "VideoSwipeCell", for: indexPath) as! VideoSwipeCell
        cell.configure(url: videoUrls[indexPath.item])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // Mỗi cell to bằng đúng Full màn hình
        return view.frame.size
    }
    
    // Bắt sự kiện LƯỚT XONG để phát video mới
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let height = scrollView.frame.height
        let currentPage = Int(scrollView.contentOffset.y / height)
        
        if currentIndex != currentPage {
            currentIndex = currentPage
            playVideo(at: currentIndex) // Lướt tới đâu phát video tới đó
        }
    }
}


// MARK: - CUSTOM CELL: Nơi chứa và chạy Video
class VideoSwipeCell: UICollectionViewCell {
    
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    
    // Nút Play hiển thị khi tạm dừng (Giống TikTok)
    private let playIcon: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "play.fill"))
        iv.tintColor = .white.withAlphaComponent(0.8)
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.isHidden = true // Mặc định ẩn vì video sẽ auto-play
        return iv
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    private func setupUI() {
        backgroundColor = .black
        contentView.addSubview(playIcon)
        
        NSLayoutConstraint.activate([
            playIcon.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            playIcon.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            playIcon.widthAnchor.constraint(equalToConstant: 70),
            playIcon.heightAnchor.constraint(equalToConstant: 70)
        ])
        
        // Chạm vào màn hình để Play/Pause
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        contentView.addGestureRecognizer(tap)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // Đảm bảo video layer luôn bám sát khung Cell
        playerLayer?.frame = contentView.bounds
    }
    
    // Nạp link video
    func configure(url: String) {
        guard let videoUrl = URL(string: url) else { return }
        
        // Khởi tạo Player
        player = AVPlayer(url: videoUrl)
        playerLayer = AVPlayerLayer(player: player)
        
        // Cậu có thể đổi thành .resizeAspectFill nếu muốn video lấp đầy màn hình như TikTok (bị cắt viền)
        // Hiện tại tớ để .resizeAspect để không bị mất góc video
        playerLayer?.videoGravity = .resizeAspect
        
        if let layer = playerLayer {
            contentView.layer.insertSublayer(layer, at: 0) // Nằm dưới icon Play
        }
        
        // Lắng nghe sự kiện video chạy hết để lặp lại (Loop)
        NotificationCenter.default.addObserver(self, selector: #selector(videoDidEnd), name: .AVPlayerItemDidPlayToEndTime, object: player?.currentItem)
    }
    
    @objc private func handleTap() {
        guard let player = player else { return }
        if player.rate == 0 { // Đang dừng -> Phát
            play()
        } else { // Đang phát -> Tạm dừng
            pause()
            playIcon.isHidden = false
        }
    }
    
    @objc private func videoDidEnd() {
        // Tua lại từ đầu và phát tiếp
        player?.seek(to: .zero)
        player?.play()
    }
    
    func play() {
        player?.play()
        playIcon.isHidden = true
    }
    
    func pause() {
        player?.pause()
    }
    
     
    // Quan trọng: Dọn rác bộ nhớ khi lướt qua Cell khác
    override func prepareForReuse() {
        super.prepareForReuse()
        pause()
        playerLayer?.removeFromSuperlayer()
        playerLayer = nil
        player = nil
        playIcon.isHidden = true
        NotificationCenter.default.removeObserver(self)
    }
}
