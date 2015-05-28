//
//  Drawing.swift
//  Panic
//
//  Created by Byron Coetsee on 2015/03/14.
//  Copyright (c) 2015 Byron Coetsee. All rights reserved.
//

import UIKit

class Drawing: NSObject {
	
	func verticalLine(imageView: UIImageView, circles: Bool = false, dashed: Bool = false, colour: UIColor = UIColor.blackColor(), customWidth: CGFloat = 2) -> UIImage {
		
		let path = UIBezierPath()
		path.lineWidth = customWidth
		
		if circles == true {
			UIGraphicsBeginImageContextWithOptions(CGSizeMake(8, CGFloat(imageView.frame.height + 1)), false, 2) // 8, height
			var context = UIGraphicsGetCurrentContext()
			colour.set()
			CGContextSetLineWidth(context, 2.0);
			
			CGContextAddArc(context, 4, 4, 3, 0.0, CGFloat(M_PI * 2.0), 1)
			CGContextStrokePath(context)
			CGContextAddArc(context, 4, CGFloat(imageView.frame.height - 3), 3, 0.0, CGFloat(M_PI * 2.0), 1)
			CGContextStrokePath(context)
			if dashed == true {
				path.moveToPoint(CGPointMake(4, 13))
			} else {
				path.lineWidth = 2
				path.moveToPoint(CGPointMake(4, 8))
			}
			path.addLineToPoint(CGPointMake(4, CGFloat(imageView.frame.height - 7)))
		} else {
			UIGraphicsBeginImageContextWithOptions(CGSizeMake(4, CGFloat(imageView.frame.height - 5)), false, 2)
			path.moveToPoint(CGPointMake(2, 2))
			path.addLineToPoint(CGPointMake(2, CGFloat(imageView.frame.height - 3)))
		}
		
		var context = UIGraphicsGetCurrentContext()
		colour.set()
		
		
		if dashed == true {
			let dashes: [CGFloat] = [ 0, path.lineWidth * 2 ]
			path.setLineDash(dashes, count: dashes.count, phase: 0)
		}
		path.lineCapStyle = kCGLineCapRound
		path.stroke()
		return UIGraphicsGetImageFromCurrentImageContext()
	}
	
	func horizontalLine(imageView: UIImageView, customWidth: CGFloat = 2, colour: UIColor = UIColor.grayColor()) -> UIImage {
		let path = UIBezierPath()
		path.lineWidth = customWidth
		
		UIGraphicsBeginImageContextWithOptions(CGSizeMake(CGFloat(imageView.frame.height + 1), 5), false, 2) // 8, height
		var context = UIGraphicsGetCurrentContext()
		colour.set()
		CGContextSetLineWidth(context, 2.0);
		
		CGContextAddArc(context, 4, 4, 3, 0.0, CGFloat(M_PI * 2.0), 1)
		CGContextStrokePath(context)
		CGContextAddArc(context, 4, CGFloat(imageView.frame.height - 3), 3, 0.0, CGFloat(M_PI * 2.0), 1)
		CGContextStrokePath(context)
		path.lineWidth = 2
		path.moveToPoint(CGPointMake(2, 2))
		path.addLineToPoint(CGPointMake(CGFloat(imageView.frame.width - 2), 2))
		
		colour.set()
		
		path.lineCapStyle = kCGLineCapRound
		path.stroke()
		return UIGraphicsGetImageFromCurrentImageContext()
	}
	
	/**
	Draws a gradient over a view
	
	:param: view       The view which s used and will contain the gradient overlay
	:param: colours    Array of colours included in the gradient
	:param: locations  Locations of the colours ranging from 0 - 1
	:param: opacity    Opacity of the gradient
	:param: startPoint Where the gradient begins
	:param: endPoint   Where the gradient ends
	
	:returns: The gradient layer
	*/
	func gradient (view: UIView, colours: [CGColor], locations: [CGFloat] = [0.0 , 1.0], opacity: Float = 1, startPoint: CGPoint = CGPointZero, endPoint: CGPoint = CGPointZero) -> CAGradientLayer {
		let gradient: CAGradientLayer = CAGradientLayer()
		
		gradient.colors = colours
		gradient.locations = locations
		gradient.opacity = opacity
		if startPoint != CGPointZero || endPoint != CGPointZero {
			gradient.startPoint = startPoint
			gradient.endPoint = endPoint
		}
		gradient.frame = CGRect(x: 0.0, y: 0.0, width: view.frame.size.width, height: view.frame.size.height)
		
		return gradient
	}
	
	
	func viewBorderCircle(view: UIView, borderWidth: CGFloat = 1, borderColour: CGColor = UIColor.whiteColor().CGColor) -> UIView {
		view.layer.cornerRadius = 0.5 * view.bounds.size.width
		view.layer.borderWidth = borderWidth
		view.layer.borderColor = borderColour
		view.clipsToBounds = true
		return view
	}
	
	func picBorderCircle(pic: UIImageView, borderWidth: CGFloat = 1, borderColour: CGColor = UIColor.whiteColor().CGColor) -> UIImageView {
		pic.layer.cornerRadius = 0.5 * pic.bounds.size.width
		pic.layer.borderWidth = borderWidth
		pic.layer.borderColor = borderColour
		pic.clipsToBounds = true
		return pic
	}
	
	func buttonBorderCircle(button: UIButton, borderWidth: CGFloat = 1, borderColour: CGColor = UIColor.whiteColor().CGColor) -> UIButton {
		button.layer.cornerRadius = 0.5 * button.bounds.size.width
		button.layer.borderWidth = borderWidth
		button.layer.borderColor = borderColour
		button.clipsToBounds = true
		return button
	}
}
