//
//  SceneDelegate.swift
//  MaterialPageControlExample
//
//  Created by Alonso on 12/1/19.
//  Copyright © 2019 Alonso. All rights reserved.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        let window = UIWindow(windowScene: windowScene)
        let navigationController = UINavigationController(rootViewController: ViewController())
        window.rootViewController = navigationController
        self.window = window
        self.window?.makeKeyAndVisible()
    }

}

