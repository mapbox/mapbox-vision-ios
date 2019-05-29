import Foundation
import UIKit

final class ExampleTableViewController: UITableViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        self.clearsSelectionOnViewWillAppear = false
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return listOfExamples.count
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ExampleCell", for: indexPath)
        cell.textLabel?.text = listOfExamples[indexPath.row].name
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let controller = UIStoryboard(name: "Main", bundle: .main)
            .instantiateViewController(withIdentifier: "ExampleContainer") as? ExampleContainerViewController else {
            assertionFailure("Unknown controller type")
            return
        }

        let example = listOfExamples[indexPath.row]
        controller.exampleClass = example.controllerType

        present(controller, animated: true) {
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
}
