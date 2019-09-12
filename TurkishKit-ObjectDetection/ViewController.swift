//
//  ViewController.swift
//  TurkishKit-ObjectDetection
//
//  Created by Nadin Tamer on 29.08.2019.
//  Copyright © 2019 Nadin Tamer. All rights reserved.
//
import UIKit
import CoreML
import Vision

class ViewController: UIViewController {
    
    @IBOutlet weak var photosCollectionView: UICollectionView!
    
    var photos = [PhotoItem]()
    var filteredPhotos = [PhotoItem]()
    let picker = UIImagePickerController()
    let searchController = UISearchController(searchResultsController: nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        picker.delegate = self
        picker.allowsEditing = false
        picker.sourceType = .photoLibrary
        picker.modalPresentationStyle = .popover
        
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Fotoğraf Ara"
        self.navigationItem.searchController = searchController
        self.navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
        
    }
    
    @IBAction func addPhotoBarButtonItemTapped(_ sender: UIBarButtonItem) {
        present(picker, animated: true, completion: nil)
    }
    
    @IBAction func btnTakePhoto(_ sender: Any) {
        let vc = UIImagePickerController()
        vc.sourceType = .camera
        vc.allowsEditing = true
        vc.delegate = self
        present(vc, animated: true)
    }
    
    // MARK: CoreML
    func predictImage(image: UIImage) {
        guard let model = try? VNCoreMLModel(for: FruitDetector().model) else { return }
        let request = VNCoreMLRequest(model: model) { (finishedReq, err) in
            guard let results = finishedReq.results as? [VNClassificationObservation] else { return }
            
            guard let firstObservation = results.first else { return }
            
            self.photos.append(PhotoItem(photo: image, predictedLabel: firstObservation.identifier))
            
        }
        
        try? VNImageRequestHandler(cgImage: image.cgImage!, options: [:]).perform([request])
    }
    
    // MARK: SearchBar
    func searchBarIsEmpty() -> Bool {
        // Returns true if the text is empty or nil
        return searchController.searchBar.text?.isEmpty ?? true
    }
    
    func filterContentForSearchText(_ searchText: String, scope: String = "All") {
        var filtered = [PhotoItem]()
        for photo in self.photos {
            if photo.predictedLabel.prefix(searchText.count) == searchText {
                filtered.append(photo)
            }
        }
        
        self.filteredPhotos = filtered
        photosCollectionView.reloadData()
    }
    
    func isFiltering() -> Bool {
        return searchController.isActive && !searchBarIsEmpty()
    }
}

// MARK: CollectionView
extension ViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if isFiltering() {
            return filteredPhotos.count
        } else {
            return photos.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let photoCell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoItemCollectionViewCell", for: indexPath) as! PhotoItemCollectionViewCell
        
        if isFiltering() {
            photoCell.photoImageView.image = filteredPhotos[indexPath.row].photo
        } else {
            photoCell.photoImageView.image = photos[indexPath.row].photo
        }
        
        return photoCell
    }
}

// MARK: ImagePicker
extension ViewController : UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            predictImage(image: pickedImage)
            photosCollectionView.reloadData()
            print(self.photos)
        }
        picker.dismiss(animated: true, completion: nil)
        
        guard let image = info[.editedImage] as? UIImage else {
            print("No image found")
            return
        }
            
        // print out the image size as a test
        print(image.size)
            
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}

// MARK: UISearchResultsUpdating
extension ViewController : UISearchResultsUpdating {
    // MARK: - UISearchResultsUpdating Delegate
    func updateSearchResults(for searchController: UISearchController) {
        if let text = searchController.searchBar.text {
            filterContentForSearchText(text)
        }
    }
}


