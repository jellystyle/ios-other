import UIKit
import NotificationCenter

class TodayViewController: UIViewController, NCWidgetProviding, IconViewControllerDelegate {
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let iconViewController = IconViewController()

        self.addChildViewController(iconViewController)
        self.view.addSubview(iconViewController.view)

        iconViewController.delegate = self
        iconViewController.view.anchor(toAllSidesOf: self.view)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    func widgetPerformUpdateWithCompletionHandler(completionHandler: (NCUpdateResult) -> Void) {
        completionHandler(NCUpdateResult.NewData)
    }
    
    func iconViewController(iconViewController: UIViewController, didRequestOpenURL url: NSURL) {
        self.extensionContext?.openURL(url, completionHandler: nil)
    }
    
}
