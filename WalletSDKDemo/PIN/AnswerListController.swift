//Copyright (c) 2019 Cybavo. All rights reserved.

import UIKit

class AnswerListController : UITableViewController {  
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return questions.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LabelCell", for: indexPath)
        
        cell.textLabel?.text = questions[indexPath.row]
        
        return cell
    }
    
    @IBAction func onBack(sugue: UIStoryboardSegue) {
        
    }
}
