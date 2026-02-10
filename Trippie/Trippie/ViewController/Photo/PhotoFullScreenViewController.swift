//
//  PhotoFullScreenViewController.swift
//  Trippie
//
//  Created by hoang.nguyenh on 2/9/26.
//

import UIKit
import SDWebImage

class PhotoFullScreenViewController: UIViewController {
    
    var imageUrls: [String] = []
    var currentIndex: Int = 0
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.isPagingEnabled = true
        cv.backgroundColor = .black
        cv.showsHorizontalScrollIndicator = false
        cv.register(FullScreenPhotoCell.self, forCellWithReuseIdentifier: "FullScreenPhotoCell")
        cv.delegate = self
        cv.dataSource = self
        cv.translatesAutoresizingMaskIntoConstraints = false
        return cv
    }()
    
    private let imageCountLabel = UILabel.customLabel(text: "", font: .systemFont(ofSize: 14), textColor: .white, textAligment: .center)
    
    private let closeButton = UIButton.customButton(image: UIImage(systemName: "xmark"), backgroundColor: .black.withAlphaComponent(0.3))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        // Cuộn đến ảnh được chọn ban đầu
        updateImageCount(index: currentIndex)
        DispatchQueue.main.async {
            self.collectionView.scrollToItem(at: IndexPath(item: self.currentIndex, section: 0), at: .centeredHorizontally, animated: false)
        }
    }
    
    private func setupUI() {
        view.addSubview(collectionView)
        view.addSubview(closeButton)
        view.addSubview(imageCountLabel)
        
        imageCountLabel.backgroundColor = .black.withAlphaComponent(0.3)
        imageCountLabel.clipsToBounds = true
        imageCountLabel.heightAnchor.constraint(equalToConstant: 24).isActive = true
        imageCountLabel.layer.cornerRadius = 12
        
        
        closeButton.addTarget(self, action: #selector(didTapClose), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            closeButton.widthAnchor.constraint(equalToConstant: 40),
            closeButton.heightAnchor.constraint(equalToConstant: 40),
            
            imageCountLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageCountLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 30)
        ])
    }
    
    @objc private func didTapClose() { dismiss(animated: true) }
    
    private func updateImageCount(index: Int) {
        let total = imageUrls.count
        // Cộng 1 vì index bắt đầu từ 0 (ảnh 0 -> hiển thị là 1)
        imageCountLabel.text = " Images \(index + 1)/\(total)  "
    }
}

extension PhotoFullScreenViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageUrls.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FullScreenPhotoCell", for: indexPath) as! FullScreenPhotoCell
        cell.configure(url: imageUrls[indexPath.item])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return view.frame.size
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let width = scrollView.frame.width
        let currentPage = Int(scrollView.contentOffset.x / width)

        self.currentIndex = currentPage
        
        updateImageCount(index: currentPage)
    }
}

class FullScreenPhotoCell: UICollectionViewCell, UIScrollViewDelegate {
    
    private let scrollView = UIScrollView()
    private let imageView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    private func setupUI() {
        // 1. Setup ScrollView
        scrollView.delegate = self
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 4.0 // Zoom tối đa 4x
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.backgroundColor = .black
        
        contentView.addSubview(scrollView)
        scrollView.addSubview(imageView) // Add imageView vào nhưng KHÔNG set constraint
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        
        // 2. Constraints cho ScrollView (Full màn hình)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: contentView.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        
        // 3. Setup Double Tap
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        addGestureRecognizer(doubleTap)
    }
    
    // --- LOAD ẢNH VÀ TÍNH FRAME ---
    func configure(url: String) {
        scrollView.setZoomScale(1.0, animated: false)
        
        guard let imageUrl = URL(string: url) else { return }
        
        // Dùng SDWebImage tải ảnh
        imageView.sd_setImage(with: imageUrl) { [weak self] (image, error, cacheType, url) in
            guard let self = self, let image = image else { return }
            
            // Tải xong -> Tính toán lại kích thước thật
            self.updateLayout(for: image)
        }
    }
    
    // Hàm thần thánh: Tính frame ảnh để chặn scroll ra vùng đen
    private func updateLayout(for image: UIImage) {
        // 1. Đảm bảo layout của Cell đã hoàn tất
        contentView.layoutIfNeeded()
        
        // 2. TRIỆT TIÊU TRANSFORM CŨ (Chìa khóa để hết lag/phóng đại)
        imageView.transform = .identity
        
        let boundsSize = contentView.bounds.size
        let imageSize = image.size
        
        // Tính tỷ lệ scale để ảnh vừa khít màn hình (Fit)
        let xScale = boundsSize.width / imageSize.width
        let yScale = boundsSize.height / imageSize.height
        let minScale = min(xScale, yScale)
        
        // Kích thước hiển thị thực tế của ảnh
        let scaledImageSize = CGSize(width: imageSize.width * minScale, height: imageSize.height * minScale)
        
        // Set frame cho imageView bằng đúng kích thước thật này
        imageView.frame = CGRect(origin: .zero, size: scaledImageSize)
        
        // Set contentSize cho scrollView
        scrollView.contentSize = scaledImageSize
        
        // Đặt ảnh vào giữa màn hình
        centerImage()
    }
    
    // --- ZOOM LOGIC ---
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    // Mỗi lần zoom sẽ gọi hàm này để căn giữa lại
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerImage()
    }
    
    // Hàm căn giữa ảnh (kể cả khi zoom hay chưa zoom)
    private func centerImage() {
        let boundsSize = scrollView.bounds.size
        var frameToCenter = imageView.frame
        
        // Nếu ảnh nhỏ hơn màn hình -> Căn giữa
        // Nếu ảnh to hơn màn hình -> Để nguyên (cho phép scroll)
        if frameToCenter.size.width < boundsSize.width {
            frameToCenter.origin.x = (boundsSize.width - frameToCenter.size.width) / 2
        } else {
            frameToCenter.origin.x = 0
        }
        
        if frameToCenter.size.height < boundsSize.height {
            frameToCenter.origin.y = (boundsSize.height - frameToCenter.size.height) / 2
        } else {
            frameToCenter.origin.y = 0
        }
        
        imageView.frame = frameToCenter
    }
    
    // --- DOUBLE TAP LOGIC ---
    @objc private func handleDoubleTap(_ sender: UITapGestureRecognizer) {
        if scrollView.zoomScale > scrollView.minimumZoomScale {
            scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
        } else {
            let touchPoint = sender.location(in: imageView)
            let scrollSize = scrollView.bounds.size
            
            // Tính vùng cần zoom vào
            let size = CGSize(width: scrollSize.width / scrollView.maximumZoomScale,
                              height: scrollSize.height / scrollView.maximumZoomScale)
            let origin = CGPoint(x: touchPoint.x - size.width / 2,
                                 y: touchPoint.y - size.height / 2)
            scrollView.zoom(to: CGRect(origin: origin, size: size), animated: true)
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        // 1. Reset zoom về 1
        scrollView.setZoomScale(1.0, animated: false)
        
        // 2. Quan trọng nhất: Đưa transform của imageView về mặc định
        imageView.transform = .identity
        
        // 3. Xóa ảnh cũ để tránh hiện ảnh cũ trước khi tải ảnh mới
        imageView.image = nil
    }
}
