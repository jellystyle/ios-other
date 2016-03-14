import UIKit

// MARK: User guide view controller

class UserGuideViewController: UITableViewController {

	private let _dataSource: _UserGuideDataSource

	init( fileAtURL fileURL: NSURL ) {
		_dataSource = _UserGuideDataSource(fileAtURL: fileURL)

		super.init(style: .Grouped)
	}

	required init?(coder aDecoder: NSCoder) {
	    fatalError("init(coder:) has not been implemented")
	}

	// MARK: Appearance

	//! Tint color used for indicating links.
	var tintColor: UIColor! = UINavigationBar.appearance().tintColor

	//! Background color for article pages.
	var articleBackgroundColor: UIColor! = UIColor.whiteColor()

	// MARK: View life cycle

	override func viewDidLoad() {
		super.viewDidLoad()

		self.navigationItem.title = "User Guide"

		self.tableView.dataSource = _dataSource
	}

	// MARK: Table view delegate

	override func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
		return 44
	}

	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		guard let article = self._dataSource._article(indexPath) else {
			return
		}

		let viewController = _UserGuideArticleViewController(article: article)
		viewController.tintColor = self.tintColor
		viewController.backgroundColor = self.articleBackgroundColor
		self.navigationController?.pushViewController(viewController, animated: true)
	}

	override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
		if cell.accessoryType != .None {
			cell.textLabel?.textColor = self.tintColor
		}
	}

}

// MARK: - User guide article view controller

private class _UserGuideArticleViewController: UIViewController {

	let _article: Dictionary<String,AnyObject>

	init( article: Dictionary<String,AnyObject> ) {
		_article = article

		super.init(nibName: nil, bundle: nil)
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	// MARK: Appearance

	var tintColor: UIColor! = UINavigationBar.appearance().tintColor

	var backgroundColor: UIColor! = UIColor.whiteColor()

	// MARK: View life cycle

	override func viewDidLoad() {
		super.viewDidLoad()

		self.view.backgroundColor = self.backgroundColor

		let scrollView = UIScrollView()
		scrollView.preservesSuperviewLayoutMargins = true
		scrollView.translatesAutoresizingMaskIntoConstraints = false
		self.view.addSubview(scrollView)

		let contentView = UIView()
		contentView.preservesSuperviewLayoutMargins = true
		contentView.translatesAutoresizingMaskIntoConstraints = false
		scrollView.addSubview(contentView)

		let titleLabel = UILabel()
		titleLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleTitle2)
		titleLabel.textColor = UIColor.darkGrayColor()
		titleLabel.translatesAutoresizingMaskIntoConstraints = false
		titleLabel.numberOfLines = 0
		contentView.addSubview(titleLabel)

		let bodyLabel = UILabel()
		bodyLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
		bodyLabel.textColor = UIColor.darkGrayColor()
		bodyLabel.translatesAutoresizingMaskIntoConstraints = false
		bodyLabel.numberOfLines = 0
		contentView.addSubview(bodyLabel)

		let views = [ "scroll": scrollView, "content": contentView, "title": titleLabel, "body": bodyLabel ]

		self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-(0)-[scroll]-(0)-|", options: [], metrics: nil, views: views))
		self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-(0)-[scroll]-(0)-|", options: [], metrics: nil, views: views))
		scrollView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-(0)-[content(==scroll)]-(0)-|", options: [], metrics: nil, views: views))
		scrollView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-(0)-[content]-(0)-|", options: [], metrics: nil, views: views))
		contentView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-[title]-|", options: [], metrics: nil, views: views))
		contentView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-[body]-|", options: [], metrics: nil, views: views))
		contentView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-(20)-[title]-(30)-[body]-(20)-|", options: [], metrics: nil, views: views))

		if let title = (self._article["title"] as? String) {
			titleLabel.text = title
		}

		if let body = (self._article["body"] as? String) {
			bodyLabel.text = body

			var mutableBody = body

			while let range = mutableBody.rangeOfString("\n") {
				mutableBody.replaceRange(range, with: "<br />")
			}

			let fontFamily = bodyLabel.font.fontName
			let fontSize = Int(bodyLabel.font.pointSize)
			var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0
			bodyLabel.textColor.getRed(&red, green: &green, blue: &blue, alpha: nil)
			mutableBody = "<div style=\"font-family: '\(fontFamily)'; font-size: \(fontSize)px; color: rgb(\(Int(red*255)),\(Int(green*255)),\(Int(blue*255)))\">\(mutableBody)</div>"

			if let data = mutableBody.dataUsingEncoding(NSUnicodeStringEncoding, allowLossyConversion: true) {
				do {
					bodyLabel.attributedText = try NSAttributedString(data: data, options: [NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType], documentAttributes: nil)
				}
				catch {}
			}
		}
	}

}

// MARK: - User guide data source

private class _UserGuideDataSource: NSObject, UITableViewDataSource {

	private let _fileURL: NSURL

	private var _contents: Array<Dictionary<String,AnyObject>> = []
	
	init( fileAtURL fileURL: NSURL ) {
		_fileURL = fileURL

		super.init()

		self._loadFromFile()
	}

	// MARK: Loading and retrieving content

	private func _loadFromFile() {
		do {

			guard let data = NSData(contentsOfURL: _fileURL) else {
				return
			}
			
			let json = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(rawValue: 0))

			guard let array = json as? Array<Dictionary<String,AnyObject>> else {
				return
			}

			_contents = array

		}
		catch {
			return
		}
	}

	private func _section(index: Int) -> Dictionary<String,AnyObject>? {
		if index < 0 || index >= self._contents.count {
			return nil
		}

		return self._contents[index]
	}
	
	private func _articlesInSection(index: Int) -> [Dictionary<String,AnyObject>] {
		guard let sect = self._section(index), let articles = sect["articles"] as? Array<Dictionary<String,AnyObject>> else {
			return []
		}

		guard let build = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleVersion") as? String else {
			return articles
		}

		let buildInt = Int(build)

		return articles.filter({ article in
			let buildMin = article["build_min"] as? Int ?? 0
			let buildMax = article["build_max"] as? Int ?? 999999
			return buildInt >= buildMin && buildInt <= buildMax
		})
	}
	
	private func _article(indexPath: NSIndexPath) -> Dictionary<String,AnyObject>? {
		let articles = self._articlesInSection(indexPath.section)

		if indexPath.row < 0 || indexPath.row >= articles.count {
			return nil
		}

		return articles[indexPath.row]
	}

	// MARK: Table view data source

	@objc
	private func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return self._contents.count
	}

	@objc
	private func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "_UserGuideCell")

		return self._articlesInSection(section).count
	}

	@objc
	private func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		guard let sect = self._section(section), let title = sect["title"] as? String else {
			return nil
		}

		return title
	}

	@objc
	private func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
		guard let sect = self._section(section), let detail = sect["detail"] as? String else {
			return nil
		}

		return detail
	}

	@objc
	private func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier("_UserGuideCell", forIndexPath: indexPath)

		if let article = self._article(indexPath) {

			cell.accessoryType = .DisclosureIndicator
			cell.textLabel?.font = UIFont.preferredFontForTextStyle(UIFontTextStyleCallout)
			cell.textLabel?.numberOfLines = 0
			cell.textLabel?.text = (article["title"] as? String)

		}

		return cell
	}

}
