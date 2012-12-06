Vagrant::Config.run do |config|
    config.vm.host_name = "api"
    config.vm.box = "lucid32"
    config.vm.box_url = "http://files.vagrantup.com/lucid32.box"
    config.vm.forward_port 80, 8080
    config.vm.network :hostonly, "10.11.12.13"
    config.vm.provision :puppet do |puppet|
        puppet.manifests_path = "puppet"
        puppet.manifest_file  = "cakephp.pp"
    end
end
