//Copyright (c) 2019 Cybavo. All rights reserved.

import UIKit
import CYBAVOWallet
import GoogleSignIn
import Foundation

class SettingsController : UITableViewController {
    @IBOutlet var settingTableView: UITableView!
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var versionCell: UITableViewCell!
    @IBOutlet weak var accounCell: UITableViewCell!
    
    override func viewDidLoad() {
        settingTableView.delegate = self
        versionCell.selectionStyle = .none
        accounCell.selectionStyle = .none
        Auth.shared.getUserState { result in
            switch result {
            case .success(let getUserStateResult):
                self.nameLabel.text = getUserStateResult.userState.realName
                self.emailLabel.text = getUserStateResult.userState.email
                break
            case .failure(let error):
                //get from local (google only)
                print("getUserStateResult failed \(error)")
                
                guard let userData = UserDefaults.standard.value(forKey: "googlesignin_user") as? Data else {
                    NSLog("no googlesignin_user")
                    return
                }
                
                guard let user = try! NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(userData) else {
                    NSLog("unable to unarchive")
                    return
                }
                
                if let user = user as? GIDGoogleUser {
                    self.nameLabel.text = user.profile?.name
                    self.emailLabel.text = user.profile?.email

                    guard let imageUrl = user.profile?.imageURL(withDimension: 50) else { return }
                    self.getData(from: imageUrl) { data, response, error in
                        guard let data = data, error == nil else { return }
                        DispatchQueue.main.async() {
                            self.avatarImageView.image = UIImage(data: data)
                        }
                    }
                }
                break
            }
        }
    }
    
    @IBAction func onSignOut(_ sender: Any) {
        let alert = UIAlertController(title: "Sign out", message: "Are you sure you want to sign out?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: {action in
            GIDSignIn.sharedInstance.signOut()
            Auth.shared.signOut()
            self.dismiss(animated: true)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: {action in
           
        }))
        self.present(alert, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        settingTableView.deselectRow(at: indexPath, animated: true)
    }
    
    func getData(from url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> ()) {
        URLSession.shared.dataTask(with: url, completionHandler: completion).resume()
    }
}
