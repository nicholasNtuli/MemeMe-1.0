//
//  MemeEditorViewController.swift
//  MemeMe 1.0
//
//  Created by Sihle Ntuli on 2023/07/30.
//

import UIKit

class MemeEditorViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate,  UIPickerViewDelegate, UIPickerViewDataSource {
    
    @IBOutlet weak var imagePickerView: UIImageView!
    @IBOutlet weak var albumBbutton: UIBarButtonItem!
    @IBOutlet weak var cameraButton: UIBarButtonItem!
    @IBOutlet weak var fontButton: UIBarButtonItem!
    @IBOutlet weak var topTextField: UITextField!
    @IBOutlet weak var bottomTextField: UITextField!
    @IBOutlet weak var toolBar: UIToolbar!
    @IBOutlet weak var shareButton: UIBarButtonItem!
    
    var fontPicker: UIPickerView?
    var fontNames: [String] = UIFont.familyNames.sorted()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        prepareTextField(topTextField, defaultText: "TOP")
        prepareTextField(bottomTextField, defaultText: "BOTTOM")
        shareButton.isEnabled = false
        setupFontPickerView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        #if targetEnvironment(simulator)
        cameraButton.isEnabled = false
        #else
        cameraButton.isEnabled = UIImagePickerController.isSourceTypeAvailable(.camera)
        #endif
        
        subscribeToKeyboardNotification()
        checkEnableShareButton()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unsubscribeFromKeyboardNotifications()
    }
    
    func setupFontPickerView() {
        // Font picker setup
        fontPicker = UIPickerView()
        fontPicker?.delegate = self
        fontPicker?.dataSource = self
        
        // Font picker toolbar setup
        let fontPickerToolbar = UIToolbar()
        fontPickerToolbar.barStyle = .default
        fontPickerToolbar.isTranslucent = true
        fontPickerToolbar.sizeToFit()
        
        let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(fontPickerDoneButtonTapped))
        let spaceButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        fontPickerToolbar.setItems([spaceButton, doneButton], animated: false)
        fontPickerToolbar.isUserInteractionEnabled = true
        
        // Set the font picker toolbar as the input accessory view for the text fields
        topTextField.inputAccessoryView = fontPickerToolbar
        bottomTextField.inputAccessoryView = fontPickerToolbar
        
        // Set the input view of the text fields to nil initially
        topTextField.inputView = nil
        bottomTextField.inputView = nil
    }

    func prepareTextField(_ textField: UITextField, defaultText: String) {
        textField.text = defaultText
        textField.textAlignment = .center
        
        var memeTextAttributes = textField.defaultTextAttributes
        if memeTextAttributes == nil {
            memeTextAttributes = [NSAttributedString.Key: Any]()
        }
        
        memeTextAttributes[NSAttributedString.Key.strokeColor] = UIColor.black
        memeTextAttributes[NSAttributedString.Key.foregroundColor] = UIColor.white
        
        let font = UIFont(name: "Impact", size: 40)!
        memeTextAttributes[NSAttributedString.Key.font] = font
        memeTextAttributes[NSAttributedString.Key.strokeWidth] = -3.0
        
        textField.defaultTextAttributes = memeTextAttributes
        textField.delegate = self
    }
    
    @IBAction func selectToolBarButton(_ sender: Any) {
        if let button = sender as? UIButton, button.tag == 1 {
            fontButtonTapped(sender)
        } else {
            handleIfImageButtonOrCameraButtonIsTapped(sender)
        }
    }
    
    func pickImage(sourceType: UIImagePickerController.SourceType) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = sourceType
        imagePicker.allowsEditing = true
        present(imagePicker, animated: true, completion: nil)
    }
    
    func handleIfImageButtonOrCameraButtonIsTapped(_ sender: Any) {
        if let button = sender as? UIBarButtonItem {
            if button == albumBbutton {
                // Album button pressed
                pickImage(sourceType: .photoLibrary)
            } else if button == cameraButton {
                // Camera button pressed
                pickImage(sourceType: .camera)
            }
        }
    }
    
    @IBAction func fontButtonTapped(_ sender: Any) {
        if topTextField.isFirstResponder || bottomTextField.isFirstResponder {
            view.endEditing(true)
        }
        
        if topTextField.inputView == nil {
            topTextField.inputView = fontPicker
            bottomTextField.inputView = fontPicker
            topTextField.becomeFirstResponder()
        } else {
            topTextField.inputView = nil
            bottomTextField.inputView = nil
        }
    }
    
    @objc func fontPickerDoneButtonTapped() {
        topTextField.resignFirstResponder()
        bottomTextField.resignFirstResponder()
        
        // Set the input view of the text fields back to nil
        topTextField.inputView = nil
        bottomTextField.inputView = nil
    }
    
    @IBAction func shareMeme(_ sender: Any) {
        guard let memedImage = generateMemedImage() else {
            return
        }
        
        let meme = Meme(topText: topTextField.text!,
                        bottomText: bottomTextField.text!,
                        originalImage: imagePickerView.image!,
                        memedImage: memedImage)
        
        let activityViewController = UIActivityViewController(activityItems: [memedImage], applicationActivities: nil)
        
        activityViewController.completionWithItemsHandler = { [weak self] activityType, completed, returnedItems, activityError in
            guard completed else {
                return
            }
            
            self?.save(meme: meme)
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
        if bottomTextField.isFirstResponder {
            view.frame.origin.y = -getKeyboardHeight(notification: notification)
        }
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
        topTextField.font = UIFont(name: selectedFontName, size: 40)
        bottomTextField.font = UIFont(name: selectedFontName, size: 40)
    }

}
