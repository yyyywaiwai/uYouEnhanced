import UIKit

class AppIconOptionsController: UIViewController {
    
    var tableView: UITableView!
    var appIcons: [String] = []
    var selectedIconIndex: Int = -1

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Change App Icon"
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.font: UIFont(name: "YTSans-Bold", size: 22)!, NSAttributedString.Key.foregroundColor: UIColor.white]
        
        selectedIconIndex = -1
        
        tableView = UITableView(frame: view.bounds, style: .plain)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        view.addSubview(tableView)

        let backButton = UIBarButtonItem(image: UIImage(named: "Back.png"), style: .plain, target: self, action: #selector(back))
        navigationItem.leftBarButtonItem = backButton

        appIcons = loadAppIcons()
        setupNavigationBar()
    }

    func loadAppIcons() -> [String] {
        guard let path = Bundle.main.path(forResource: "uYouPlus", ofType: "bundle"),
              let bundle = Bundle(path: path) else {
            return []
        }
        return bundle.paths(forResourcesOfType: "png", inDirectory: "AppIcons")
    }

    func setupNavigationBar() {
        let resetButton = UIBarButtonItem(image: UIImage(systemName: "arrow.clockwise.circle.fill"), style: .plain, target: self, action: #selector(resetIcon))

        let saveButton = UIBarButtonItem(title: "Save", style: .plain, target: self, action: #selector(saveIcon))
        navigationItem.rightBarButtonItems = [saveButton, resetButton]
    }

    @objc func resetIcon() {
        UIApplication.shared.setAlternateIconName(nil) { error in
            if let error = error {
                print("Error resetting icon: \(error.localizedDescription)")
                showAlertWithTitle("Error", message: "Failed to reset icon")
            } else {
                print("Icon reset successfully")
                showAlertWithTitle("Success", message: "Icon reset successfully")
                tableView.reloadData()
            }
        }
    }

    @objc func saveIcon() {
        DispatchQueue.global().async {
            let selectedIcon = self.selectedIconIndex >= 0 ? self.appIcons[self.selectedIconIndex] : nil
            guard let iconName = selectedIcon,
                  let plistPath = Bundle.main.path(forResource: "Info", ofType: "plist"),
                  var infoDict = NSMutableDictionary(contentsOfFile: plistPath),
                  var iconsDict = infoDict["CFBundleIcons"] as? NSMutableDictionary,
                  var primaryIconDict = iconsDict["CFBundlePrimaryIcon"] as? NSMutableDictionary,
                  var iconFiles = primaryIconDict["CFBundleIconFiles"] as? [String] else {
                print("Error accessing Info.plist")
                return
            }

            iconFiles.append(iconName)
            primaryIconDict["CFBundleIconFiles"] = iconFiles
            infoDict["CFBundleIcons"] = iconsDict
            infoDict.write(toFile: plistPath, atomically: true)

            UIApplication.shared.setAlternateIconName(iconName) { error in
                if let error = error {
                    print("Error setting alternate icon: \(error.localizedDescription)")
                    showAlertWithTitle("Error", message: "Failed to set alternate icon")
                } else {
                    print("Alternate icon set successfully")
                    showAlertWithTitle("Success", message: "Alternate icon set successfully")
                    DispatchQueue.main.async {
                        tableView.reloadData()
                    }
                }
            }
        }
    }

    func showAlertWithTitle(_ title: String, message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(okAction)
            present(alert, animated: true, completion: nil)
        }
    }

    @objc func back() {
        navigationController?.popViewController(animated: true)
    }
}

extension AppIconOptionsController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return appIcons.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") ?? UITableViewCell(style: .default, reuseIdentifier: "Cell")
        
        for view in cell.contentView.subviews {
            view.removeFromSuperview()
        }

        let iconPath = appIcons[indexPath.row]
        if let iconImage = UIImage(contentsOfFile: iconPath) {
            let iconImageView = UIImageView(image: iconImage)
            iconImageView.contentMode = .scaleAspectFit
            iconImageView.frame = CGRect(x: 16, y: 10, width: 60, height: 60)
            iconImageView.layer.cornerRadius = 8
            iconImageView.layer.masksToBounds = true
            cell.contentView.addSubview(iconImageView)

            let iconNameLabel = UILabel(frame: CGRect(x: 90, y: 10, width: view.frame.size.width - 90, height: 60))
            iconNameLabel.text = URL(fileURLWithPath: iconPath).deletingPathExtension().lastPathComponent
            iconNameLabel.textColor = .black
            iconNameLabel.font = UIFont.systemFont(ofSize: 16.0, weight: .medium)
            cell.contentView.addSubview(iconNameLabel)

            cell.accessoryType = (indexPath.row == selectedIconIndex) ? .checkmark : .none
        }

        return cell
    }
}
