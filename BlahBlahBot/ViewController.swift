//
//  ViewController.swift
//  BlahBlahBot
//
//  Created by Donghoon Shin on 2020/12/17.
//

import UIKit
import Combine
import WebKit
import FirebaseFirestore
import ComposableRequest
import ComposableRequestCrypto
import Swiftagram
import SwiftagramCrypto
import Alamofire
import SwiftyJSON
import TagListView
import ANLoader

class ViewController: UIViewController, UITextFieldDelegate, isAbleToReceiveData, TagListViewDelegate {
    
    let db = Firestore.firestore()
    
    var identifier: String?
    var secret: Secret?
    
    var posts = [String]()
    var postsCounter = [String]()
    
    var comments = [String]()
    
    var themes = [String]()
    var finalThemes = [String]()
    
    var participant1 = "http://ec2-3-35-233-177.ap-northeast-2.compute.amazonaws.com:80/"
    var participant2 = "http://ec2-13-125-206-148.ap-northeast-2.compute.amazonaws.com:80/"
    
    func pass(id: String, sec: Secret) {
        self.loginButton.setTitleColor(UIColor.lightGray, for: .normal)
        self.loginButton.isEnabled = false
        identifier = id
        secret = sec
        
        Endpoint.Media.Posts.owned(by: sec.identifier).unlocking(with: sec).task(maxLength: .max, by: .instagram) { (yaya) in
            ANLoader.hide()
            print(self.posts)
            self.db.collection("Data").document(experimentID).setData(["data": self.posts]) { (error) in
                if let error = error {
                    let alertController = UIAlertController(title: error.localizedDescription, message: "실험 주관인에게 문의하시오", preferredStyle: .actionSheet)
                    alertController.addAction(UIAlertAction(title: "확인", style: .default, handler: nil))
                    self.present(alertController, animated: true, completion: nil)
                    return
                } else {
                    self.uploadLabel.textColor = self.color333
                    self.uploadLabel.isHidden = false
                    self.uploadButton.setTitleColor(self.color333, for: .normal)
                    self.uploadButton.isEnabled = true
                    self.uploadButton.isHidden = false
                }
            }
        } onChange: { (result) in
            switch result {
            case .success(let posts):
                if let post = posts.media {
                    self.posts += post.map { (media) -> String in
                        return media.caption?.text ?? ""
                    }
                }
                
            case .failure(let error):
                let alertController = UIAlertController(title: error.localizedDescription, message: "실험 주관인에게 문의하시오", preferredStyle: .actionSheet)
                alertController.addAction(UIAlertAction(title: "확인", style: .default, handler: nil))
                self.present(alertController, animated: true, completion: nil)
            }
        }.resume()

        /*
        Endpoint.Media.Posts.owned(by: sec.identifier).unlocking(with: sec)
            .task(maxLength: .max) { (result) in
                print("yaya")
                ANLoader.hide()
                switch result {
                case .success(let posts):
                    if let post = posts.media {
                        self.posts = post.map { (media) -> String in
                            return media.caption?.text ?? ""
                        }
                    }
                    self.db.collection("Data").document(experimentID).setData(["data": self.posts]) { (error) in
                        if let error = error {
                            let alertController = UIAlertController(title: error.localizedDescription, message: "실험 주관인에게 문의하시오", preferredStyle: .actionSheet)
                            alertController.addAction(UIAlertAction(title: "확인", style: .default, handler: nil))
                            self.present(alertController, animated: true, completion: nil)
                            return
                        } else {
                            self.db.collection("Data").document(experimentID).updateData(["isDone": "true"]) { (err) in
                                if let err = error {
                                    let alertController = UIAlertController(title: err.localizedDescription, message: "실험 주관인에게 문의하시오", preferredStyle: .actionSheet)
                                    alertController.addAction(UIAlertAction(title: "확인", style: .default, handler: nil))
                                    self.present(alertController, animated: true, completion: nil)
                                    return
                                } else {
                                    self.uploadLabel.textColor = self.color333
                                    self.uploadLabel.isHidden = false
                                    self.uploadButton.setTitleColor(self.color333, for: .normal)
                                    self.uploadButton.isEnabled = true
                                    self.uploadButton.isHidden = false

                                }
                            }
                        }
                    }
                case .failure(let error):
                    let alertController = UIAlertController(title: error.localizedDescription, message: "실험 주관인에게 문의하시오", preferredStyle: .actionSheet)
                    alertController.addAction(UIAlertAction(title: "확인", style: .default, handler: nil))
                    self.present(alertController, animated: true, completion: nil)
                }
            }
            .resume()*/
    }
    
    
    let color333 = UIColor(red: 51/255.0, green: 51/255.0, blue: 51/255.0, alpha: 1)
    
