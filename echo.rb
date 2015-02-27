require "json"
require "selenium-webdriver"
require "rspec"
require 'eyes_selenium' 
include RSpec::Expectations

username   = ENV['SAUCE_USER']
access_key = ENV['SAUCE_KEY']
SAUCE_URL  = "http://#{username}:#{access_key}@ondemand.saucelabs.com/wd/hub"

file = File.read('./environments.json')
environments = JSON.parse(file)

def driver_for(env)
  caps = Selenium::WebDriver::Remote::Capabilities.chrome
  caps[:screenResolution] = "1280x1024"
  caps.platform, caps.browser_name, caps.version = env

  Selenium::WebDriver.for(:remote,
    url: SAUCE_URL, 
    desired_capabilities: caps
  )
end

describe "Echo Test Suite" do

  before(:all) do

    @eyes = Applitools::Eyes.new
    @eyes.api_key = 'F98XqniW4M0E4sgOKnLvPK6aNJvMFoh97L4x7BuAr1MQw110' 

    @base_url = "http://digitalscientists.github.io/echo-static/"

  end

  before(:each) do
    @verification_errors = []

  end
  
  after(:each) do
    expect(@verification_errors).to eq([])
  end

  after(:all) do
    @driver.quit
  end
  
  environments.each do |env|

    it "tests the dashboard on #{env}" do

      @eyes.test(

        app_name: 'Echo', 
        test_name: 'Dashboard Test', 
        viewport_size: { width: 1024, height: 768 },
        driver: driver_for(env)

      ) do |driver|

        driver.get(@base_url + "/")
        @eyes.check_window('Dashboard')
        driver.find_element(:link, "New Survey").click
        @eyes.check_window('New Survey Menu')
        driver.find_element(:css, "a.left-off-canvas-toggle.menu-icon").click
        @eyes.check_window('Main Menu')

        driver.quit

      end

    end

    it "tests the select schools on #{env}" do
      @eyes.test(

        app_name: 'Echo', 
        test_name: 'Select Schools Test', 
        viewport_size: { width: 1024, height: 768 },
        driver: driver_for(env)

      ) do |driver|

        driver.get(@base_url + "/select-school.html")
        @eyes.check_window('Select School')

        driver.quit
      end

    end

  end
  
end
