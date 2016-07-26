//
//  ViewController.swift
//  LB_OCR
//
//  Created by llb1119 on 07/24/2016.
//  Copyright (c) 2016 llb1119. All rights reserved.
//

import UIKit
import LB_OCR
class ViewController: UIViewController, UINavigationControllerDelegate {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var textView: UITextView!
    
    @IBOutlet weak var recognizeBtn: UIButton!
    @IBOutlet weak var findSquarePointBtn: UIButton!
    @IBOutlet weak var selectImageBtn: UIButton!
    var activityIndicator:UIActivityIndicatorView!
    var ocrEngine:LB_OCR.Manager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        do {
            ocrEngine = try LB_OCR.Manager(languages: [Language.English, Language.French])
            selectImageBtn.enabled = true
            recognizeBtn.enabled = true
        }catch let error as NSError{
            print("error is \(error.code) \(error.localizedFailureReason ?? "")")
        }
    }
    
    @IBAction func findSquarePointClick(sender: AnyObject) {
    }
    @IBAction func recognizeClick(sender: AnyObject) {
    }
    @IBAction func selectImageClick(sender: AnyObject) {
        // 1
        view.endEditing(true)
        ()
        // 2
        let imagePickerActionSheet = UIAlertController(title: "Snap/Upload Photo",
                                                       message: nil, preferredStyle: .ActionSheet)
        // 3
        if UIImagePickerController.isSourceTypeAvailable(.Camera) {
            let cameraButton = UIAlertAction(title: "Take Photo",
                                             style: .Default) { (alert) -> Void in
                                                let imagePicker = UIImagePickerController()
                                                imagePicker.delegate = self
                                                imagePicker.sourceType = .Camera
                                                self.presentViewController(imagePicker,
                                                                           animated: true,
                                                                           completion: nil)
            }
            imagePickerActionSheet.addAction(cameraButton)
        }
        // 4
        let libraryButton = UIAlertAction(title: "Choose Existing",
                                          style: .Default) { (alert) -> Void in
                                            let imagePicker = UIImagePickerController()
                                            imagePicker.delegate = self
                                            imagePicker.sourceType = .PhotoLibrary
                                            self.presentViewController(imagePicker,
                                                                       animated: true,
                                                                       completion: nil)
        }
        imagePickerActionSheet.addAction(libraryButton)
        // 5
        let cancelButton = UIAlertAction(title: "Cancel",
                                         style: .Cancel) { (alert) -> Void in
        }
        imagePickerActionSheet.addAction(cancelButton)
        // 6
        presentViewController(imagePickerActionSheet, animated: true,
                              completion: nil)
    }
    
    func performImageRecognition(image: UIImage) {
        ocrEngine.recognize(image) {[weak self] (recognizedText, error) in
            self?.removeActivityIndicator()
            
            if error == nil{
                self?.textView.text = recognizedText
            }
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // Activity Indicator methods
    
    func addActivityIndicator() {
        activityIndicator = UIActivityIndicatorView(frame: view.bounds)
        activityIndicator.activityIndicatorViewStyle = .WhiteLarge
        activityIndicator.backgroundColor = UIColor(white: 0, alpha: 0.25)
        activityIndicator.startAnimating()
        view.addSubview(activityIndicator)
    }
    
    func removeActivityIndicator() {
        activityIndicator.removeFromSuperview()
        activityIndicator = nil
    }

}

extension ViewController: UIImagePickerControllerDelegate {
    func imagePickerController(picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        let selectedPhoto = info[UIImagePickerControllerOriginalImage] as! UIImage
        //let scaledImage = scaleImage(selectedPhoto, maxDimension: 640)
        
        addActivityIndicator()
        imageView.image = selectedPhoto
        dismissViewControllerAnimated(true, completion: {
            self.performImageRecognition(selectedPhoto)
        })
    }
}