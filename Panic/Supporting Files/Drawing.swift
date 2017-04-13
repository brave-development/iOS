//
//  Drawing.swift
//  Panic
//
//  Created by Byron Coetsee on 2015/03/14.
//  Copyright (c) 2015 Byron Coetsee. All rights reserved.
//

import UIKit
//import VCFloatingActionButton

var drawing = Drawing()

extension UITextField {
	func addDashedBorder() {
		let color = UIColor.red.cgColor
		
		let shapeLayer:CAShapeLayer = CAShapeLayer()
		let frameSize = self.frame.size
		let shapeRect = CGRect(x: 0, y: 0, width: frameSize.width, height: frameSize.height)
		
		shapeLayer.bounds = shapeRect
		shapeLayer.position = CGPoint(x: frameSize.width/2, y: frameSize.height/2)
		shapeLayer.fillColor = UIColor.clear.cgColor
		shapeLayer.strokeColor = color
		shapeLayer.lineWidth = 2
		shapeLayer.lineJoin = kCALineJoinRound
		shapeLayer.lineDashPattern = [6,3]
		shapeLayer.path = UIBezierPath(roundedRect: shapeRect, cornerRadius: 5).cgPath
		
		self.layer.addSublayer(shapeLayer)
		
	}
}

class Drawing: NSObject {
	
	func verticalLine(_ imageView: UIImageView, circles: Bool = false, dashed: Bool = false, colour: UIColor = UIColor.black, customWidth: CGFloat = 2) -> UIImage {
		
		let path = UIBezierPath()
		path.lineWidth = customWidth
		
		if circles == true {
			UIGraphicsBeginImageContextWithOptions(CGSize(width: 8, height: CGFloat(imageView.frame.height + 1)), false, 2) // 8, height
			let context = UIGraphicsGetCurrentContext()
			colour.set()
			context?.setLineWidth(2.0);
			
//			CGContextAddArc(context, 4, 4, 3, 0.0, CGFloat(Double.pi * 2.0), 1)
            context?.addArc(center: CGPoint(x: 4, y: 4), radius: 3, startAngle: 0.0, endAngle: CGFloat(Double.pi * 2.0), clockwise: true)
			context?.strokePath()
//			CGContextAddArc(context, 4, CGFloat(imageView.frame.height - 3), 3, 0.0, CGFloat(Double.pi * 2.0), 1)
            context?.addArc(center: CGPoint(x: 4, y: CGFloat(imageView.frame.height - 3)), radius: 3, startAngle: 0.0, endAngle: CGFloat(Double.pi * 2.0), clockwise: true)
			context?.strokePath()
			if dashed == true {
				path.move(to: CGPoint(x: 4, y: 13))
			} else {
				path.lineWidth = 2
				path.move(to: CGPoint(x: 4, y: 8))
			}
			path.addLine(to: CGPoint(x: 4, y: CGFloat(imageView.frame.height - 7)))
		} else {
			UIGraphicsBeginImageContextWithOptions(CGSize(width: 4, height: CGFloat(imageView.frame.height - 5)), false, 2)
			path.move(to: CGPoint(x: 2, y: 2))
			path.addLine(to: CGPoint(x: 2, y: CGFloat(imageView.frame.height - 3)))
		}
		
//		var context = UIGraphicsGetCurrentContext()
		colour.set()
		
		
		if dashed == true {
			let dashes: [CGFloat] = [ 0, path.lineWidth * 2 ]
			path.setLineDash(dashes, count: dashes.count, phase: 0)
		}
		path.lineCapStyle = .round
		path.stroke()
		return UIGraphicsGetImageFromCurrentImageContext()!
	}
	
	func horizontalLine(_ imageView: UIImageView, customWidth: CGFloat = 2, colour: UIColor = UIColor.gray) -> UIImage {
		let path = UIBezierPath()
		path.lineWidth = customWidth
		
		UIGraphicsBeginImageContextWithOptions(CGSize(width: CGFloat(imageView.frame.height + 1), height: 5), false, 2) // 8, height
		let context = UIGraphicsGetCurrentContext()
		colour.set()
		context?.setLineWidth(2.0);
		
//		CGContextAddArc(context, 4, 4, 3, 0.0, CGFloat(M_PI * 2.0), 1)
        context?.addArc(center: CGPoint(x: 4, y: 4), radius: 3, startAngle: 0.0, endAngle: CGFloat(Double.pi * 2.0), clockwise: true)
		context?.strokePath()
//		CGContextAddArc(context, 4, CGFloat(imageView.frame.height - 3), 3, 0.0, CGFloat(M_PI * 2.0), 1)
        context?.addArc(center: CGPoint(x: 4, y: CGFloat(imageView.frame.height - 3)), radius: 3, startAngle: 0.0, endAngle: CGFloat(Double.pi * 2.0), clockwise: true)
		context?.strokePath()
		path.lineWidth = 2
		path.move(to: CGPoint(x: 2, y: 2))
		path.addLine(to: CGPoint(x: CGFloat(imageView.frame.width - 2), y: 2))
		
		colour.set()
		
		path.lineCapStyle = .round
		path.stroke()
		return UIGraphicsGetImageFromCurrentImageContext()!
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
	func gradient (_ view: UIView, colours: [CGColor], locations: [CGFloat] = [0.0 , 1.0], opacity: Float = 1, startPoint: CGPoint = CGPoint.zero, endPoint: CGPoint = CGPoint.zero) -> CAGradientLayer {
		let gradient: CAGradientLayer = CAGradientLayer()
		
		gradient.colors = colours
		gradient.locations = locations as [NSNumber]
		gradient.opacity = opacity
		if startPoint != CGPoint.zero || endPoint != CGPoint.zero {
			gradient.startPoint = startPoint
			gradient.endPoint = endPoint
		}
		gradient.frame = CGRect(x: 0.0, y: 0.0, width: view.frame.size.width, height: view.frame.size.height)
		
		return gradient
	}
	
	
	func viewBorderCircle(_ view: UIView, borderWidth: CGFloat = 1, borderColour: CGColor = UIColor.white.cgColor) -> UIView {
		view.layer.cornerRadius = 0.5 * view.bounds.size.width
		view.layer.borderWidth = borderWidth
		view.layer.borderColor = borderColour
		view.clipsToBounds = true
		return view
	}
	
	func picBorderCircle(_ pic: UIImageView, borderWidth: CGFloat = 1, borderColour: CGColor = UIColor.white.cgColor) -> UIImageView {
		pic.layer.cornerRadius = 0.5 * pic.bounds.size.width
		pic.layer.borderWidth = borderWidth
		pic.layer.borderColor = borderColour
		pic.clipsToBounds = true
		return pic
	}
	
	func buttonBorderCircle(_ button: UIButton, borderWidth: CGFloat = 1, borderColour: CGColor = UIColor.white.cgColor) -> UIButton {
		button.layer.cornerRadius = 0.5 * button.bounds.size.width
		button.layer.borderWidth = borderWidth
		button.layer.borderColor = borderColour
		button.clipsToBounds = true
		return button
	}
}
