Pod::Spec.new do |s|
  s.name             = 'flutter_ffmpeg_fijkplayer'
  s.version          = '0.0.3'
  s.summary          = 'FFmpeg plugin for Flutter.'
  s.description      = 'FFmpeg plugin based on mobile-ffmpeg for Flutter.'
  s.homepage         = 'https://github.com/martytsaitw/flutter-ffmpeg-fijkplayer'

  s.author           = { 'Taner Sener' => 'tanersener@gmail.com' }
  s.license          = { :file => '../LICENSE' }

  s.requires_arc     = true
  s.static_framework = true

  s.source              = { :path => '.' }
  s.source_files        = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'

  s.xcconfig  =  { 'LIBRARY_SEARCH_PATHS' => '"$(PODS_ROOT)/../.symlinks/plugins/flutter_ffmpeg_fijkplayer/ios"' }

  s.libraries = "runffmpeg"

  s.dependency          'Flutter'

end
