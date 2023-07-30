//
//  ViewController.swift
//  MemeMe 1.0
//
//  Created by Sihle Ntuli on 2023/07/30.
//

import UIKit

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate,  UIPickerViewDelegate, UIPickerViewDataSource {
    
    @IBOutlet weak var imagePickerView: UIImageView!
    @IBOutlet weak var albumBbutton: UIBarButtonItem!
    @IBOutlet weak var cameraButton: UIBarButtonItem!
    @IBOutlet weak var topTextField: UITextField!
    @IBOutlet weak var bottomTextField: UITextField!
    @IBOutlet weak var toolBar: UIToolbar!
    @IBOutlet weak var shareButton: UIBarButtonItem!
    
    var memes: [Meme] = []
    var fontPicker: UIPickerView?
    var fontNames: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        topTextField.text = "TOP"
        bottomTextField.text = "BOTTOM"
        
        topTextField.textAlignment = .center
        bottomTextField.textAlignment = .center
        
        let memeTextAttributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key.strokeColor: UIColor.black,
            NSAttributedString.Key.foregroundColor: UIColor.white,
            NSAttributedString.Key.font: UIFont(name: "Impact", size: 40)!,
            NSAttributedString.Key.strokeWidth: -3.0
        ]
        
        topTextField.defaultTextAttributes = memeTextAttributes
        bottomTextField.defaultTextAttributes = memeTextAttributes
        
        topTextField.delegate = self
        bottomTextField.delegate = self
        
        fontNames = UIFont.familyNames.sorted()
        
        // Initialize the font picker and set its delegate and data source
        fontPicker = UIPickerView()
        fontPicker?.delegate = self
        fontPicker?.dataSource = self
        
        // Assign the font picker as the input view for both text fields
        topTextField.inputView = fontPicker
        bottomTextField.inputView = fontPicker
        
        shareButton.isEnabled = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        cameraButton.isEnabled = UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera)
        subscribeToKeyboardNotification()
        
        checkEnableShareButton()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unsubscribeFromKeyboardNotifications()
    }
    
    @IBAction func pickAnImageFromAlbum(_ sender: Any) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        imagePicker.allowsEditing = true
        present(imagePicker, animated: true, completion: nil)
    }
    
    @IBAction func pickAnImageFromCamera(_ sender: Any) {
        
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        imagePicker.allowsEditing = true
        present(imagePicker, animated: true, completion: nil)
    }
    
    @IBAction func shareMeme(_ sender: Any) {
        guard let memedImage = generateMemedImage() else {
            print("Error generating memed image.")
            return
        }
        
        let activityViewController = UIActivityViewController(activityItems: [memedImage], applicationActivities: nil)
        
        activityViewController.completionWithItemsHandler = { activityType, completed, returnedItems, activityError in
            guard completed else {
                print("User canceled the sharing.")
                return
            }
        }
        
        present(activityViewController, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let editedImage = info[.editedImage] as? UIImage {
            imagePickerView.image = editedImage
        } else if let originalImage = info[.originalImage] as? UIImage {
            imagePickerView.image = originalImage
        }
        
        picker.dismiss(animated: true, completion: nil)
        
        checkEnableShareButton()
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField.text == "TOP" || textField.text == "BOTTOM" {
            textField.text = ""
        }
        
        checkEnableShareButton()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        view.frame.origin.y = -getKeyboardHeight(notification: notification)
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        view.frame.origin.y = 0
    }
    
    func subscribeToKeyboardNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    func unsubscribeFromKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    func getKeyboardHeight(notification: Notification) -> CGFloat {
        let userInfo = notification.userInfo!
        let keyboardSize = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue
        return keyboardSize.cgRectValue.height
    }
    
    func hideBars(_ hide: Bool) {
        navigationController?.setNavigationBarHidden(hide, animated: false)
        toolBar.isHidden = hide
    }
    
    func generateMemedImage() -> UIImage? {
        hideBars(true)
        UIGraphicsBeginImageContextWithOptions(view.frame.size, false, UIScreen.main.scale)
        view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
        let memedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        hideBars(false)
        
        return memedImage
    }
    
    func save(meme: Meme) {
        if let memedImage = generateMemedImage() {
            let meme = Meme(topText: topTextField.text!, bottomText: bottomTextField.text!, originalImage: imagePickerView.image!, memedImage: memedImage)
            UIImageWriteToSavedPhotosAlbum(meme.memedImage, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
        } else {
            print("Error generating memed image.")
        }
    }
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            print("Error saving image to photo library: \(error.localizedDescription)")
        } else {
            print("Image saved to photo library")
        }
    }
    
    func checkEnableShareButton() {
        shareButton.isEnabled = imagePickerView.image != nil && !topTextField.text!.isEmpty && !bottomTextField.text!.isEmpty
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return fontNames.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return fontNames[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let selectedFontName = fontNames[row]
        // Apply the selected font to the text fields
        topTextField.font = UIFont(name: selectedFontName, size: 40)
        bottomTextField.font = UIFont(name: selectedFontName, size: 40)
    }
    
    func updateTextFieldsFont(fontName: String) {
        let memeTextAttributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key.strokeColor: UIColor.black,
            NSAttributedString.Key.foregroundColor: UIColor.white,
            NSAttributedString.Key.font: UIFont(name: fontName, size: 40)!,
            NSAttributedString.Key.strokeWidth: -3.0
        ]
        
        topTextField.defaultTextAttributes = memeTextAttributes
        bottomTextField.defaultTextAttributes = memeTextAttributes
    }
}
