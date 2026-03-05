//
//  MenuItemView.swift
//  Doas
//
//  Created by Admin on 05/03/26.
//

import UIKit
final class MenuItemView: UIControl {

    private let stack = UIStackView()
    private let imageView = UIImageView()
    private let titleLabel = UILabel()

    private var activeColor: UIColor = .systemBlue
    private var inactiveColor: UIColor = .systemGray

    init(title: String, iconName: String, active: Bool = false) {
        super.init(frame: .zero)
        setup()
        configure(title: title, iconName: iconName, active: active)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {

        translatesAutoresizingMaskIntoConstraints = false
        isUserInteractionEnabled = true   // ← ini penting

        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.isUserInteractionEnabled = false   // 🔥 penting

        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = inactiveColor
        imageView.setContentHuggingPriority(.required, for: .vertical)
        imageView.setContentCompressionResistancePriority(.required, for: .vertical)
        imageView.isUserInteractionEnabled = false

        titleLabel.font = UIFont.systemFont(ofSize: 10)
        titleLabel.textColor = inactiveColor
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 1
        titleLabel.isUserInteractionEnabled = false

        addSubview(stack)

        stack.addArrangedSubview(imageView)
        stack.addArrangedSubview(titleLabel)

        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 4),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -4)
        ])

        heightAnchor.constraint(equalToConstant: 64).isActive = true
    }

   

    func configure(title: String, iconName: String, active: Bool) {
        titleLabel.text = title

        if let img = UIImage(named: iconName)?.withRenderingMode(.alwaysTemplate) {
            imageView.image = img
        } else {
            imageView.image = nil
        }

        setActive(active)
    }

    func setActive(_ active: Bool) {
        let color = active ? activeColor : inactiveColor

        titleLabel.font = UIFont.systemFont(ofSize: 10, weight: active ? .bold : .regular)
        titleLabel.textColor = color
        imageView.tintColor = color

        backgroundColor = active ? UIColor.systemBlue.withAlphaComponent(0.1) : .clear
        layer.cornerRadius = 10
    }
}
