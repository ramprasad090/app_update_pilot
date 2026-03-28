Pod::Spec.new do |s|
  s.name             = 'app_update_pilot'
  s.version          = '0.1.0'
  s.summary          = 'The complete app update lifecycle manager for Flutter.'
  s.description      = <<-DESC
Store version checks, force update walls, A/B rollout, rich changelogs,
skip with cooldown, analytics hooks, and remote config from any JSON API.
                       DESC
  s.homepage         = 'https://github.com/ramprasadsreerama/app_update_pilot'
  s.license          = { :type => 'MIT', :file => '../LICENSE' }
  s.author           = { 'Ramprasad Sreerama' => '' }
  s.source           = { :http => 'https://github.com/ramprasadsreerama/app_update_pilot' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform         = :ios, '12.0'
  s.swift_version    = '5.0'

  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
end
