#!/usr/bin/env ruby
require 'sinatra'
require 'slim'
require_relative 'lib/iwlist'
require_relative 'lib/netconf'

# configure { set server: :puma }

class Keepion < Sinatra::Base
  set environment: :production, port: 80, server: :puma
  WLAN = 'wlan0'.freeze

  get '/' do
    get_sysinfo
    @list = IWList.scan(WLAN) rescue []
    slim :index
  end

  post '/connect' do
    get_vars
    if good_password(@password)
      Netconf.connect(@essid, @password)
    end
    slim :connect
  end

  post '/hostap' do
    get_vars
    if good_password(@password)
      Netconf.hostap(@essid, @password)
      get_sysinfo
      slim :hostap
    else
      get_sysinfo
      slim :index
    end
  end

  private

  def get_vars
    @essid, @password = params[:essid], params[:password]
  end

  def good_password(pass)
    (8..90) === pass.length && pass !~ /\s/
  end

  def get_sysinfo
    @data = "KeePion! #{`uname -a`}"
    @wlan = `iwconfig #{WLAN}`
    @route = `route -n`
    @ipaddr = `ip addr`
  end
end

if __FILE__ == $0
  Keepion.run!
end
