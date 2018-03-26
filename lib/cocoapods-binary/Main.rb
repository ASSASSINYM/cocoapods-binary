# encoding: UTF-8

require_relative 'tool/tool'

require_relative 'podfile_options'
require_relative 'prebuild_sandbox'

require_relative 'Integration'
require_relative 'Prebuild'

require_relative 'feature_switches'
require_relative 'prebuild_sandbox'


Pod::HooksManager.register('cocoapods-binary', :pre_install) do |installer_context|

    if Pod.is_prebuild_stage
        next
    end

    # [Check Environment]
    # check user_framework is on
    podfile = installer_context.podfile
    podfile.target_definition_list.each do |target_definition|
        next if target_definition.prebuild_framework_names.empty?
        if not target_definition.uses_frameworks?
            STDERR.puts "[!] Cocoapods-binary requires `use_frameworks!`".red
            exit
        end
    end


    # -- step 1: prebuild framework ---
    # Execute a sperated pod install, to generate targets for building framework,
    # then compile them to framework files.
    
    Pod::UI.puts "🚀  Prebuild frameworks"

    # control features
    Pod.is_prebuild_stage = true
    Pod::Podfile::DSL.enable_prebuild_patch true  # enable sikpping for prebuild targets
    Pod::Installer.force_disable_integration true # don't integrate targets
    Pod::Config.force_disable_write_lockfile true # disbale write lock file for perbuild podfile
    Pod::Installer.disable_install_complete_message true # disable install complete message

    # make another custom sandbox
    standard_sandbox = installer_context.sandbox
    prebuild_sandbox = Pod::PrebuildSandbox.from_standard_sandbox(standard_sandbox)

    # get the podfile for prebuild
    prebuild_podfile = Pod::Podfile.from_ruby(podfile.defined_in_file)
    
    # install
    binary_installer = Pod::Installer.new(prebuild_sandbox, prebuild_podfile , nil)
    binary_installer.repo_update = false
    binary_installer.update = false
    binary_installer.install!


    # reset the environment
    Pod.is_prebuild_stage = false
    Pod::Installer.force_disable_integration false
    Pod::Podfile::DSL.enable_prebuild_patch false
    Pod::Config.force_disable_write_lockfile false
    Pod::Installer.disable_install_complete_message false

    
    # -- step 2: prebuild framework ---
    # install
    Pod::UI.puts "\n"
    Pod::UI.puts "🤖  Pod Install"
          
end

