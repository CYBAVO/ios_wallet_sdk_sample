//Copyright (c) 2019 Cybavo. All rights reserved.

import UIKit
import CYBAVOWallet
import QuartzCore

class WalletDetailController : UIViewController {
    @IBOutlet weak var balanceTextView: UITextView!
    @IBOutlet weak var walletAddressTextView: UITextView!
    @IBOutlet weak var historyTableView: UITableView!

    @IBOutlet weak var goEosResourceItem: UIBarButtonItem!
    var timeBtController: SSRadioButtonsController?
    var directionBtController: SSRadioButtonsController?
    var statusBtController: SSRadioButtonsController?
    var resultBtController: SSRadioButtonsController?
    var timeBtControllerDelegate: BtControllerDelegate?
    var directionBtControllerDelegate: BtControllerDelegate?
    var statusBtControllerDelegate: BtControllerDelegate?
    var resultBtControllerDelegate: BtControllerDelegate?
    var wallet: Wallet?
    var editingItems: Array<Transaction> = Array()//
    var historyItems: Array<Transaction> = Array()
    var selectingItem: Transaction?
    var refreshControl: UIRefreshControl!
    var loadMoreHint: UILabel?
    var moreFilterImgView: UIImageView?
    var allFilterWidth: Int = 0;
    let NO_MORE_TEXT = "End of history"
    let LOADING_MORE_TEXT = "Loading more..."

