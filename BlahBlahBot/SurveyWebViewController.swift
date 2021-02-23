//
//  SurveyWebViewController.swift
//  BlahBlahBot
//
//  Created by Donghoon Shin on 2020/12/22.
//

import UIKit
import WebKit

class SurveyWebViewController: UIViewController {
    
    let url = URL(string: "https://forms.gle/GNyrBxoo3xsFGX3t9")
    
    @IBOutlet weak var webView: WKWebView!
    let progressView = UIProgressView(progressViewStyle: .default)
    private var estimatedProgressObserver: NSKeyValueObservation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "설문조사"
        
        navigationItem.hidesBackButton = true
        
        setupProgressView()
        setupEstimatedProgressObserver()
        
        let request = URLRequest(url: url!)
        webView.navigationDelegate = self

        webView.load(request)

        // Do any additional setup after loading the view.
    }
    private func setupProgressView() {
           guard let navigationBar = navigationController?.navigationBar else { return }

           progressView.translatesAutoresizingMaskIntoConstraints = false
           navigationBar.addSubview(progressView)

           progressView.isHidden = true

           NSLayoutConstraint.activate([
               progressView.leadingAnchor.constraint(equalTo: navigationBar.leadingAnchor),
               progressView.trailingAnchor.constraint(equalTo: navigationBar.trailingAnchor),

               progressView.bottomAnchor.constraint(equalTo: navigationBar.bottomAnchor),
               progressView.heightAnchor.constraint(equalToConstant: 2.0)
           ])
       }

       private func setupEstimatedProgressObserver() {
           estimatedProgressObserver = webView.observe(\.estimatedProgress, options: [.new]) { [weak self] webView, _ in
               self?.progressView.progress = Float(webView.estimatedProgress)
           }
       }

}
extension SurveyWebViewController: WKNavigationDelegate {
    func webView(_: WKWebView, didStartProvisionalNavigation _: WKNavigation!) {
        if progressView.isHidden {
            // Make sure our animation is visible.
            progressView.isHidden = false
        }

        UIView.animate(withDuration: 0.33,
                       animations: {
                           self.progressView.alpha = 1.0
        })
    }

    func webView(_: WKWebView, didFinish _: WKNavigation!) {
        UIView.animate(withDuration: 0.33,
                       animations: {
                           self.progressView.alpha = 0.0
                       },
                       completion: { isFinished in
                           // Update `isHidden` flag accordingly:
                           //  - set to `true` in case animation was completly finished.
                           //  - set to `false` in case animation was interrupted, e.g. due to starting of another animation.
                           self.progressView.isHidden = isFinished
        })
    }
}
