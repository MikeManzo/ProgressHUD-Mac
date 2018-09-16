//
//  ViewController.swift
//  ProgressHUD
//
//  Created by Massimo Biolcati on 9/10/18.
//  Copyright © 2018 Massimo. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }

    @IBAction func showIndeterminate(_ sender: Any) {
        view.showProgressHUD(title: "Doing Stuff", message: "Completing something…", mode: .indeterminate, duration: 2)
    }

    @IBAction func showDeterminateCircular(_ sender: Any) {
        view.showProgressHUD(title: "Determinate Progress", message: "Almost done…", mode: .determinate)
        DispatchQueue.global(qos: .default).async {
            var progress = 0.0
            for _ in 0..<100 {
                usleep(10000)
                progress += 0.01
                self.view.setProgressHUDProgress(progress)
            }
            self.view.hideProgressHUD()

        }
    }

    @IBAction func showCustomView(_ sender: Any) {

        let hud = ProgressHUD.showAdded(to: view, animated: true)
        let imageView = NSImageView(frame: NSRect(x: 0, y: 0, width: 40, height: 40))
        imageView.image = NSImage(named: "error-X-icon")
        hud.customView = imageView
        hud.mode = .customView
        hud.labelText = "ERROR"
        hud.detailsLabelText = "Something went wrong"
        hud.hide(true, afterDelay: 2)

    }

    @IBAction func showTextOnly(_ sender: Any) {
        view.showProgressHUD(title: "Message", message: "Showing text only.\nOn multiple lines.\nSquashed much?", mode: .text, duration: 2)
    }
    
}
