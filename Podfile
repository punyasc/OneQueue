# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

target 'SongScrape' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for SongScrape
	pod ‘Alamofire’
	pod ‘SwiftyJSON’
	pod ‘UIImageColors’
	pod 'SpotifyLogin', '~> 0.1'

  target 'SongScrapeTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'SongScrapeUITests' do
    inherit! :search_paths
    # Pods for testing
  end

end

post_install do |installer|  
    installer.pods_project.targets.each do |target|  
        target.build_configurations.each do |config|  
            config.build_settings['ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES'] = 'NO'  
        end  
    end  
end  
