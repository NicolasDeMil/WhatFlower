//
//  ViewController.swift
//  WhatFlower
//
//  Created by Nicolas De Mil on 28/07/2019.
//  Copyright © 2019 Nicolas De Mil. All rights reserved.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SDWebImage
import SwiftyJSON


class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    let wikipediaURl = "https://en.wikipedia.org/w/api.php"
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var label: UILabel!
    
    let imagePicker = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        imagePicker.sourceType = .camera
        
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let imageUserPicked = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            
            //imageView.image = imageUserPicked
            
            guard let ciimage = CIImage(image: imageUserPicked) else { fatalError("Could not convert to CIImage")}
            
            detect(ciimage)
            
        }
        
        imagePicker.dismiss(animated: true, completion: nil)
        
    }
    
    func detect(_ image: CIImage){
        
        //Create Model
        guard let model = try? VNCoreMLModel(for: FlowerClassifier().model) else { fatalError("Could not create model") }
        //Create Request
        let request = VNCoreMLRequest(model: model) { (request, error) in
            //Create Results
            guard let results = request.results as? [VNClassificationObservation] else { fatalError("Could not process results") }
            //Use Results
            print(results)
            if let flowerType = results.first?.identifier {
                self.navigationItem.title = flowerType.capitalized
                self.requestInfo(flowerType)
            }
        }
        //Create Handler
        let handler = VNImageRequestHandler(ciImage: image)
        //Run the handler
        do {
            try handler.perform([request])
        } catch {
            print("Error handling request: \(error)")
        }
        
    }
    
    //API FUNC
    func requestInfo(_ flowerName: String) {
        
        //Create Parametres
        let parameters : [String:String] = [
            "format" : "json",
            "action" : "query",
            "prop" : "extracts|pageimages",
            "exintro" : "",
            "explaintext" : "",
            "titles" : flowerName,
            "indexpageids" : "",
            "redirects" : "1",
            "pithumbsize" : "500",
        ]
        
        //Make Request
        Alamofire.request(wikipediaURl, method: .get, parameters: parameters).responseJSON { (response) in
            
            //Use response
            if response.result.isSuccess {
                
                print("Got the Wiki!")
                
                //Convert to JSON response
                let flowerJSON = JSON(response.result.value!)
                
                let pageid = flowerJSON["query"]["pageids"][0].stringValue
                
                let introText = flowerJSON["query"]["pages"][pageid]["extract"].stringValue
                
                let flowerImageURL = flowerJSON["query"]["pages"][pageid]["thumbnail"]["source"].stringValue
                
                self.label.text = introText
                
                self.imageView.sd_setImage(with: URL(string: flowerImageURL))
                }
        }
    }
    
    @IBAction func cameraPressed(_ sender: UIBarButtonItem) {
        
        present(imagePicker, animated: true, completion: nil)
        
    }
    
}


