# Uncomment the next line to define a global platform for your project
 platform :ios, '10.0'

target 'Brave' do
	use_frameworks!

    pod 'ChameleonFramework/Swift', :git => 'https://github.com/ViccAlexander/Chameleon.git'
    
    pod 'UIScrollSlidingPages'
	pod 'HMSegmentedControl'
	pod 'CustomBadge'
	pod 'Mapbox-iOS-SDK'
    
    pod 'SwiftValidate'
    pod 'Spring', :git => 'https://github.com/MengTo/Spring.git', :branch => 'swift3'
    
	pod 'Parse'
    pod 'Parse/FacebookUtils'
    pod 'ParseLiveQuery'
    
    pod 'Firebase/Core'
    pod 'Firebase/Messaging'
    pod 'Firebase/RemoteConfig'
    pod 'Fabric'
    pod 'Crashlytics'
    
    pod 'FacebookCore'
    pod 'FacebookLogin'
    pod 'pop'

    pod 'SwiftyJSON'
    pod 'SwiftLocation'
    pod 'SDWebImage'
    pod 'Toast'
    pod 'SCLAlertView'
    pod 'SZTextView'
    pod 'BBLocationManager'
    pod 'SwiftLocation', '~> 3.1.0'
    pod 'Alamofire'
    pod 'MessageKit', '~> 0.10.2'
    pod 'ESTabBarController-swift'
    pod 'NotificationBannerSwift'
    pod 'CenteredCollectionView'

end


post_install do |installer|
    installer.pods_project.targets.each do |target|
        if target.name.end_with? 'Bolts-Swift'
            target.build_configurations.each do |config|
                config.build_settings['SWIFT_VERSION'] = '3.0'
            end
        end

        if target.name == 'MessageKit'
            target.build_configurations.each do |config|
                config.build_settings['SWIFT_VERSION'] = '4.0'
            end
        end
    end
end

