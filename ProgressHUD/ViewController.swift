//
//  ViewController.swift
//  ProgressHUD, https://github.com/massimobio/ProgressHUD
//
//  Created by Massimo Biolcati on 9/10/18.
//  Copyright © 2018 Massimo. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    @IBOutlet private var locationSegmentedControl: NSSegmentedControl!
    @IBOutlet private var modeSegmentedControl: NSSegmentedControl!
    @IBOutlet private var styleSegmentedControl: NSSegmentedControl!
    @IBOutlet private var maskSegmentedControl: NSSegmentedControl!
    @IBOutlet private var positionSegmentedControl: NSSegmentedControl!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    @IBAction func showHUD(_ sender: Any) {

        // set ProgressHUD defaults according to user selected options
        applyUserSelectedHUDStyle()
        applyUserSelectedHUDMaskType()
        applyUserSelectedHUDPosition()
        ProgressHUD.setContainerView(locationSegmentedControl.selectedSegment == 0 ? view : nil)

        switch modeSegmentedControl.selectedSegment {

        case 0: // Indeterminate
            ProgressHUD.shared.mode = .indeterminate
            ProgressHUD.show(withStatus: "Indeterminate Progress…")
            ProgressHUD.dismiss(delay: 2)

        case 1: // Determinate
            ProgressHUD.shared.mode = .determinate
            ProgressHUD.show(withStatus: "Determinate Progress…")
            DispatchQueue.global(qos: .default).async {
                var progress = 0.0
                for _ in 0..<100 {
                    usleep(10000)
                    progress += 0.01
                    ProgressHUD.show(progress: progress, status: "Determinate Progress…")
                }
                ProgressHUD.dismiss(delay: 1)
            }

        case 2: // Error
            ProgressHUD.shared.mode = .error
            ProgressHUD.show(withStatus: "Something bad happened!")
            ProgressHUD.dismiss(delay: 2)

        case 3: // Success
            ProgressHUD.shared.mode = .success
            ProgressHUD.show(withStatus: "Everything worked out in the end")
            ProgressHUD.dismiss(delay: 2)

        case 4: // Text Only
            ProgressHUD.shared.mode = .text
            ProgressHUD.show(withStatus: "Showing text only.\nOn multiple lines.\nSquashed much?")
            ProgressHUD.dismiss(delay: 2)

        case 5: // Custom View
            let image = NSImage(named: "unicorn")!
            let imageView = NSImageView(frame: NSRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
            imageView.image = image
            ProgressHUD.shared.mode = .custom(view: imageView)
            ProgressHUD.show(withStatus: "I'm not a horse")
            ProgressHUD.dismiss(delay: 2)

        default:
            break
        }
    }

    private func applyUserSelectedHUDStyle() {
        switch styleSegmentedControl.selectedSegment {
        case 0: return ProgressHUD.setDefaultStyle(.light)
        case 1: return ProgressHUD.setDefaultStyle(.dark)
        default: return ProgressHUD.setDefaultStyle(.custom(foreground: .yellow, backgroud: .red))
        }
    }

    private func applyUserSelectedHUDMaskType() {
        switch maskSegmentedControl.selectedSegment {
        case 0: return ProgressHUD.setDefaultMaskType(.none)
        case 1: return ProgressHUD.setDefaultMaskType(.clear)
        case 2: return ProgressHUD.setDefaultMaskType(.black)
        default: return ProgressHUD.setDefaultMaskType(.custom(color: NSColor.green.withAlphaComponent(0.6)))
        }
    }

    private func applyUserSelectedHUDPosition() {
        switch positionSegmentedControl.selectedSegment {
        case 0: return ProgressHUD.setDefaultPosition(.top)
        case 1: return ProgressHUD.setDefaultPosition(.center)
        default: return ProgressHUD.setDefaultPosition(.bottom)
        }
    }

}
