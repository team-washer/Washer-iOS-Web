//
//  MyWebView.swift
//  Washer-WebApp
//
//  Created by 서지완 on 5/21/25.
//

import SwiftUI
import WebKit
import UserNotifications

struct MyWebView: UIViewRepresentable {
    let urlToLoad: String = "https://demo.washer-gsm.com/login"
    @Binding var isLoaded: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(isLoaded: $isLoaded)
    }

    func makeUIView(context: Context) -> WKWebView {
        guard let url = URL(string: self.urlToLoad) else {
            return WKWebView()
        }

        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.load(URLRequest(url: url))
        
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    class Coordinator: NSObject, WKNavigationDelegate {
        @Binding var isLoaded: Bool

        init(isLoaded: Binding<Bool>) {
            _isLoaded = isLoaded
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            print("🟡 웹뷰 로딩 시작")
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("🟢 웹뷰 로딩 완료!")
            isLoaded = true
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("🔴 웹뷰 로딩 실패: \(error.localizedDescription)")
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            print("🔴 초기 로딩 실패: \(error.localizedDescription)")
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if let url = navigationAction.request.url,
               navigationAction.targetFrame == nil || !navigationAction.targetFrame!.isMainFrame {
                UIApplication.shared.open(url)
                decisionHandler(.cancel)
                return
            }
            decisionHandler(.allow)
        }
    }
}

struct AppWebView: View {
    @State private var splash = SplashState()
    @State private var webViewStyle = WebViewStyle()
    @State private var webViewLoaded = false
    @State private var hasRequestedNotification = false

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            MyWebView(isLoaded: $webViewLoaded)
                .opacity(webViewStyle.opacity)
                .offset(y: webViewStyle.offset)
                .blur(radius: webViewStyle.blur)
                .ignoresSafeArea(.container, edges: .bottom)
                .navigationBarBackButtonHidden(true)

            if splash.isVisible {
                Color.white
                    .ignoresSafeArea()

                Image("splashImage")
                    .resizable()
                    .frame(width: 120, height: 120)
                    .scaledToFit()
                    .scaleEffect(splash.scale)
                    .opacity(splash.opacity)
            }
        }
        .onChange(of: webViewLoaded) { loaded in
            if loaded {
                startSplashAnimation()
            }
        }
    }

    private func startSplashAnimation() {
        withAnimation(.easeInOut(duration: 0.8)) {
            splash.opacity = 0.1
            splash.scale = 0.8
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            splash.isVisible = false
            withAnimation(.easeOut(duration: 0.8)) {
                webViewStyle.opacity = 1.0
                webViewStyle.offset = 0
                webViewStyle.blur = 0
            }

            if !hasRequestedNotification {
                hasRequestedNotification = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    requestNotificationPermission()
                }
            }
        }
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("🔴 알림 권한 요청 오류: \(error.localizedDescription)")
            } else {
                print("🟢 알림 권한 허용 여부: \(granted)")
            }
        }
    }
}


// MARK: - 상태 구조체
struct SplashState {
    var isVisible = true
    var opacity = 1.0
    var scale: CGFloat = 1.0
}

struct WebViewStyle {
    var opacity = 0.0
    var offset: CGFloat = 20
    var blur: CGFloat = 10
}
