import UIKit
import NotificationCenter

class TodayViewController: UIViewController, NCWidgetProviding, IconViewControllerDelegate {
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let iconViewController = IconViewController()

        self.addChildViewController(iconViewController)
        self.view.addSubview(iconViewController.view)

        iconViewController.delegate = self
        iconViewController.view.anchor(to: self.view)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    func widgetPerformUpdate(completionHandler: @escaping (NCUpdateResult) -> Void) {
        completionHandler(NCUpdateResult.newData)
    }
    
    func iconViewController(_ iconViewController: UIViewController, didRequestOpenURL url: URL) {
        self.extensionContext?.open(url, completionHandler: nil)
    }
    
}
