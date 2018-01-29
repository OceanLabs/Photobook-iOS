//
//  PaymentViewController.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 29/01/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

class PaymentViewController: UIViewController {

    
    @IBAction func payTapped(_ sender: UIButton) {
        navigationController?.pushViewController(storyboard!.instantiateViewController(withIdentifier: "ReceiptTableViewController"), animated: true)
    }
    
}
