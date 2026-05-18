//
//  SplashViewController.swift
//  Cafe
//
//  Created by Антон Абалуев on 05.02.2026.
//

import UIKit

final class SplashViewController: UIViewController {
    private let logoImageView = UIImageView(image: UIImage(named: "zaryadkaLogo"))
    private let indicator = UIActivityIndicatorView(style: .large)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        logoImageView.contentMode = .scaleAspectFit
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(logoImageView)

        indicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(indicator)

        NSLayoutConstraint.activate([
            logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -70),
            logoImageView.widthAnchor.constraint(equalToConstant: 120),
            logoImageView.heightAnchor.constraint(equalTo: logoImageView.widthAnchor),

            indicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            indicator.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 28)
        ])
        indicator.startAnimating()
    }
}
