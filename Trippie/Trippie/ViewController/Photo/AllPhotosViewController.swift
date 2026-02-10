//
//  AllPhotosViewController.swift
//  Trippie
//
//  Created by hoang.nguyenh on 2/9/26.
//

import UIKit
import PhotosUI
import Combine

class AllPhotosViewController: FadeBaseViewController {
    
    var imageUrls: [String] = []
    var isOwnerOpen: Bool!
    var trip: TripWithStatus!
    
    private var isAdding = false
    @Published private var startingDelete = false
    private var deleteUrls: [String] = []
    
    private let viewModel = TripViewModel.shared
    private let imagesViewModel = ImageViewModel()
    private var cancellable = Set<AnyCancellable>()
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 1 // Khoảng cách giữa các hàng
        layout.minimumInteritemSpacing = 1 // Khoảng cách giữa các cột
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .systemBackground
        cv.register(PhotoGridCell.self, forCellWithReuseIdentifier: "PhotoGridCell")
        cv.delegate = self
        cv.dataSource = self
        cv.translatesAutoresizingMaskIntoConstraints = false
        return cv
    }()
    
    private let menubtn = DropdownButton()
    private let backBtn = UIButton.customButton(image: UIImage(systemName: "arrow.left"), backgroundColor: .authBackground2.withAlphaComponent(0.5))
    private let deleteBtn = UIButton.customButton(image: UIImage(systemName: "minus"), backgroundColor: .systemRed.withAlphaComponent(0.5))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavBar()
        bindLoading(to: imagesViewModel.loading)
    }
    
    private func setupUI() {
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupNavBar() {
        self.title = "All images"
        backBtn.addTarget(self, action: #selector(handleBack), for: .touchUpInside)
        
        if isOwnerOpen {
            var dropDownItems: [DropdownItem] = []
            dropDownItems.append(DropdownItem(title: "Add Photos", icon: "photo.badge.plus", type: .normal) {
                self.handleAdd()
            })
            
            let rightItem = UIBarButtonItem(customView: menubtn)
            let rightItem1 = UIBarButtonItem(customView: deleteBtn)
            
            if startingDelete {
                self.navigationItem.rightBarButtonItems = [rightItem1, rightItem]
                dropDownItems.append(DropdownItem(title: "Cancel Action", icon: "xmark", type: .destructive) {
                    self.startingDelete = false
                })
            } else {
                self.navigationItem.rightBarButtonItem = rightItem
                dropDownItems.append(DropdownItem(title: "Delete Photos", icon: "trash", type: .destructive) {
                    self.startingDelete = true
                })
            }
            menubtn.items = dropDownItems
        }
        
        let leftItem = UIBarButtonItem(customView: backBtn)
        self.navigationItem.leftBarButtonItem = leftItem
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .systemBackground
        appearance.shadowColor = .clear
        
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
    }
    
    @objc private func handleBack() {
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc private func handleAdd() {
        var config = PHPickerConfiguration()
        config.selectionLimit = 10
        config.filter = .images
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
        isAdding = true
    }
    
    @objc private func handledDoingDelete() {
        
    }
    
    private func binding() {
        imagesViewModel.$uploadedUrls
            .dropFirst()
            .filter { !$0.isEmpty }
            .receive(on: DispatchQueue.main) // 🟢 Sink trên Main Thread
            .sink { [weak self] urls in
                guard let self = self else { return }
                if self.isAdding {
                    self.viewModel.editingTrip.send(self.trip)
                    guard var t = self.trip?.trip else { return }
                    let uniqueUrls = urls.filter { !t.coverImage.contains($0) }
                    t.coverImage.insert(contentsOf: uniqueUrls, at: 0)
                    self.viewModel.handleSave(trip: t)
                    self.imagesViewModel.uploadedUrls = []
                    
                } else {
                    self.viewModel.editingTrip.send(self.trip)
                    guard var t = self.trip?.trip else { return }
                    t.coverImage.removeAll(where: { urls.contains($0) })
                    self.viewModel.handleSave(trip: t)
                    self.imagesViewModel.deleteAllImages()
                }
            }
            .store(in: &cancellable)
        
        self.$startingDelete
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.setupNavBar()
            }
            .store(in: &cancellable)
    }
}

// MARK: - CollectionView Logic
extension AllPhotosViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageUrls.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoGridCell", for: indexPath) as! PhotoGridCell
        cell.configure(url: imageUrls[indexPath.item])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // Chia 3 màn hình (trừ đi khoảng cách giữa các cell)
        let width = (view.frame.width - 2) / 3
        return CGSize(width: width, height: width)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let fullVC = PhotoFullScreenViewController()
        fullVC.imageUrls = self.imageUrls
        fullVC.currentIndex = indexPath.item
        fullVC.modalPresentationStyle = .overFullScreen
        fullVC.modalTransitionStyle = .crossDissolve
        present(fullVC, animated: true)
    }
}

// MARK: - Cell
class PhotoGridCell: UICollectionViewCell {
    private let imageView = TrippieImageView(style: .rounded(radius: 0, corners: []), isShadow: false, borderColor: .authBackground2.withAlphaComponent(0.3))
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    func configure(url: String) {
        imageView.setImage(url: url)
    }
}

extension AllPhotosViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        
        guard !results.isEmpty else { return }
        
        var selectedImages: [UIImage] = []
        let dispatchGroup = DispatchGroup()
        
        // Lấy UIImage từ kết quả chọn
        for result in results {
            dispatchGroup.enter()
            if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                result.itemProvider.loadObject(ofClass: UIImage.self) { (image, error) in
                    if let img = image as? UIImage {
                        selectedImages.append(img)
                    }
                    dispatchGroup.leave()
                }
            } else {
                dispatchGroup.leave()
            }
        }
        dispatchGroup.notify(queue: .main) { [weak self] in
            Task { [weak self] in
                let confirmed = await self?.confirmAlert(type: .add, title: "these Images?") ?? false
                
                if confirmed {
                    self?.imagesViewModel.uploadImages(selectedImages, folder: "trips")
                }
            }
        }
    }
}
