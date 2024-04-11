//
//  WebViewController.swift
//  spense-sdk-ios
//
//  Created by Varun on 30/10/23.
//

import Foundation
import WebKit
import AVFoundation
import UIKit
import SwiftUI

public class WebViewController: UIViewController, WKNavigationDelegate, WKUIDelegate {
    
    private let whitelistedUrls = ["razorpay.com"]
    public weak var delegate: WebViewControllerDelegate?
    
    private lazy var webView: WKWebView = {
        let webConfiguration = WKWebViewConfiguration()
        let userContentController = WKUserContentController()
        
        // Add your existing message handler
        userContentController.add(self, name: "iosListener")
        
        // Script to intercept console.log messages and forward them to Swift
        let scriptSource = """
        var originalConsoleLog = console.log;
        console.log = function(message) {
            window.webkit.messageHandlers.interceptor.postMessage(message);
            originalConsoleLog.apply(console, arguments);
        };
        """
        
        let script = WKUserScript(source: scriptSource, injectionTime: .atDocumentStart, forMainFrameOnly: true)
        userContentController.addUserScript(script)
        
        // Add the interceptor message handler
        userContentController.add(self, name: "interceptor")
        
        webConfiguration.userContentController = userContentController
        
        let webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.scrollView.isScrollEnabled = true
        return webView
    }()
    var urlString: String?
    
    public init(urlString: String?) {
        self.urlString = urlString
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        let swipeBack = UISwipeGestureRecognizer(target: self, action: #selector(didSwipe(_:)))
        swipeBack.direction = .right
        self.view.addGestureRecognizer(swipeBack)
        
        view.addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
        ])
        webView.frame = view.bounds
        
        
        
        if let cookies = HTTPCookieStorage.shared.cookies {
            for cookie in cookies {
                print("Cookie: \(cookie.name)=\(cookie.value)")
            }
        }
        
        webView.configuration.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        webView.configuration.mediaTypesRequiringUserActionForPlayback = []
        
        loadRequestWithCookies(completion: { error in
            if let error = error {
                print("Error loading webView: \(error)")
            }
        })
    }
    
    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        additionalSafeAreaInsets = UIEdgeInsets(top: -view.safeAreaInsets.top, left: 0, bottom: -view.safeAreaInsets.bottom, right: 0)
    }
    
    @objc func didSwipe(_ gesture: UISwipeGestureRecognizer) {
        if gesture.direction == .right {
            handleBackButton()
        }
    }
    
    func handleBackButton() {
        if webView.canGoBack {
            webView.goBack()
        }
    }
    
    func loadRequestWithCookies(completion: @escaping (Error?) -> Void) {
        let cookies = HTTPCookieStorage.shared.cookies ?? []
        let cookieStore = webView.configuration.websiteDataStore.httpCookieStore
        
        let dispatchGroup = DispatchGroup()
        
        for cookie in cookies {
            dispatchGroup.enter()
            cookieStore.setCookie(cookie) {
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: DispatchQueue.main) {
            do {
                guard let urlString = self.urlString, let url = URL(string: urlString) else {
                    throw InvalidURLError.invalidURL
                }
                
                let request = URLRequest(url: url)
                self.webView.load(request)
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }
    
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("WebView navigation failed: \(error)")
    }
    
    public func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
        }
        return nil
    }
    
    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        let isCameraActionRequiredScript = "typeof capture === 'function'"
        
        webView.evaluateJavaScript(isCameraActionRequiredScript) { result, error in
            if let error = error {
                print("JavaScript evaluation error: \(error)")
            } else if let isFunction = result as? Bool, isFunction {
                self.handleCameraAction()
            } else {
                print("isCameraActionRequired function not found on this page")
            }
        }
    }
    
    func handleCameraAction() {
        requestCameraPermission { [weak self] granted in
            guard let self = self else { return }
            if granted {
                self.webView.evaluateJavaScript("takePhoto();")
            } else {
                print("Camera permission denied")
            }
        }
    }
    
    func requestCameraPermission(completion: @escaping (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }
    
    private func openURLExternally(_ url: URL) {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    
    private func openWhatsApp() {
        let phoneNumber = "+918073700288"  // Use the appropriate phone number
        let appURL = URL(string: "https://api.whatsapp.com/send?phone=\(phoneNumber)&text=Hello")!
        if UIApplication.shared.canOpenURL(appURL) {
            UIApplication.shared.open(appURL, options: [:], completionHandler: nil)
        } else {
            // Optionally provide feedback to the user that WhatsApp is not installed
            print("WhatsApp is not installed")
        }
    }
    
    private func handleSessionExpired() {
        self.dismiss(animated: true) {
            self.delegate?.sessionDidExpire()
        }
    }
    
    enum InvalidURLError: Error {
        case invalidURL
    }
    
}

extension WebViewController: WKScriptMessageHandler {
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "spense_library" {
            if let messageBody = message.body as? String {
                print("Received message from web: \(messageBody)")
                // Handle the message or perform an action based on the message content
            }
        }
        
        if message.name == "interceptor", let messageBody = message.body as? String {
            print("Received console message: \(messageBody)")
            
            if messageBody.contains("/exit") {
                self.dismiss(animated: true, completion: nil)
            } else if messageBody.contains("generatePin()") {
                // Navigate to PpiPinActivity equivalent in iOS
            } else if messageBody.contains("logout()") {
                // Handle logout
                DispatchQueue.main.async {
                    self.dismiss(animated: true)
                    NotificationCenter.default.post(name: .userDidLogoutNotification, object: nil)
                }
            }
        }
        
    }
}

extension WebViewController {
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.cancel)
            return
        }
        
        // Convert your logic to Swift
        let urlString = url.absoluteString
        
        print(urlString)
        
        if urlString.contains("session-expired") {
            // Close the WebView and navigate back to the SignIn screen
            // Note: Implementation will vary based on how you navigate in your app
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .userDidLogoutNotification, object: nil)
            }
            decisionHandler(.cancel) // Stop loading
            return
        }
        
        if urlString.contains("api.whatsapp.com") {
            openWhatsApp()
            decisionHandler(.cancel) // Stop loading as we are opening WhatsApp externally
            return
        }
        
        
        // Loop through whitelisted URLs to find a match
        for whitelistedUrl in whitelistedUrls {
            if urlString.contains(whitelistedUrl) || urlString.contains(EnvManager.hostName) {
                // If URL matches whitelisted URL or the environment manager's hostname, load it inside the WebView
                decisionHandler(.allow)
                return
            }
        }
        
        // If URL does not match any condition, open it externally
        openURLExternally(url)
        decisionHandler(.cancel)
    }
}
