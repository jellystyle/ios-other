import UIKit
import StaticTables
import SafariServices

class AboutViewController: JSMStaticTableViewController {

	// MARK: View life cycle

	override func viewDidLoad() {
		super.viewDidLoad()

		self.navigationItem.title = "About"

		// About
		let about = JSMStaticSection()
		self.dataSource.addSection(about)

		let version = JSMStaticRow()
		version.text = "Version"
		version.detailText = NSBundle.mainBundle().displayVersion
		version.configurationForCell { row, cell in
			cell.accessoryType = .None
			cell.selectionStyle = .None
		}
		about.addRow(version)

		// Melissa
		let melissa = JSMStaticSection()
		melissa.headerText = "Melissa"
		melissa.footerText = "Copyright © 2015 Daniel Farrelly\n\nRedistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:\n\n* Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.\n\n* Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.\n\nTHIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS \"AS IS\" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE."
		self.dataSource.addSection(melissa)

		let melissaRow = JSMStaticRow(key: "melissa.github")
		melissaRow.text = "GitHub"
		melissaRow.configurationForCell { row, cell in
			cell.accessoryType = .DisclosureIndicator
			cell.selectionStyle = .Default
			cell.textLabel?.textColor = PreferencesManager.tintColor
		}
		melissa.addRow(melissaRow)

		// StaticTables
		let staticTables = JSMStaticSection()
		staticTables.headerText = "StaticTables"
		staticTables.footerText = "Copyright © 2014 Daniel Farrelly\n\nRedistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:\n\n* Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.\n\n* Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.\n\nTHIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS \"AS IS\" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE."
		self.dataSource.addSection(staticTables)

		let staticTablesRow = JSMStaticRow(key: "statictables.github")
		staticTablesRow.text = "GitHub"
		staticTablesRow.configurationForCell { row, cell in
			cell.accessoryType = .DisclosureIndicator
			cell.selectionStyle = .Default
			cell.textLabel?.textColor = PreferencesManager.tintColor
		}
		staticTables.addRow(staticTablesRow)

	}

	// MARK: Table view delegate

	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		if let row = self.dataSource.rowAtIndexPath(indexPath), let key = row.key as? String {

			if key == "melissa.github", let url = NSURL(string: "https://github.com/jellybeansoup/ios-melissa") {
				let viewController = SFSafariViewController(URL: url)
				self.presentViewController(viewController, animated: true, completion: nil)
			}

			else if key == "statictables.github", let url = NSURL(string: "https://github.com/jellybeansoup/ios-statictables") {
				let viewController = SFSafariViewController(URL: url)
				self.presentViewController(viewController, animated: true, completion: nil)
			}

		}
	}

}