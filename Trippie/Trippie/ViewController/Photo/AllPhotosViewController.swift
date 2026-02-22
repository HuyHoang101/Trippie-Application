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
    deinit {
        print("\(String(describing: self)) đã bị hủy (Deallocated)!")
    }
    
    private var startingDelete: Bool = false {
        didSet {
            if oldValue != startingDelete {
                self.setupNavBar()
            }
        }
    }
    
    var imageUrls: [String] = []
    var isOwnerOpen: Bool!
    var trip: TripWithStatus!
    var videoUrls: [String] = []
    var thumbnailUrls: [String] = []
    var navigationTitle: String?
    
    private var isAdding = false
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
        action()
        bindLoading(to: imagesViewModel.loading)
        binding()
    }
    
    private func setupUI() {
        startingDelete = false
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupNavBar() {
        self.title = self.navigationTitle
        backBtn.addTarget(self, action: #selector(handleBack), for: .touchUpInside)
        
        if isOwnerOpen {
            var dropDownItems: [DropdownItem] = []
            dropDownItems.append(DropdownItem(title: "Add Photos", icon: "photo.badge.plus", type: .normal) { [weak self] in
                guard let self = self else { return }
                self.handleAdd()
            })
            
            let rightItem = UIBarButtonItem(customView: menubtn)
            let rightItem1 = UIBarButtonItem(customView: deleteBtn)
            
            if startingDelete {
                self.navigationItem.rightBarButtonItems = [rightItem1, rightItem]
                dropDownItems.append(DropdownItem(title: "Cancel Action", icon: "xmark", type: .destructive) { [weak self] in
                    guard let self = self else { return }
                    self.handleCancleDeleteAction()
                })
            } else {
                self.navigationItem.rightBarButtonItem = rightItem
                dropDownItems.append(DropdownItem(title: "Delete Photos", icon: "trash", type: .destructive) { [weak self] in
                    guard let self = self else { return }
                    self.handleStartDeleteAction()
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
    
    private func action() {
        self.deleteBtn.addTarget(self, action: #selector(handledDoingDelete), for: .touchUpInside)
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
        Task {
            await performDeleteLogic()
        }
    }
    
    @MainActor
    private func performDeleteLogic() async {
        isAdding = false
        let confirmAlert = await self.confirmAlert(type: .delete, title: "these images?")
        if deleteUrls.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                NotificationCenter.default.post(
                    name: .showGlobalToast,
                    object: nil,
                    userInfo: [
                        "message": "No image was choosen!",
                        "isSuccess": false
                    ]
                )
            }
        } else {
            if confirmAlert {
                self.imagesViewModel.uploadedUrls = self.deleteUrls
            }
        }
    }
    
    private func handleCancleDeleteAction() {
        self.startingDelete = false
        self.deleteUrls = []
        self.collectionView.reloadData()
    }
    
    private func handleStartDeleteAction() {
        self.startingDelete = true
        self.collectionView.reloadData()
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
                    self.imageUrls.insert(contentsOf: uniqueUrls, at: 0)
                } else {
                    self.viewModel.editingTrip.send(self.trip)
                    guard var t = self.trip?.trip else { return }
                    t.coverImage.removeAll(where: { urls.contains($0) })
                    self.viewModel.handleSave(trip: t)
                    self.imagesViewModel.deleteAllImages()
                    self.imageUrls.removeAll(where: { urls.contains($0) })
                    self.deleteUrls = []
                    self.startingDelete = false
                }
                self.collectionView.reloadData()
            }
            .store(in: &cancellable)
    }
}

// MARK: - CollectionView Logic
extension AllPhotosViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let count = videoUrls.isEmpty ? imageUrls.count : videoUrls.count
        return count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoGridCell", for: indexPath) as! PhotoGridCell
        
        var url = ""
        if !imageUrls.isEmpty {
            url = imageUrls[indexPath.item]
        } else {
            url = thumbnailUrls[indexPath.item]
        }
        
        let isSelected = deleteUrls.contains(url)
        
        cell.configure(url: url, isDeleteMode: startingDelete, isSelected: isSelected, isVideo: videoUrls.count != 0)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // Chia 3 màn hình (trừ đi khoảng cách giữa các cell)
        let width = (view.frame.width - 2) / 3
        return CGSize(width: width, height: width)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if startingDelete {
            let url = imageUrls[indexPath.item]
            if let index = deleteUrls.firstIndex(of: url) {
                deleteUrls.remove(at: index)
            } else {
                deleteUrls.append(url)
            }
            collectionView.reloadItems(at: [indexPath])
            
        } else {
            if imageUrls.count != 0 {
                let fullVC = PhotoFullScreenViewController()
                fullVC.imageUrls = self.imageUrls
                fullVC.currentIndex = indexPath.item
                fullVC.modalPresentationStyle = .overFullScreen
                fullVC.modalTransitionStyle = .crossDissolve
                present(fullVC, animated: true)
            } else {
                let fullVC = VideoSwipeViewController()
                fullVC.currentIndex = indexPath.item
                fullVC.videoUrls = self.videoUrls
                fullVC.modalPresentationStyle = .overFullScreen
                fullVC.modalTransitionStyle = .crossDissolve
                present(fullVC, animated: true)
            }
        }
    }
}

// MARK: - Cell
class PhotoGridCell: UICollectionViewCell {
    private let bgContainer: UIView = {
        let v = UIView()
        v.backgroundColor = .authBackground2
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    private let checkmarkIcon: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    private let playIcon: UIImageView = {
        let i = UIImageView()
        i.image = UIImage(systemName: "play.fill")
        i.tintColor = .white.withAlphaComponent(0.9)
        i.translatesAutoresizingMaskIntoConstraints = false
        return i
    }()
    private let imageView = TrippieImageView(style: .rounded(radius: 0, corners: []), isShadow: false, borderColor: .authBackground2.withAlphaComponent(0.3))
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(bgContainer)
        bgContainer.addSubview(imageView)
        bgContainer.addSubview(checkmarkIcon)
        bgContainer.addSubview(playIcon)
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        
        NSLayoutConstraint.activate([
            bgContainer.topAnchor.constraint(equalTo: contentView.topAnchor),
            bgContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            bgContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            bgContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            imageView.topAnchor.constraint(equalTo: bgContainer.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: bgContainer.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: bgContainer.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: bgContainer.bottomAnchor),
            
            checkmarkIcon.topAnchor.constraint(equalTo: bgContainer.topAnchor, constant: 12),
            checkmarkIcon.trailingAnchor.constraint(equalTo: bgContainer.trailingAnchor, constant: -12),
            checkmarkIcon.widthAnchor.constraint(equalToConstant: 24),
            checkmarkIcon.heightAnchor.constraint(equalToConstant: 24),
            
            playIcon.centerYAnchor.constraint(equalTo: bgContainer.centerYAnchor),
            playIcon.centerXAnchor.constraint(equalTo: bgContainer.centerXAnchor),
            playIcon.widthAnchor.constraint(equalToConstant: 26),
            playIcon.heightAnchor.constraint(equalToConstant: 26)
        ])
        
        playIcon.isHidden = true
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    func configure(url: String, isDeleteMode: Bool, isSelected: Bool, isVideo: Bool = false) {
        imageView.setImage(url: url)
        checkmarkIcon.isHidden = !isDeleteMode
        imageView.transform = .identity
        
        if isDeleteMode {
            checkmarkIcon.clipsToBounds = true
            checkmarkIcon.layer.cornerRadius = 12
            if isSelected {
                imageView.transform = CGAffineTransform(scaleX: 0.92, y: 0.92)
                checkmarkIcon.image = UIImage(systemName: "checkmark.circle.fill")
                checkmarkIcon.tintColor = .authBackground2
                checkmarkIcon.backgroundColor = .white
                checkmarkIcon.alpha = 1
            } else {
                imageView.transform = .identity
                checkmarkIcon.image = UIImage(systemName: "")
                checkmarkIcon.backgroundColor = .black
                checkmarkIcon.alpha = 0.15
            }
        }
        
        playIcon.isHidden = !isVideo
    }
}

extension AllPhotosViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        
        guard !results.isEmpty else { return }
        
        Task {
            // 1. Xử lý song song để lấy mảng DATA
            let optimizedDataArray = await withTaskGroup(of: Data?.self) { group -> [Data] in
                for result in results {
                    group.addTask {
                        // Gọi hàm mới trả về Data
                        return await result.loadResizedImage(targetSize: 1024)
                    }
                }
                
                var dataList: [Data] = []
                for await data in group {
                    if let validData = data {
                        dataList.append(validData)
                    }
                }
                return dataList
            }
            
            // 2. Upload (Lúc này cậu cần đảm bảo ViewModel có hàm nhận [Data])
            // Không cần chuyển đổi gì nữa, tiết kiệm rất nhiều bộ nhớ!
            let confirmed = await self.confirmAlert(type: .add, title: "these Images?")
            
            if confirmed {
                self.imagesViewModel.uploadImages(optimizedDataArray, folder: "trips")
            }
        }
    }
}
