import UIKit

final class SummarySubditCollectionViewCell: UICollectionViewCell {

    let nameLabel = UILabel()
    let diajukanLabel = UILabel()
    let terserapLabel = UILabel()
    let persenLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = UIColor.systemGray6
        layer.cornerRadius = 12

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false

        nameLabel.font = .boldSystemFont(ofSize: 14)
        diajukanLabel.font = .systemFont(ofSize: 12)
        terserapLabel.font = .systemFont(ofSize: 12)
        persenLabel.font = .systemFont(ofSize: 12)

        stack.addArrangedSubview(nameLabel)
        stack.addArrangedSubview(diajukanLabel)
        stack.addArrangedSubview(terserapLabel)
        stack.addArrangedSubview(persenLabel)

        contentView.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

 
}

