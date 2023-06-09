# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  vms = [
    {
      :id => "debian-bullseye",
      :box => "bento/debian-11",
    },
    {
      :id => "ubuntu-focal",
      :box => "bento/ubuntu-20.04",
    },
    {
      :id => "ubuntu-jammy",
      :box => "bento/ubuntu-22.04",
    },
  ]

  n_cpus = ENV["BOX_N_CPUS"]&.to_i || 2
  memory = ENV["BOX_MEMORY"]&.to_i || 2048
  vms.each_with_index do |vm, idx|
    id = vm[:id]
    box = vm[:box] || id
    config.vm.define(id) do |node|
      node.vm.box = box
      node.vm.provider("virtualbox") do |virtual_box|
        virtual_box.cpus = n_cpus if n_cpus
        virtual_box.memory = memory if memory
      end
    end
  end
end
