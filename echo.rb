require "json"
require "selenium-webdriver"
require "rspec"
require 'eyes_selenium' 
include RSpec::Expectations

username   = ENV['SAUCE_USER']
access_key = ENV['SAUCE_KEY']
SAUCE_URL  = "http://#{username}:#{access_key}@ondemand.saucelabs.com/wd/hub"

file = File.read('./environments.json')
Environments = JSON.parse(file)

def get_user_input
  puts "Run locally or on Sauce Labs?"
  puts "f: firefox"
  puts "c: chrome"
  puts "s: Sauce Labs"
  $stdin.gets.chomp.downcase
end

def driver_for(env)

  if Key == 's'
    caps = Selenium::WebDriver::Remote::Capabilities.chrome
    caps[:screenResolution] = "1280x1024"
    caps.platform, caps.browser_name, caps.version = env

    Selenium::WebDriver.for(:remote,
      url: SAUCE_URL, 
      desired_capabilities: caps
    )
  else
    Selenium::WebDriver.for(Key == 'c' ? :chrome : :firefox )
  end
end

def run_tests
  if Key == 's'
    Environments.each do |env|
      yield(env)
    end
  else
    yield ['Locally', Key, 'latest']
  end
end

describe "Echo Test Suite" do

  Key = get_user_input

  before(:all) do

    @eyes = Applitools::Eyes.new
    @eyes.api_key = ENV['APPLITOOLS_KEY']

    @base_url = "http://digitalscientists.github.io/echo-static/"

  end

  before(:each) do
    @verification_errors = []
  end
  
  after(:each) do
    expect(@verification_errors).to eq([])
  end

  after(:all) do
  end
  
  run_tests do |env|

    it "tests the dashboard on #{env}" do

      @eyes.test(

        app_name: 'Echo', 
        test_name: 'Dashboard Test', 
        viewport_size: { width: 1024, height: 768 },
        driver: driver_for(env)

      ) do |driver|

        driver.get(@base_url + "/")

        @eyes.check_window('Dashboard')

        driver.execute_script(%|
          document.querySelector('.page-container').scrollTop = 600
        |)
        @eyes.check_window('My Surveys')

        driver.find_element(:link, "New Survey").click
        @eyes.check_window('New Survey Menu')

        driver.find_element(:css, "a.left-off-canvas-toggle.menu-icon").click
        @eyes.check_window('Main Menu')

        driver.quit

      end

    end

    it "tests the Select Schools Page on #{env}" do

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

    it "tests the Survey Editor Page on #{env}" do
      @eyes.test(

        app_name: 'Echo', 
        test_name: 'Survey Editor Test', 
        viewport_size: { width: 1024, height: 768 },
        driver: driver_for(env)

      ) do |driver|

        driver.get(@base_url + "/survey-edit.html")
        @eyes.check_window('Survey Edit')

        driver.execute_script(%|
          document.querySelector('.survey-edit__content').scrollTop = 600
        |)
        driver.find_element(:css, "label[for=radio1]").click
        @eyes.check_window('Survey Question Section 1')

        driver.execute_script(%|
          document.querySelector('.survey-edit__content').scrollTop = 1600
        |)
        @eyes.check_window('Survey Question Section 2')

        driver.quit
      end

    end

  end
  
end