    func createMoreFilter(x: Int, y: Int) -> UIImageView{
        let image = UIImage(named: "ic_more_h")
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.frame = CGRect(x: x, y: y, width: 45, height: 30)
        imageView.isUserInteractionEnabled = true

        let singleTap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.showAllFilter(recognizer:)))
        singleTap.numberOfTapsRequired = 1
        imageView.addGestureRecognizer(singleTap)
        return imageView
    }
    @objc func showAllFilter(recognizer: UIGestureRecognizer) {
        moreFilterImgView?.isHidden = true
        directionBtController?.toggleAllBtn(hide: false)
        statusBtController?.toggleAllBtn(hide: false)
        resultBtController?.toggleAllBtn(hide: false)
        scrollView.contentSize = CGSize(width: allFilterWidth, height: 46)
        print("image clicked")
    }
    @IBOutlet weak var scrollView: UIScrollView!
    var isLoading: Bool = false
    var hasMore: Bool = false
    func createFilter(titles: String...){

        timeBtControllerDelegate = BtControllerDelegate(self)
        directionBtControllerDelegate = BtControllerDelegate(self)
        statusBtControllerDelegate = BtControllerDelegate(self)
        resultBtControllerDelegate = BtControllerDelegate(self)

        let padding = 0
        let groupX = 25
        var xOffset = 10
        var arr = Array<UIButton>()
        for i in 0..<titles.count{
            let view = createButton(title: titles[i], x: xOffset, y: padding)
            xOffset = xOffset + padding + Int(view.frame.size.width)
            arr.append(view)
            switch i {
            case 2:
                moreFilterImgView = createMoreFilter(x: xOffset, y: 6)
                scrollView.addSubview(moreFilterImgView!)
                xOffset += groupX
                timeBtController = initRatioButton(buttons: arr[0], arr[1], arr[2], delegate: timeBtControllerDelegate)
                timeBtControllerDelegate?.controller = timeBtController
                arr.removeAll()
                break;
            case 5:
                xOffset += groupX
                directionBtController = initRatioButton(hide: true, buttons: arr[0], arr[1], arr[2], delegate: directionBtControllerDelegate)
                directionBtControllerDelegate?.controller = directionBtController
                arr.removeAll()
                break;
            case 8:
                xOffset += groupX
                statusBtController = initRatioButton(hide: true, buttons: arr[0], arr[1], arr[2], delegate: statusBtControllerDelegate)
                statusBtControllerDelegate?.controller = statusBtController
                arr.removeAll()
                break;
            case 11:
                xOffset += groupX
                resultBtController = initRatioButton(hide: true, buttons: arr[0], arr[1], arr[2], delegate: resultBtControllerDelegate)
                resultBtControllerDelegate?.controller = resultBtController
                arr.removeAll()
                break;
            default: break
            }
            scrollView.addSubview(view)
        }
        allFilterWidth = xOffset
    }
    func createButton(title: String, x: Int, y: Int)-> UIButton{
        let button = UIButton(type: .system) // let preferred over var here
        button.frame = CGRect(x: x, y: y, width: calWidth(byTitle: title), height: 46)
        button.setTitle(title, for: .normal)
        return button
    }
    func createLabel(title: String, x: Int, y: Int)-> UILabel{
        let label = UILabel(frame: CGRect(x: x, y: y, width: calWidth(byTitle: title), height: 40)) // let preferred over var here
        label.text = title
        label.textColor = .white
        label.backgroundColor = UIColor(red: 93.0/255.0, green: 112.0/255.0, blue: 103.0, alpha: 1.0)
        label.layer.masksToBounds = true
        label.layer.cornerRadius = 20
        label.textAlignment = NSTextAlignment.center
//        label.font = amount.font.withSize(14)
        return label
    }
    override func viewDidLoad() {
        guard let w = wallet else {
            self.dismiss(animated: true)
            return
        }
        createFilter(titles: "ALL TIME","TODAY","YESTERDAY","ALL","RECEIVED","SENT","ALL","PENDING","DONE","ALL","SUCCESS","FAILED")
        title = w.name
        goEosResourceItem.isEnabled = w.currency == CurrencyHelper.Coin.EOS.rawValue
        historyTableView.dataSource = self
        historyTableView.delegate = self
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(WalletDetailController.reloadHistory), for: .valueChanged)
        historyTableView.addSubview(refreshControl)

        walletAddressTextView.text = w.address
    }
    func calWidth(byTitle: String) -> Int{
        return byTitle.count * 12
    }
    func createLoadMoreHint(){
        var title = NO_MORE_TEXT
        let label = createLabel(title: title, x: Int(self.view.frame.width / 2) - calWidth(byTitle: title)/2, y: Int(self.view.frame.size.height - 70))
//        button.backgroundColor = UIColor(red: 80.0/255.0, green: 104.0/255.0, blue: 194.0, alpha: 1.0)
//        button.layer.masksToBounds = true
//        button.layer.cornerRadius = 20
//        button.tintColor = UIColor.white
        self.navigationController?.view.addSubview(label)
        self.loadMoreHint = label
        self.loadMoreHint?.alpha = 0
    }
    func initRatioButton(hide: Bool = false, buttons: UIButton..., delegate: SSRadioButtonControllerDelegate?)-> SSRadioButtonsController{
        var btController = SSRadioButtonsController(hide: hide, buttons: buttons[0],buttons[1],buttons[2])
        btController.delegate = delegate
        btController.shouldLetDeSelect = false
        buttons[0].sendActions(for: .touchUpInside)
        return btController
    }
    class BtControllerDelegate:SSRadioButtonControllerDelegate {
        var controller: SSRadioButtonsController?;
        weak var delegate: WalletDetailController?;

        init(_ delegate: WalletDetailController) {
            self.delegate = delegate
        }

        var select :Int = 0
        func didSelectButton(selectedButton: UIButton?) {
            guard controller != nil else{return }
            let index = controller!.selectedButtonIndex()!
            guard index != select else{return }
            select = index
            delegate?.reloadHistory()
        }
    }
    override func viewDidAppear(_ animated: Bool) {
        createLoadMoreHint()
        if(historyItems.count == 0){
            reloadHistory()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.loadMoreHint?.removeFromSuperview()
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
        case "idEosResource":
            let vc = segue.destination as! EosResourceController
            vc.wallet = wallet
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
    func getParameter()->[String:Any]{
        var extras: [String:Any] = [:]
        var idx = timeBtController!.selectedButtonIndex()!

        var gregorian = Calendar(identifier: .gregorian)
        var now = Date()
        let midnight = gregorian.date(bySettingHour: 0, minute: 0, second: 0, of: Date())
        let nowSec = now.timeIntervalSince1970
        let midnightSec = midnight!.timeIntervalSince1970

        switch idx {
        case 0:
            break;
        case 1:
            extras["start_time"] = midnightSec
            extras["end_time"] = now
            break;
        case 2:
            extras["start_time"] = midnightSec - 86400
            extras["end_time"] = midnightSec
            break;
        default: break;
        }
        idx = directionBtController!.selectedButtonIndex()!
        switch idx {
        case 0:
            break;
        case 1:
            extras["direction"] = Direction.IN.rawValue
            break;
        case 2:
            extras["direction"] = Direction.OUT.rawValue
            break;
        default: break;
        }
        idx = statusBtController!.selectedButtonIndex()!
        switch idx {
        case 0:
            break;
        case 1:
            extras["pending"] = true
            break;
        case 2:
            extras["pending"] = false
            break;
        default: break;
        }
        idx = resultBtController!.selectedButtonIndex()!
        switch idx {
        case 0:
            break;
        case 1:
            extras["success"] = true
            break;
        case 2:
            extras["success"] = false
            break;
        default: break;
        }
        return extras
    }

    func changeLoadMoreHint(hide: Bool, title: String = ""){
        if !hide {
            self.loadMoreHint?.text = title
            let width = calWidth(byTitle: title)
            var frm : CGRect = self.loadMoreHint!.frame
            self.loadMoreHint?.frame = CGRect(x: Int(self.view.frame.width / 2) - width/2, y: Int(frm.origin.y), width: width, height: Int(frm.size.height))
        }
        hideViewWithAnimation(view: self.loadMoreHint!,hide: hide)
    }

    func hideViewWithAnimation(view: UIView, hide: Bool){
        UIView.animate(withDuration: 0.2) {
            view.alpha = hide ? 0 : 1
        }
    }
    @objc func doRefreshHistory(loadStart: Int ){
        guard let w = wallet else {
            self.dismiss(animated: true)
            return
        }
        self.isLoading = true
        var extras = getParameter()
        Wallets.shared.getHistory(currency: w.currency, tokenAddress: w.tokenAddress, walletAddress: w.address, start: loadStart, count: 10, filters: extras) { result in
            self.isLoading = false
            switch result {
            case .success(let result):
                self.historyItems.reset(self.editingItems + result.transactions)
                self.editingItems.reset(self.historyItems)
                self.historyTableView.reloadData()
                self.hasMore = self.historyItems.count < result.total
                print("getHistory \(result), \(self.historyItems.count), \(result.total), \(self.hasMore)")
                break
            case .failure(let error):
                print("getHistory \(error)")
                break
            }
            self.changeLoadMoreHint(hide: self.hasMore, title: self.NO_MORE_TEXT)
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
    @objc func loadMoreHistory() {
        guard !self.isLoading else{
            return
        }
        guard self.hasMore else{
            return
        }
        print("loadMoreHistory ")
        self.changeLoadMoreHint(hide: false, title: self.LOADING_MORE_TEXT)
        doRefreshHistory(loadStart: self.historyItems.count)
    }
    @objc func reloadHistory() {
        self.editingItems.removeAll()
        self.hasMore = true
        print("reloadHistory ")
        doRefreshHistory(loadStart:0)
    }
}

extension WalletDetailController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let transaction = historyItems[safe: indexPath.row] {
            selectingItem = transaction
            performSegue(withIdentifier: "idTransactionDetail", sender: nil)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension WalletDetailController : UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return historyItems.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if (historyItems.count-1) == indexPath.row {
            print("scrollToEnd")
            self.loadMoreHistory()
        }

        if let tx = historyItems[safe: indexPath.row] {
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
            cell.directionLabel.sizeToFit()
            cell.failImage.isHidden = tx.success
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
extension Array{
    mutating func reset(_ new: Array){
        self.removeAll()
        self += new
    }
}
