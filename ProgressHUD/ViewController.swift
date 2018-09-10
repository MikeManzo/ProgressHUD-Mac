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
        let hud = ProgressHUD.showAdded(to: view, animated: true)
        hud.mode = .indeterminate
        hud.labelText = "Doing Stuff"
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2) {
            hud.hide(true)
        }
    }

    @IBAction func showDeterminateCircular(_ sender: Any) {
        let hud = ProgressHUD.showAdded(to: view, animated: true)
        hud.mode = .determinateCircular
        hud.labelText = "Determinate Progress"
        hud.detailsLabelText = "Circular"
        DispatchQueue.global(qos: .default).async {
            for _ in 0..<100 {
                usleep(10000)
                DispatchQueue.main.async {
                    hud.progress += 0.01
                }
            }
        }
        hud.hide(true, afterDelay: 2.0)

    }

    @IBAction func showDeterminalAnnular(_ sender: Any) {
        let hud = ProgressHUD.showAdded(to: view, animated: true)
        hud.mode = .determinateAnnular
        hud.labelText = "Determinate Progress"
        hud.detailsLabelText = "Annular"
        DispatchQueue.global(qos: .default).async {
            for _ in 0..<100 {
                usleep(10000)
                DispatchQueue.main.async {
                    hud.progress += 0.01
                }
            }
        }
        hud.hide(true, afterDelay: 2.0)

    }

    @IBAction func showDeterminateHorizontalBar(_ sender: Any) {
        let hud = ProgressHUD.showAdded(to: view, animated: true)
        hud.mode = .determinateHorizontalBar
        hud.labelText = "Determinate Progress"
        hud.detailsLabelText = "Horizontal Bar"
        DispatchQueue.global(qos: .default).async {
            for _ in 0..<100 {
                usleep(10000)
                DispatchQueue.main.async {
                    hud.progress += 0.01
                }
            }
        }
        hud.hide(true, afterDelay: 2.0)

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
        let hud = ProgressHUD.showAdded(to: view, animated: true)
        hud.mode = .text
        hud.labelText = "Message"
        hud.detailsLabelText = "Showing text only"
        hud.hide(true, afterDelay: 2)
    }
}