    var selectedThemes = [String]()
    
    func createTag(_ texts: [String]) {
        for item in texts {
            let tagView = themeView.addTag("# \(item)")
            tagView.tagBackgroundColor = UIColor.systemGray6
            tagView.frame.size.height = 15
            tagView.textColor = .systemGray2
            tagView.onTap = { tagView in
                if self.selectedThemes.contains(item) {
                    self.selectedThemes = self.selectedThemes.filter { $0 != item }
                    tagView.tagBackgroundColor = .systemGray6
                    tagView.textColor = .systemGray2
                } else {
                    self.selectedThemes.append(item)
                    tagView.tagBackgroundColor = .systemBlue
                    tagView.textColor = .white
                }
                self.startButton.isEnabled = self.selectedThemes.count != 0
                self.startButton.setTitleColor(self.selectedThemes.count == 0 ? UIColor.lightGray : self.color333, for: .normal)
            }
        }
        tagHeight.constant = self.themeView.intrinsicContentSize.height
        self.view.layoutIfNeeded()
    }
    func setTagListView() {
        themeView.textFont = UIFont.systemFont(ofSize: 15.0, weight: .medium)
        themeView.alignment = .center
        themeView.paddingX = 7
        themeView.paddingY = 7
        themeView.marginX = 7
        themeView.marginY = 7
        themeView.cornerRadius = 12
    }
    @IBOutlet weak var tagHeight: NSLayoutConstraint!
    
    @IBOutlet weak var pidLabel: UILabel!
    @IBOutlet weak var igLabel: UILabel! {
        didSet {
            igLabel.isHidden = true
        }
    }
    @IBOutlet weak var recommendationLabel: UILabel! {
        didSet {
            recommendationLabel.isHidden = true
        }
    }
    @IBOutlet weak var themeView: TagListView!
    
    @IBOutlet weak var uploadLabel: UILabel! {
        didSet {
            uploadLabel.isHidden = true
        }
    }
    @IBOutlet weak var pidField: UITextField!
    
    @IBOutlet weak var enterButton: UIButton! {
        didSet {
            enterButton.layer.cornerRadius = 7
        }
    }
    @IBOutlet weak var loginButton: UIButton! {
        didSet {
            loginButton.layer.cornerRadius = 7
            loginButton.isEnabled = false
            loginButton.isHidden = true
        }
    }
    @IBOutlet weak var uploadButton: UIButton! {
        didSet {
            uploadButton.layer.cornerRadius = 7
            uploadButton.isEnabled = false
            uploadButton.isHidden = true
        }
    }
    @IBOutlet weak var startButton: UIButton! {
        didSet {
            startButton.layer.cornerRadius = 7
            startButton.isEnabled = false
            startButton.isHidden = true
        }
    }
    @IBAction func enterClicked(_ sender: UIButton) {
        self.enterButton.isEnabled = false
        pidField.resignFirstResponder()
        if pidField.text != "" {
            experimentID = pidField.text!
            
            switch experimentID.prefix(1) {
            case "1":
                igLabel.textColor = color333
                igLabel.isHidden = false
                enterButton.setTitleColor(UIColor.lightGray, for: .normal)
                enterButton.isEnabled = false
                loginButton.isEnabled = true
                loginButton.isHidden = false
                loginButton.setTitleColor(color333, for: .normal)
            case "2", "3":
                enterButton.setTitleColor(UIColor.lightGray, for: .normal)
                enterButton.isEnabled = false
                startButton.setTitleColor(color333, for: .normal)
                startButton.isEnabled = true
                startButton.isHidden = false
            default:
                break
            }
        } else {
            self.enterButton.isEnabled = true
            pidLabel.textColor = .systemRed
            pidField.text = ""
            pidField.placeholder = "올바른 번호를 입력해주세요"
        }
    }
    
