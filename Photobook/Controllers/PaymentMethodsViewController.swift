//
//  PaymentMethodsViewController.swift
//  Shopify
//
//  Created by Jaime Landazuri on 12/09/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import Stripe

protocol PaymentMethodsDelegate: class {
    func didTapToDismissPayments()
}

class PaymentMethodsViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!

    weak var delegate: PaymentMethodsDelegate!

    fileprivate var selectedPaymentMethod: PaymentMethod? {
        get {
            return ProductManager.shared.paymentMethod
        }
        set {
            ProductManager.shared.paymentMethod = newValue
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("PaymentMethodsTitle", value: "PAYMENT METHODS", comment: "Title for the payment methods screen")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        if segue.identifier == "CreditCardSegue", let destination = segue.destination as? CreditCardTableViewController {
//            destination.delegate = self
//        }
    }

    @IBAction func tappedCloseButton(_ sender: UIBarButtonItem) {
        delegate?.didTapToDismissPayments()
    }
}

extension PaymentMethodsViewController: UITableViewDataSource {

    fileprivate enum Section: Int {
        case card, thirdParty
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let section = Section(rawValue: section) else { return 0 }

        // Add card
        if section == Section.card {
            return Card.currentCard != nil ? 2 : 1
        }

        // Third party payments
        var numberOfPayments = 1 // PayPal
        if Stripe.deviceSupportsApplePay() { numberOfPayments += 1 }
        return numberOfPayments
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: PaymentMethodTableViewCell.reuseIdentifier, for: indexPath) as! PaymentMethodTableViewCell

        switch Section(rawValue: indexPath.section)! {
        case Section.card:
            if indexPath.row == 0, let card = Card.currentCard {
                cell.method = card.isAmex ? "•••• •••••• •\(card.numberMasked)" : "•••• •••• •••• \(card.numberMasked)"
                cell.icon = card.cardIcon
                cell.separator.alpha = 1.0
                cell.ticked = selectedPaymentMethod == .creditCard
            } else {
                cell.method = "Add Credit / Debit Card"
                cell.icon = UIImage(named:"add-payment")
                cell.separator.alpha = 0.0
                cell.ticked = false
            }
        case Section.thirdParty:
            if indexPath.row == 0, Stripe.deviceSupportsApplePay() {
                cell.method = "ApplePay"
                cell.icon = UIImage(named:"apple-pay-method")
                cell.ticked = selectedPaymentMethod == .applePay
            } else {
                cell.method = "PayPal"
                cell.icon = UIImage(named:"paypal-method")
                cell.ticked = selectedPaymentMethod == .payPal
            }

            cell.separator.alpha = indexPath.row == tableView.numberOfRows(inSection: Section.thirdParty.rawValue) - 1 ? 0.0 : 1.0
        }

        return cell
    }
}

extension PaymentMethodsViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == Section.card.rawValue ? 0.0 : 16.0
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch Section(rawValue: indexPath.section)! {
        case Section.card:
            if indexPath.row == 0, Card.currentCard != nil {
               selectedPaymentMethod = .creditCard
            } else {
                performSegue(withIdentifier: "CreditCardSegue", sender: nil)
                return
            }
        case Section.thirdParty:
            if indexPath.row == 0, Stripe.deviceSupportsApplePay() {
                selectedPaymentMethod = .applePay
            } else {
                selectedPaymentMethod = .payPal
            }
        }

        tableView.reloadData()
        ProductManager.shared.paymentMethod = selectedPaymentMethod
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return indexPath.row == 0 && Card.currentCard != nil
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        Card.currentCard = nil
        tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
    }
}
//
//extension PaymentMethodsViewController: CreditCardTableViewControllerDelegate {
//
//    func didAddCreditCard(on viewController: CreditCardTableViewController) {
//        delegate?.didTapToDismissPayments()
//    }
//}
//
//
//class PaymentMethodTableViewCell: UITableViewCell {
//
//    static let reuseIdentifier = NSStringFromClass(PaymentMethodTableViewCell.self).components(separatedBy: ".").last!
//
//    @IBOutlet private weak var tickImageView: UIImageView! {
//        didSet {
//            tickImageView.tintColor = Theme.colorForKey("tick")
//        }
//    }
//    @IBOutlet private weak var methodLabel: UILabel!
//    @IBOutlet private weak var methodIcon: UIImageView!
//    @IBOutlet weak var separator: UIView!
//
//    var method: String? {
//        didSet { methodLabel.text = method }
//    }
//
//    var icon: UIImage? {
//        didSet { methodIcon.image = icon }
//    }
//
//    var ticked: Bool = false {
//        didSet { tickImageView.alpha = ticked ? 1.0 : 0.0 }
//    }
//}


