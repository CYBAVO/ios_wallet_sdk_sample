import UIKit
import CYBAVOWallet

extension Wallet where Self: Hashable {
    
}

class WalletsViewController: UIViewController {
    @IBOutlet weak var walletsTableView: UITableView!
    var refreshControl: UIRefreshControl!
    
    var wallets = [Wallet]()
    let debouncer = Debouncer(seconds: 0.5)
    var pendingBalanceRequest = [Int64:(Wallet, UILabel)]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        walletsTableView.register(
                UITableViewCell.self, forCellReuseIdentifier: "Cell")
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(WalletsViewController.refreshWallets), for: .valueChanged)
        walletsTableView.addSubview(refreshControl)
        walletsTableView.dataSource = self
        walletsTableView.delegate = self
        Wallets.shared.getWallets() { result in
            switch result {
            case .success(let result):
                self.wallets = result.wallets
                self.walletsTableView.reloadData()
                break
            case .failure(_):
                break
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        refreshWallets()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "idWalletDetail" else {
            return
        }
        switch segue.identifier {
        case "idWalletDetail":
            let obj = sender as AnyObject
            if let wallet = obj as? Wallet, let vc = segue.destination as? WalletDetailController {
                vc.wallet = wallet
            }
        default:
            break
        }
    }
    
    @objc func refreshWallets() {
        Wallets.shared.getWallets() { result in
            switch result {
            case .success(let result):
                self.wallets = result.wallets
                self.walletsTableView.reloadData()
                break
            case .failure(_):
                break
            }
            self.refreshControl.endRefreshing()
        }
    }
}

extension WalletsViewController : UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return wallets.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "idWalletsView", for: indexPath) as! WalletItemCell
        cell.accessoryType = .disclosureIndicator
        
        if let wallet = wallets[safe: indexPath.row] {
            cell.walletNameLabel.text = wallet.name
            cell.currencyNameLabel.text = wallet.currencySymbol
            cell.currencyImageView.image = UIImage(named: wallet.currencySymbol.replacingOccurrences(of: "-", with: "_").lowercased())
        }

        return cell
    }
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? WalletItemCell, let wallet = wallets[safe: indexPath.row] {
            pendingBalanceRequest[wallet.walletId] = (wallet, cell.balanceLabel)
            debouncer.debounce() {
                var balanceRequest: [Int64:Wallet] = [:]
                var callbackData = self.pendingBalanceRequest
                
                DispatchQueue.main.sync {
                    for (k, (w, _)) in self.pendingBalanceRequest {
                        balanceRequest[k] = w
                    }
                    self.pendingBalanceRequest = [:]
                }
                Wallets.shared.getBalances(addresses: balanceRequest) { result in
                    switch result {
                    case .success(let result):
                        for (walletId, balance) in result.balance {
                            if let (wallet, labelView) = callbackData[walletId]{
                                DispatchQueue.main.async {
                                    if wallet.tokenAddress.count > 0 {
                                        labelView.text = "\(balance.tokenBalance) \(wallet.currencySymbol)"
                                    } else {
                                        labelView.text = "\(balance.balance) \(wallet.currencySymbol)"
                                    }
                                }
                            }
                        }
                        break
                    case .failure(let error):
                        print("getBalance \(error)")
                        break
                    }
                }
            }
        }
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
}

extension WalletsViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let wallet = wallets[safe: indexPath.row] {
            performSegue(withIdentifier: "idWalletDetail", sender: wallet)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
