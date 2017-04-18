import UIKit
import StaticTables
import SafariServices
import AVFoundation

private class PlayerView: UIView {

	override class var layerClass : AnyClass {
		return AVPlayerLayer.self
	}

	override var layer: AVPlayerLayer {
		get {
			return (super.layer as! AVPlayerLayer)
		}
	}

	var player: AVPlayer? {
		get {
			return self.layer.player
		}
		set(player) {
			self.layer.player = player
			self.layer.backgroundColor = UIColor.clear.cgColor
		}
	}

}

class AboutViewController: JSMStaticTableViewController {

	var player: AVPlayer? = nil

	// MARK: View life cycle

	override func viewDidLoad() {
		super.viewDidLoad()

		self.navigationItem.title = "About"

		// Illustration
		// We have to fetch an alternate version for small screens.
		let screen = UIScreen.main
		let allowedWidth = screen.nativeBounds.size.width <= 640 ? "640" : "1242"
		if let url = Bundle.main.url(forResource: "illustration-\(allowedWidth)", withExtension: "mp4") {
			let playerItem = AVPlayerItem(url: url)

			if let track = playerItem.asset.tracks(withMediaCharacteristic: AVMediaCharacteristicVisual).first {
				// Let's figure out an appropriate size for the video
				let percent = min( track.naturalSize.width / screen.scale, screen.bounds.size.width, screen.bounds.size.height ) / track.naturalSize.width
				let size = CGSize(width: track.naturalSize.width * percent, height: track.naturalSize.height * percent)

				let headerView = UIView(frame: CGRect(x: 0, y: 0, width: self.tableView.frame.size.width, height: size.height * 0.28))
				headerView.backgroundColor = UIColor.clear
				self.tableView.tableHeaderView = headerView

				let player = AVPlayer(playerItem: playerItem)
				player.allowsExternalPlayback = false
				player.isMuted = true
				self.player = player

				let playerView = PlayerView(frame: CGRect(x: (headerView.frame.size.width - size.width) / 2, y: size.height * -0.72, width: size.width, height: size.height))
				playerView.autoresizingMask = [ .flexibleLeftMargin, .flexibleRightMargin ]
				playerView.backgroundColor = UIColor.clear
				playerView.player = self.player
				headerView.addSubview(playerView)

				NotificationCenter.default.addObserver(self, selector: #selector(AboutViewController.playerItemDidReachEnd(_:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: playerItem)
				NotificationCenter.default.addObserver(self, selector: #selector(AboutViewController.pausePlayer), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
				NotificationCenter.default.addObserver(self, selector: #selector(AboutViewController.resumePlayer), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
			}
		}

		// About
		let about = JSMStaticSection()
		self.dataSource.addSection(about)

		let version = JSMStaticRow()
		version.text = "Version"
		version.detailText = Bundle.main.displayVersion
		version.accessoryType = .none
		version.selectionStyle = .none
		about.addRow(version)

		// Other
		let openSource = JSMStaticSection()
		openSource.headerText = "Open Source"
		openSource.footerText = "Copyright © Daniel Farrelly\n\nRedistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:\n\n* Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.\n\n* Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.\n\nTHIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS \"AS IS\" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE."
		self.dataSource.addSection(openSource)

		let other = JSMStaticRow(key: "open-source.other")
		other.text = "Other"
		other.accessoryType = .disclosureIndicator
		other.selectionStyle = .default
		other.configuration { row, cell in
			cell.textLabel?.textColor = PreferencesManager.tintColor
		}
		openSource.addRow(other)

		let sherpa = JSMStaticRow(key: "open-source.sherpa")
		sherpa.text = "Sherpa"
		sherpa.accessoryType = .disclosureIndicator
		sherpa.selectionStyle = .default
		sherpa.configuration { row, cell in
			cell.textLabel?.textColor = PreferencesManager.tintColor
		}
		openSource.addRow(sherpa)

		let staticTables = JSMStaticRow(key: "open-source.statictables")
		staticTables.text = "StaticTables"
		staticTables.accessoryType = .disclosureIndicator
		staticTables.selectionStyle = .default
		staticTables.configuration { row, cell in
			cell.textLabel?.textColor = PreferencesManager.tintColor
		}
		openSource.addRow(staticTables)

	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		self.resumePlayer()
	}

	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		self.pausePlayer()
	}

	func pausePlayer() {
		self.player?.pause()
		do {
			try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategorySoloAmbient)
		}
		catch {}
	}

	func resumePlayer() {
		do {
			try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryAmbient)
		}
		catch {}
		self.player?.play()
	}

	// MARK: Table view delegate

	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		if let row = self.dataSource.row(at: indexPath), let key = row.key as? String {

			if key == "open-source.other", let url = URL(string: "https://github.com/jellystyle/ios-other") {
				let viewController = SFSafariViewController(url: url)
				self.present(viewController, animated: true, completion: nil)
			}

			else if key == "open-source.sherpa", let url = URL(string: "https://github.com/jellybeansoup/ios-sherpa") {
				let viewController = SFSafariViewController(url: url)
				self.present(viewController, animated: true, completion: nil)
			}

			else if key == "open-source.statictables", let url = URL(string: "https://github.com/jellybeansoup/ios-statictables") {
				let viewController = SFSafariViewController(url: url)
				self.present(viewController, animated: true, completion: nil)
			}

		}
	}

	// MARK: Player item notifications

	func playerItemDidReachEnd(_ playerItem: AVPlayerItem) {
		self.player?.seek(to: kCMTimeZero)
		self.player?.play()
	}

}
