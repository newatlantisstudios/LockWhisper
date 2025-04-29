import UIKit
import StoreKit

class TipJarViewController: UIViewController, SKProductsRequestDelegate, SKPaymentTransactionObserver {

    // Tip product identifiers in the desired order.
    private let tipProductIDs: [String] = [
        "com.newatlantisstudios.lockwhisper.tip1",
        "com.newatlantisstudios.lockwhisper.tip3",
        "com.newatlantisstudios.lockwhisper.tip5"
    ]
    // The set required for the products request.
    private var productIdentifiers: Set<String> {
        return Set(tipProductIDs)
    }
    
    private var products: [SKProduct] = []
    private var productRequest: SKProductsRequest?
    
    // We'll store the buttons so we can update them once the products load.
    private var tipButtons: [String: UIButton] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Tip Jar"
        setupUI()
        fetchProducts()
        
        // Register self as a transaction observer.
        SKPaymentQueue.default().add(self)
    }
    
    deinit {
        SKPaymentQueue.default().remove(self)
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        // Add a description label at the top.
        let descriptionLabel = UILabel()
        descriptionLabel.text = "If you enjoy using LockWhisper, consider leaving a tip! Your support helps keep the app updated and free for everyone. Thank you!"
        descriptionLabel.font = UIFont.systemFont(ofSize: 17)
        descriptionLabel.textColor = .label
        descriptionLabel.numberOfLines = 0
        descriptionLabel.textAlignment = .center
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(descriptionLabel)
        
        // Create a vertical stack view to hold the tip buttons.
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = 20
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(stackView)
        
        // For each product identifier (in the desired order), create a styled button.
        for productID in tipProductIDs {
            let button = createTipButton(for: productID)
            tipButtons[productID] = button
            stackView.addArrangedSubview(button)
        }
        
        NSLayoutConstraint.activate([
            descriptionLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            descriptionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            descriptionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            
            stackView.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 32),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }
    
    private func createTipButton(for productID: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle("Loading...", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 10
        button.clipsToBounds = true
        button.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        // Store the product identifier in the button's accessibilityIdentifier.
        button.accessibilityIdentifier = productID
        button.addTarget(self, action: #selector(tipButtonTapped(_:)), for: .touchUpInside)
        // Initially disable until product info is available.
        button.isEnabled = false
        return button
    }
    
    // MARK: - In-App Purchase (IAP)
    
    private func fetchProducts() {
        productRequest?.cancel()
        productRequest = SKProductsRequest(productIdentifiers: productIdentifiers)
        productRequest?.delegate = self
        productRequest?.start()
    }
    
    // Called when products are returned from the App Store.
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        products = response.products
        
        // Update buttons with the product price.
        DispatchQueue.main.async {
            for product in self.products {
                let priceString = self.priceString(for: product)
                if let button = self.tipButtons[product.productIdentifier] {
                    button.setTitle(priceString, for: .normal)
                    button.isEnabled = true
                }
            }
        }
        
        // Log any invalid product IDs.
        for invalidId in response.invalidProductIdentifiers {
            print("Invalid product identifier: \(invalidId)")
        }
    }
    
    private func priceString(for product: SKProduct) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = product.priceLocale
        return formatter.string(from: product.price) ?? "$\(product.price)"
    }
    
    @objc private func tipButtonTapped(_ sender: UIButton) {
        guard let productID = sender.accessibilityIdentifier,
              let product = products.first(where: { $0.productIdentifier == productID }) else {
            return
        }
        
        // Start the purchase process.
        if SKPaymentQueue.canMakePayments() {
            let payment = SKPayment(product: product)
            SKPaymentQueue.default().add(payment)
        } else {
            showAlert(title: "Purchases Disabled", message: "In-app purchases are disabled on this device.")
        }
    }
    
    // MARK: - SKPaymentTransactionObserver
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased:
                // Purchase successful.
                SKPaymentQueue.default().finishTransaction(transaction)
                showAlert(title: "Thank You!", message: "Your tip has been received.")
            case .failed:
                // Handle failures.
                if let error = transaction.error as NSError? {
                    if error.code != SKError.paymentCancelled.rawValue {
                        showAlert(title: "Purchase Error", message: error.localizedDescription)
                    }
                }
                SKPaymentQueue.default().finishTransaction(transaction)
            case .restored:
                SKPaymentQueue.default().finishTransaction(transaction)
            default:
                break
            }
        }
    }
    
    // MARK: - Helper
    
    private func showAlert(title: String, message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title,
                                          message: message,
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
        }
    }
}
