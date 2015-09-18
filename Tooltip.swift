//
//  Tooltip.swift
//  Panic
//
//  Created by Byron Coetsee on 2015/09/13.
//  Copyright (c) 2015 Byron Coetsee. All rights reserved.
//

import UIKit

class Tooltip: NSObject {
	
	var view: UIView!
	var arrow: UIImageView!
	
	init(view: UIView, arrow: UIImageView, hidden: Bool = false) {
		super.init()
		
		self.view = view
		self.arrow = arrow
		
		view.layer.cornerRadius = 10
		view.clipsToBounds = true
		
		var tap = UITapGestureRecognizer(target: self, action: "hide")
		view.addGestureRecognizer(tap)
		
		if hidden == true {
			view.hidden = true
			arrow.hidden = true
		}
	}
	
	func hide() {
		UIView.animateWithDuration(0.5, animations: {
			self.view.alpha = 0
			self.arrow.alpha = 0
			}, completion: { (result: Bool) -> Void in
				// hide maybe?
		})
	}
	
	func show() {
		UIView.animateWithDuration(0.5, animations: {
			self.view.alpha = 0.8
			self.arrow.alpha = 0.8
			}, completion: { (result: Bool) -> Void in
				// hide maybe?
		})
	}
	
	func setText(newText: String) {
		for subview in view.subviews {
			if subview is UILabel {
				animateTextChange((subview as! UILabel), newString: newText)
			}
		}
	}
	
	func animateTextChange(label: UILabel, newString : String) {
		UIView.animateWithDuration(0.2, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: {
			label.alpha = 0.0
			}, completion: {
				(finished: Bool) -> Void in
				
				//Once the label is completely invisible, set the text and fade it back in
				label.text = newString
				
				// Fade in
				UIView.animateWithDuration(0.2, delay: 0.0, options: UIViewAnimationOptions.CurveEaseIn, animations: {
					label.alpha = 1.0
					}, completion: nil)
		})
	}
	
	
}
