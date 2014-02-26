#!/usr/bin/ruby

require 'trollop'
require 'rbvmomi'
require 'rbvmomi/trollop'

VIM = RbVmomi::VIM
CMDS = %w(vm-to-ip ip-to-vm)

opts = Trollop.options do
  banner <<-EOS

Get the IPs seen from the VM (vm-to-ip), or the VM name by searching for an IP (ip-to-vm)

Usage:
    assigned-ip.rb [options] ip-to-vm IP
    assigned-ip.rb [options] vm-to-ip VM

Commands: #{CMDS * ' '}

VIM connection options:
    EOS

    rbvmomi_connection_opts

    text <<-EOS

VM location options:
    EOS

    rbvmomi_datacenter_opt

    text <<-EOS

Other options:
  EOS

  stop_on CMDS
end

cmd = ARGV[0] or Trollop.die("no command given")
search_pattern = ARGV[1] or Trollop.die("no VM name or IP Address given")
abort "invalid command" unless CMDS.member? cmd
Trollop.die("must specify host") unless opts[:host]

vim = VIM.connect opts

dc = vim.serviceInstance.find_datacenter(opts[:datacenter]) or abort "datacenter not found"

case cmd
when 'ip-to-vm'
  ip = search_pattern
  vm_by_mobid = vim.rootFolder.findByIp(ip) or abort "IP not found"
  puts "IP #{ip} belongs to #{vm_by_mobid.name}"
when 'vm-to-ip'
  vm = dc.find_vm(search_pattern) or abort "VM not found"
  vm.guest.net.each_index do |x|
    puts "\nAddress seen on NIC#{x} = ", vm.guest.net[x].ipAddress, "\n"
  end
end
