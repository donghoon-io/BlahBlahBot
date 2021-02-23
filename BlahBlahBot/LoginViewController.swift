//
//  LoginViewController.swift
//  BlahBlahBot
//
//  Created by Donghoon Shin on 2020/12/17.
//

import UIKit
import WebKit
import ComposableRequest
import ComposableRequestCrypto
import Swiftagram
import SwiftagramCrypto
import ANLoader

class LoginViewController: UIViewController {
    
    var delegate: isAbleToReceiveData?
    
    let client = Client.default
    
    /// The web view.
    var webView: WKWebView? {
        didSet {
            oldValue?.removeFromSuperview() // Just in case.
            guard let webView = webView else { return }
            webView.frame = view.bounds     // Fill the parent view.
            // You should also deal with layout constraints or similar here…
            view.addSubview(webView)        // Add it to the parent view.
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        WebViewAuthenticator(storage: ComposableRequestCrypto.KeychainStorage<Secret>(),
                             client: client) { self.webView = $0 }
            .authenticate { [weak self] in
                switch $0 {
                case .failure(let error): print(error.localizedDescription)
                case .success(let secret):
                    print("success")
                    self?.delegate?.pass(id: secret.identifier, sec: secret)
                    self?.dismiss(animated: true, completion: {
                        ANLoader.showLoading("로그인 중\n최대 1분이 소요될 수 있습니다", disableUI: false)
                    })
                }
            }
    }
}
protocol isAbleToReceiveData {
    func pass(id: String, sec: Secret)  //data: string is an example parameter
}
