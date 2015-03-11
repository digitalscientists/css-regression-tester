require "json"
require "selenium-webdriver"
require 'webdriver-user-agent'
require "rspec"
require 'eyes_selenium' 
include RSpec::Expectations

describe "Rately Xpath Test Suite" do

  before(:all) do

    @driver = Webdriver::UserAgent.driver(
      browser: :chrome, 
      # agent: :iphone, 
      # orientation: :landscape
    )

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
  
  it "tests the xpath rules" do

    @driver.get("http://m.macys.com/shop/product/waring-wmk600-double-belgian-waffle-maker?ID=462232")

    @driver.execute_script(%|
      script = document.createElement('script')
      script.src = window.location.protocol + "//rately.com/api/products/" + window.location.host.replace(/^www\./,'') + "/tracker.js"
      document.head.appendChild(script)
    |)

    sleep 2

    data = JSON.parse(@driver.execute_script("return JSBridge_JSON"))
    product = data["product"]

    expect(product["title"]).not_to be_empty
    expect(product["image_url"]).not_to be_empty

  end
  
end
