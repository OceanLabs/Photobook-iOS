//
//  Modified MIT License
//
//  Copyright (c) 2010-2018 Kite Tech Ltd. https://www.kite.ly
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The software MAY ONLY be used with the Kite Tech Ltd platform and MAY NOT be modified
//  to be used with any competitor platforms. This means the software MAY NOT be modified
//  to place orders with any competitors to Kite Tech Ltd, all orders MUST go through the
//  Kite Tech Ltd platform servers.
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Stripe

class PaymentMethodsViewController: UIViewController {
    
    private struct Constants {
        static let creditCardSegueName = "CreditCardSegue"
    }
    
    var order: Order!
    
    var paymentManager: PaymentAuthorizationManager!
    
    @IBOutlet weak var tableView: UITableView!

    private var selectedPaymentMethod: PaymentMethod? {
        get { return order.paymentMethod }
        set { order.paymentMethod = newValue }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        Analytics.shared.trackScreenViewed(.paymentMethods)
        
        title = NSLocalizedString("PaymentMethods/Title", value: "Payment Methods", comment: "Title for the payment methods screen")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
    
    @IBAction func tappedAddPaymentMethod(_ sender: Any) {
        guard let paymentContext = paymentManager.stripePaymentContext else { return }
        paymentContext.hostViewController = self
        paymentContext.pushPaymentMethodsViewController()
    }
    
    func reloadPaymentMethods() {
        tableView.reloadData()
    }
}

extension PaymentMethodsViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return paymentManager.availablePaymentMethods.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch paymentManager.availablePaymentMethods[indexPath.item] {
        case .applePay:
            let cell = tableView.dequeueReusableCell(withIdentifier: PaymentMethodTableViewCell.reuseIdentifier, for: indexPath) as! PaymentMethodTableViewCell
            let method = "ApplePay"
            cell.method = method
            cell.icon = UIImage(namedInPhotobookBundle:"apple-pay-method")
            
            let selected = selectedPaymentMethod != nil && selectedPaymentMethod == .applePay
            cell.ticked = selected
            
            cell.separator.isHidden = true
            cell.accessibilityIdentifier = "applePayCell"
            cell.accessibilityLabel = (selected ? CommonLocalizedStrings.accessibilityListItemSelected : "") + method
            cell.accessibilityHint = selected ? nil : CommonLocalizedStrings.accessibilityDoubleTapToSelectListItem
            return cell
        case .payPal:
            let cell = tableView.dequeueReusableCell(withIdentifier: PaymentMethodTableViewCell.reuseIdentifier, for: indexPath) as! PaymentMethodTableViewCell
            let method = "PayPal"
            cell.method = method
            
            cell.icon = UIImage(namedInPhotobookBundle:"paypal-method")
            
            let selected = selectedPaymentMethod != nil && selectedPaymentMethod == .payPal
            cell.ticked = selected
            
            cell.separator.isHidden = paymentManager.stripePaymentContext?.selectedPaymentMethod != nil
            cell.accessibilityIdentifier = "payPalCell"
            cell.accessibilityLabel = (selected ? CommonLocalizedStrings.accessibilityListItemSelected : "") + method
            cell.accessibilityHint = selected ? nil : CommonLocalizedStrings.accessibilityDoubleTapToSelectListItem
            return cell
        case .creditCard where indexPath.item != paymentManager.availablePaymentMethods.count - 1: // Saved card
            let selectedPaymentMethod = paymentManager.stripePaymentContext?.selectedPaymentMethod
            
            let cell = tableView.dequeueReusableCell(withIdentifier: PaymentMethodTableViewCell.reuseIdentifier, for: indexPath) as! PaymentMethodTableViewCell
            cell.method = selectedPaymentMethod?.label
            cell.icon = selectedPaymentMethod?.image
            
            let selected = order.paymentMethod == .creditCard
            cell.ticked = selected
            
            cell.separator.isHidden = false
            cell.accessibilityIdentifier = "creditCardCell"
            cell.accessibilityLabel = (selected ? CommonLocalizedStrings.accessibilityListItemSelected : "") + (selectedPaymentMethod?.label ?? "")
            cell.accessibilityHint = selected ? nil : CommonLocalizedStrings.accessibilityDoubleTapToSelectListItem
            return cell
        default:
            return tableView.dequeueReusableCell(withIdentifier: "AddPaymentMethodCell", for: indexPath)
        }
    }
}

extension PaymentMethodsViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 0 ? 44 : 1
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? NSLocalizedString("PaymentMethods/Header", value: "Your Methods", comment: "Payment method selection screen header") : nil
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let supportsApplePay = PaymentAuthorizationManager.isApplePayAvailable ? 1 : 0
        
        switch indexPath.item {
        case -1 + supportsApplePay: // Apple Pay
            selectedPaymentMethod = .applePay
        case 0 + supportsApplePay: // PayPal
            selectedPaymentMethod = .payPal
        case paymentManager.availablePaymentMethods.count - 1: // Saved card
            tappedAddPaymentMethod(self)
        default: // Add Payment Method
            selectedPaymentMethod = .creditCard
        }
        
        tableView.reloadData()
    }
}
