//Copyright (c) 2019 Cybavo. All rights reserved.

import UIKit
import CYBAVOWallet
import QuartzCore

class WalletDetailController : UIViewController {
    @IBOutlet weak var balanceTextView: UITextView!
    @IBOutlet weak var walletAddressTextView: UITextView!
    @IBOutlet weak var historyTableView: UITableView!
    
    var wallet: Wallet?
    var historyItems: Array<Transaction>?
    var selectingItem: Transaction?
    var refreshControl: UIRefreshControl!

    override func viewDidLoad() {
        guard let w = wallet else {
            self.dismiss(animated: true)
            return
        }
        
        title = w.name
        
        historyTableView.dataSource = self
        historyTableView.delegate = self
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(WalletDetailController.refreshHistory), for: .valueChanged)
        historyTableView.addSubview(refreshControl)
        
        walletAddressTextView.text = w.address
    }
    
    override func viewDidAppear(_ animated: Bool) {
        refreshHistory()
    }
    
    @IBAction func onWithdrawClick(_ sender: Any) {
        performSegue(withIdentifier: "idWithdraw", sender: nil)
    }
    
    @IBAction func onDepositClick(_ sender: Any) {
        performSegue(withIdentifier: "idDeposit", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "idWithdraw":
            let vc = segue.destination as! WithdrawController
            vc.wallet = wallet
            break;
        case "idDeposit":
            let vc = segue.destination as! DepositController
            vc.wallet = wallet
            break;
        case "idTransactionDetail":
            if let vc = segue.destination as? TransactionDetailController, let transaction = selectingItem {
                vc.wallet = wallet
                vc.transaction = transaction
                selectingItem = nil
            }
            break;
        default:
            break;
        }
    }
    @IBAction func onEditWalletName(_ sender: Any) {
        guard let w = wallet else {
            print("invalid wallet")
            self.dismiss(animated: true)
            return
        }
        
        let alertController: UIAlertController = UIAlertController(title: "Rename wallet", message: nil, preferredStyle: .alert)
        
        //cancel button
        let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
            //cancel code
        }
        alertController.addAction(cancelAction)
        
        //Create an optional action
        let nextAction: UIAlertAction = UIAlertAction(title: "Confirm", style: .default) { action -> Void in
            if let text = alertController.textFields?.first?.text {
                Wallets.shared.renameWallet(walletId: w.walletId, name: text) {result in
                    switch result {
                    case .success(let result):
                        print("renameWallet \(result)")
                        break
                    case .failure(let error):
                        print("renameWallet \(error)")
                        break
                    }
                }
            }
        }
        alertController.addAction(nextAction)
        
        //Add text field
        alertController.addTextField { (textField) -> Void in
            textField.setBottomBorder()
        }
        //Present the AlertController
        present(alertController, animated: true, completion: nil)
    }
    @objc func refreshHistory() {
        guard let w = wallet else {
            self.dismiss(animated: true)
            return
        }
        Wallets.shared.getWallet(walletId: w.walletId) { result in 
            switch result {
            case .success(let result):
                print("getWallet \(result)")
                break
            case .failure(let error):
                print("getWallet \(error)")
                break
            }
        }
        Wallets.shared.getHistory(currency: w.currency, tokenAddress: w.tokenAddress, walletAddress: w.address, start: 0, count: 20) { result in
            switch result {
            case .success(let result):
                self.historyItems = result.transactions
                self.historyTableView.reloadData()
                print("getHistory \(result)")
                break
            case .failure(let error):
                print("getHistory \(error)")
                break
            }
            self.refreshControl.endRefreshing()
        }
        Wallets.shared.getBalances(addresses: [w.walletId:w]) { result in
            switch result {
            case .success(let result):
                print("getBalance \(result)")
                if w.tokenAddress.count > 0 {
                    self.balanceTextView.text = "\(result.balance[w.walletId]?.tokenBalance ?? "") \(w.currencySymbol)"
                } else {
                    self.balanceTextView.text = "\(result.balance[w.walletId]?.balance ?? "") \(w.currencySymbol)"
                }
                break
            case .failure(let error):
                print("getBalance \(error)")
                break
            }
        }
    }
}

extension WalletDetailController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let transaction = historyItems?[safe: indexPath.row] {
            selectingItem = transaction
            performSegue(withIdentifier: "idTransactionDetail", sender: nil)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension WalletDetailController : UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return historyItems?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let tx = historyItems?[safe: indexPath.row] {
            let cell = tableView.dequeueReusableCell(withIdentifier: "idTransactionItem", for: indexPath) as! TransactionItemCell
            if tx.direction == .IN {
                cell.directionLabel.text = "Deposit"
                cell.directionLabel.backgroundColor = UIColor(red: 153.0/255.0, green: 204.0/255.0, blue: 0.0, alpha: 1.0)
            } else{
                cell.directionLabel.text = "Withdraw"
                cell.directionLabel.backgroundColor = UIColor(red: 1.0, green: 187.0/255.0, blue: 51.0/255.0, alpha: 1.0)
            }
            cell.directionLabel.layer.masksToBounds = true
            cell.directionLabel.layer.cornerRadius = 8

            cell.amountLabel.text = tx.amount
            cell.addressLabel.text = tx.txid
            cell.contentView.alpha = tx.pending ? 0.5 : 1.0
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy/MM/dd"
            cell.timestampLabel.text = dateFormatter.string(from: Date(timeIntervalSince1970: Double(tx.timestamp)))
            
            return cell
        }
        return UITableViewCell()
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
}

