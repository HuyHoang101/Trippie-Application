//
//  ImageColectionAnimateScroll.swift
//  Trippie
//
//  Created by hoang.nguyenh on 2/10/26.
//

import UIKit
import Combine

class ImageColectionAnimateScroll: UICollectionView {
    
    private var imageUrls: [String] = []
    private var timer: Timer?
    @Published var currentIndex = 0
    
    init() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        
        super .init(frame: .zero, collectionViewLayout: layout)
        setupCollectionView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupCollectionView() {
        self.isPagingEnabled = true
        self.showsHorizontalScrollIndicator = false
        self.dataSource = self
        self.delegate = self
        
        self.register(ImageCell.self, forCellWithReuseIdentifier: "ImageCell")
    }
    
    func configure(urls: [String]) {
        self.imageUrls = urls
        self.reloadData()
        startTimer()
    }
    
    func getIndex() -> Int {
        return self.currentIndex
    }
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            self?.scrollToNextImage()
        }
        RunLoop.main.add(timer!, forMode: .common)
    }
    
    private func scrollToNextImage() {
        guard !imageUrls.isEmpty else { return }
        let nextIndex = (currentIndex + 1) % imageUrls.count
        let indexPath = IndexPath(item: nextIndex, section: 0)
        self.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        
        self.currentIndex = nextIndex
    }
}



extension ImageColectionAnimateScroll: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageUrls.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCell", for: indexPath) as! ImageCell
        let url = imageUrls[indexPath.item]
        cell.configure(with: url)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return self.bounds.size
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let width = scrollView.frame.width
        let newIndex = Int(scrollView.contentOffset.x / width)
        
        if newIndex != self.currentIndex {
            self.currentIndex = newIndex
        }
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        let width = scrollView.frame.width
        let newIndex = Int(scrollView.contentOffset.x / width)
        if newIndex != self.currentIndex {
            self.currentIndex = newIndex
        }
    }
}


class ImageCell: UICollectionViewCell {
    private let imageView = TrippieImageView(style: .rounded(radius: 8, corners: [.layerMaxXMaxYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMinXMinYCorner]), isShadow: false, borderColor: .authBackground2.withAlphaComponent(0.5))
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        
        
    }
    required init?(coder: NSCoder) { fatalError() }
    
    func configure(with url: String) {
        imageView.setImage(url: url)
    }
}