    @IBAction func uploadClicked(_ sender: UIButton) {
        self.uploadButton.isEnabled = false
        ANLoader.showLoading("업로드 중...", disableUI: true)
        let counterpartID = Int(experimentID)! % 2 == 0 ? String(Int(experimentID)!+1) : String(Int(experimentID)!-1)
        self.db.collection("Data").document(counterpartID).getDocument { (snapshot, error) in
            if let error = error {
                ANLoader.hide()
                self.showAlert(error.localizedDescription)
            } else {
                if let data = snapshot?.get("data") as? [String] {
                    print("counter: \(data)")
                    self.postsCounter = data
                    var parameters = [String:[String]]()
                    if Int(experimentID)! % 2 == 0 {
                        parameters = ["sentences1": self.postsCounter, "sentences2": self.posts]
                    } else {
                        parameters = ["sentences1": self.posts, "sentences2": self.postsCounter]
                    }
                    AF.request(Int(experimentID)! % 2==0 ? self.participant1 : self.participant2,
                               method: .post,
                               parameters: parameters,
                               encoder: JSONParameterEncoder.default).response { response in
                                ANLoader.hide()
                                switch response.result {
                                case .success(let data):
                                    if let themes = JSON(data)["themes"].arrayObject as? [String] {
                                        print(themes)
                                        self.themes = themes
                                        self.createTag(themes)
                                        self.startButton.isHidden = false
                                        self.uploadButton.isEnabled = false
                                        self.uploadButton.setTitleColor(.lightGray, for: .normal)
                                        self.recommendationLabel.isHidden = false
                                        self.recommendationLabel.textColor = self.color333
                                    }
                                case .failure(let error):
                                    self.uploadButton.isEnabled = true
                                    self.showAlert(error.localizedDescription)
                                }
                               }
                } else {
                    ANLoader.hide()
                    ANLoader.showLoading("상대방을 기다리는 중...", disableUI: true)
                    self.db.collection("Data").document(counterpartID).addSnapshotListener { (snapshot2, error2) in
                        if let err2 = error2 {
                            self.uploadButton.isEnabled = true
                            self.showAlert(err2.localizedDescription)
                        } else {
                            if let counterTheme1 = snapshot2?.get("data") as? [String] {
                                print("counter: \(counterTheme1)")
                                self.postsCounter = counterTheme1
                                var parameters = [String:[String]]()
                                if Int(experimentID)! % 2 == 0 {
                                    parameters = ["sentences1": self.postsCounter, "sentences2": self.posts]
                                } else {
                                    parameters = ["sentences1": self.posts, "sentences2": self.postsCounter]
                                }
                                AF.request(Int(experimentID)! % 2==0 ? self.participant1 : self.participant2,
                                           method: .post,
                                           parameters: parameters,
                                           encoder: JSONParameterEncoder.default).response { response in
                                            ANLoader.hide()
                                            switch response.result {
                                            case .success(let data):
                                                if let themes = JSON(data)["themes"].arrayObject as? [String] {
                                                    print(themes)
                                                    self.themes = themes
                                                    self.createTag(themes)
                                                    self.startButton.isHidden = false
                                                    self.uploadButton.isEnabled = false
                                                    self.uploadButton.setTitleColor(.lightGray, for: .normal)
                                                    self.recommendationLabel.isHidden = false
                                                    self.recommendationLabel.textColor = self.color333
                                                }
                                            case .failure(let error):
                                                self.uploadButton.isEnabled = true
                                                self.showAlert(error.localizedDescription)
                                            }
                                           }
                                ANLoader.hide()
                            }
                        }
                    }
                }
            }
        }
    }
    @IBAction func loginClicked(_ sender: UIButton) {
        self.loginButton.isEnabled = false
        let vc = LoginViewController()
        vc.delegate = self
        self.present(vc, animated: true, completion: nil)
        
    }
    @IBAction func chatClicked(_ sender: UIButton) {
        self.startButton.isEnabled = false
        ANLoader.showLoading("상대방 기다리는 중...", disableUI: true)
        
        switch experimentID.prefix(1) {
        case "1":
            let counter = Int(experimentID)! % 2 == 0 ? "\(Int(experimentID)!+1)" : "\(Int(experimentID)!-1)"
            let counterDocument = self.db.collection("Data").document(counter)
            
            
            if Int(experimentID)! % 2 == 0 {
                self.db.collection("Data").document(experimentID).updateData(["themes": self.themes]) { (error) in
                    if let error = error {
                        self.startButton.isEnabled = true
                        let alertController = UIAlertController(title: error.localizedDescription, message: "실험 주관인에게 문의하시오", preferredStyle: .actionSheet)
                        alertController.addAction(UIAlertAction(title: "확인", style: .default, handler: nil))
                        self.present(alertController, animated: true, completion: nil)
                        return
                    } else {
                        counterDocument.getDocument { (snapshot1, error1) in
                            if let err = error1 {
                                self.startButton.isEnabled = true
                                self.showAlert(err.localizedDescription)
                            } else {
                                if let counterTheme = snapshot1?.get("themes") as? [String] {
                                    ANLoader.hide()
                                    
                                    let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "Chat1ViewController") as! Chat1ViewController
                                    self.navigationController?.pushViewController(vc, animated: true)
                                } else {
                                    counterDocument.addSnapshotListener { (snapshot2, error2) in
                                        if let err2 = error2 {
                                            self.startButton.isEnabled = true
                                            self.showAlert(err2.localizedDescription)
                                        } else {
                                            if let counterTheme1 = snapshot2?.get("themes") as? [String] {
                                                ANLoader.hide()
                                                
                                                let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "Chat1ViewController") as! Chat1ViewController
                                                self.navigationController?.pushViewController(vc, animated: true)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            } else {
                createNewChat { (errrrr) in
                    if let erer = errrrr {
                        self.startButton.isEnabled = true
                        self.showAlert(erer.localizedDescription)
                    } else {
                        self.db.collection("Data").document(experimentID).setData(["themes": self.themes]) { (error) in
                            if let error = error {
                                self.startButton.isEnabled = true
                                let alertController = UIAlertController(title: error.localizedDescription, message: "실험 주관인에게 문의하시오", preferredStyle: .actionSheet)
                                alertController.addAction(UIAlertAction(title: "확인", style: .default, handler: nil))
                                self.present(alertController, animated: true, completion: nil)
                                return
                            } else {
                                counterDocument.getDocument { (snapshot1, error1) in
                                    if let err = error1 {
                                        self.showAlert(err.localizedDescription)
                                    } else {
                                        if let counterTheme = snapshot1?.get("themes") as? [String] {
                                            self.finalThemes = self.handleThemes(me: self.selectedThemes, counter: counterTheme)
                                            print("이거다111\(self.handleThemes(me: self.selectedThemes, counter: counterTheme))")
                                            ANLoader.hide()
                                            
                                            let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "Chat1ViewController") as! Chat1ViewController
                                            vc.themesToDiscuss = self.finalThemes
                                            self.navigationController?.pushViewController(vc, animated: true)
                                        } else {
                                            counterDocument.addSnapshotListener { (snapshot2, error2) in
                                                if let err2 = error2 {
                                                    self.startButton.isEnabled = true
                                                    self.showAlert(err2.localizedDescription)
                                                } else {
                                                    if let counterTheme1 = snapshot2?.get("themes") as? [String] {
                                                        self.finalThemes = self.handleThemes(me: self.selectedThemes, counter: counterTheme1)
                                                        print("이거다\(self.handleThemes(me: self.selectedThemes, counter: counterTheme1))")
                                                        ANLoader.hide()
                                                        
                                                        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "Chat1ViewController") as! Chat1ViewController
                                                        vc.themesToDiscuss = self.finalThemes
                                                        self.navigationController?.pushViewController(vc, animated: true)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        case "2", "3":
            let counter = Int(experimentID)! % 2 == 0 ? "\(Int(experimentID)!+1)" : "\(Int(experimentID)!-1)"
            let counterDocument = self.db.collection("Data").document(counter)
            
            if Int(experimentID)! % 2 == 0 {
                self.db.collection("Data").document(experimentID).setData(["isReady": "isReady"]) { (error) in
                    if let error = error {
                        self.startButton.isEnabled = true
                        let alertController = UIAlertController(title: error.localizedDescription, message: "실험 주관인에게 문의하시오", preferredStyle: .actionSheet)
                        alertController.addAction(UIAlertAction(title: "확인", style: .default, handler: nil))
                        self.present(alertController, animated: true, completion: nil)
                        return
                    } else {
                        counterDocument.getDocument { (snapshot1, error1) in
                            if let err = error1 {
                                self.startButton.isEnabled = true
                                self.showAlert(err.localizedDescription)
                            } else {
                                if let isReady = snapshot1?.get("isReady") as? String {
                                    ANLoader.hide()
                                    
                                    if experimentID.prefix(1) == "2" {
                                        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "Chat2ViewController") as! Chat2ViewController
                                        self.navigationController?.pushViewController(vc, animated: true)
                                    } else {
                                        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "Chat3ViewController") as! Chat3ViewController
                                        self.navigationController?.pushViewController(vc, animated: true)
                                    }
                                } else {
                                    counterDocument.addSnapshotListener { (snapshot2, error2) in
                                        if let err2 = error2 {
                                            self.startButton.isEnabled = true
                                            self.showAlert(err2.localizedDescription)
                                        } else {
                                            if let isReady1 = snapshot2?.get("isReady") as? String {
                                                ANLoader.hide()
                                                if experimentID.prefix(1) == "2" {
                                                    let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "Chat2ViewController") as! Chat2ViewController
                                                    self.navigationController?.pushViewController(vc, animated: true)
                                                } else {
                                                    let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "Chat3ViewController") as! Chat3ViewController
                                                    self.navigationController?.pushViewController(vc, animated: true)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            } else {
                createNewChat { (errrr) in
                    if let errrrrr = errrr {
                        self.startButton.isEnabled = true
                        self.showAlert(errrrrr.localizedDescription)
                    } else {
                        self.db.collection("Data").document(experimentID).setData(["isReady": "isReady"]) { (error) in
                            if let error = error {
                                let alertController = UIAlertController(title: error.localizedDescription, message: "실험 주관인에게 문의하시오", preferredStyle: .actionSheet)
                                alertController.addAction(UIAlertAction(title: "확인", style: .default, handler: nil))
                                self.present(alertController, animated: true, completion: nil)
                                return
                            } else {
                                counterDocument.getDocument { (snapshot1, error1) in
                                    if let err = error1 {
                                        self.showAlert(err.localizedDescription)
                                    } else {
                                        if let isReady = snapshot1?.get("isReady") as? String {
                                            ANLoader.hide()
                                            
                                            if experimentID.prefix(1) == "2" {
                                                let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "Chat2ViewController") as! Chat2ViewController
                                                self.navigationController?.pushViewController(vc, animated: true)
                                            } else {
                                                let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "Chat3ViewController") as! Chat3ViewController
                                                self.navigationController?.pushViewController(vc, animated: true)
                                            }
                                        } else {
                                            counterDocument.addSnapshotListener { (snapshot2, error2) in
                                                if let err2 = error2 {
                                                    self.startButton.isEnabled = true
                                                    self.showAlert(err2.localizedDescription)
                                                } else {
                                                    if let isReady1 = snapshot2?.get("isReady") as? String {
                                                        ANLoader.hide()
                                                        if experimentID.prefix(1) == "2" {
                                                            let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "Chat2ViewController") as! Chat2ViewController
                                                            self.navigationController?.pushViewController(vc, animated: true)
                                                        } else {
                                                            let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "Chat3ViewController") as! Chat3ViewController
                                                            self.navigationController?.pushViewController(vc, animated: true)
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        default:
            break
        }
    }
    
    func handleThemes(me: [String], counter: [String]) -> [String] {
        let common = me.filter{ counter.contains($0) }
        let sum = me + counter
        let minus = sum.filter{ !common.contains($0) }
        return common + minus.shuffled()
    }
    
    func showAlert(_ err: String) {
        let alertController = UIAlertController(title: err, message: "실험 주관인에게 문의하시오", preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "확인", style: .default, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        pidField.delegate = self
        themeView.delegate = self
        
        Requester.default = .instagram
        setTagListView()
    }
    //홀수만 이걸 하게 해야함
    func createNewChat(completionHandler: @escaping (_ err: Error?) -> ()) {
        let users = [experimentID, String(Int(experimentID)! % 2 == 0 ? Int(experimentID)!+1 : Int(experimentID)!-1), "123123123123123"]
        let data: [String: Any] = [
            "users":users
        ]
        
        Firestore.firestore().collection("Chats").addDocument(data: data) { (error) in
            completionHandler(error)
        }
    }
}
extension Collection {
    func choose(_ n: Int) -> ArraySlice<Element> { shuffled().prefix(n) }
}
