//
//  ViewController.swift
//  ProgressHUD
//
//  Created by Massimo Biolcati on 9/10/18.
//  Copyright © 2018 Massimo. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    @IBOutlet var styleSegmentedControl: NSSegmentedControl!
    @IBOutlet var maskSegmentedControl: NSSegmentedControl!
    @IBOutlet var positionSegmentedControl: NSSegmentedControl!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }

    private var hudStyle: ProgressHUDStyle {
        switch styleSegmentedControl.selectedSegment {
        case 0: return .light
        default: return .dark
        }
    }

    private var hudMaskType: ProgressHUDMaskType {
        switch maskSegmentedControl.selectedSegment {
        case 0: return .none
        case 1: return .clear
        case 2: return .black
        case 3: return .gradient
        default: return .none
        }
    }

    private var hudPosition: ProgressHUDPosition {
        switch positionSegmentedControl.selectedSegment {
        case 0: return .top
        case 1: return .center
        default: return .bottom
        }
    }

    @IBAction func showIndeterminate(_ sender: Any) {
        view.showProgressHUD(title: "Doing Stuff", message: "Completing something…", style: hudStyle, mode: .indeterminate, mask: hudMaskType, position: hudPosition, duration: 2)
    }

    @IBAction func showDeterminateCircular(_ sender: Any) {
        view.showProgressHUD(title: "Determinate Progress", message: "Almost done…", style: hudStyle, mode: .determinate, mask: hudMaskType, position: hudPosition)
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
        hud.title = "ERROR"
        hud.message = "Something went wrong"
        hud.hide(true, afterDelay: 2)

    }

    @IBAction func showTextOnly(_ sender: Any) {
        view.showProgressHUD(title: "Message", message: "Showing text only.\nOn multiple lines.\nSquashed much?", style: hudStyle, mode: .text, mask: hudMaskType, position: hudPosition, duration: 2)
    }

}
