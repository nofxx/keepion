#!/usr/bin/env ruby
require 'sinatra'
require 'slim'
require_relative 'lib/iwlist'
require_relative 'lib/netconf'

# configure { set server: :puma }

class Keepion < Sinatra::Base
  set environment: :production, port: 80, server: :puma
  WLAN = 'wlan0'.freeze

  before do
    @name = `uname -nr`
  end

  get '/' do
    sysinfo
    @list = IWList.scan(WLAN) rescue []
    slim :index
  end

  post '/connect' do
    wifi_vars
    if good_password(@password)
      Netconf.connect(@essid, @password)
    end
    slim :connect
  end

  post '/hostap' do
    wifi_vars
    if good_password(@password)
      Netconf.hostap(@essid, @password)
      sysinfo
      slim :hostap
    else
      sysinfo
      slim :index
    end
  end

  private

  def wifi_vars
    @essid, @password = params[:essid], params[:password]
  end

  def good_password(pass)
    (8..90) === pass.length && pass !~ /\s/
  end

  def sysinfo
    @wlan = `iwconfig #{WLAN}`
    @route = `route -n`
    @ipaddr = `ip addr`
  end
end

Keepion.run! if __FILE__ == $PROGRAM_NAME
