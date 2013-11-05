require 'spec_helper'
require 'tempfile'
require 'mail'

describe "Integrations" do
  before { pending "Skipping integration tests" }

  def parse_html_in_email(mail)
    Nokogiri::HTML.parse mail.html_part.body.decoded
  end


  [
    RailsApp.new("Rails 3.0.x", 'rails_30'),
    RailsApp.new("Rails 3.1.x", 'rails_31'),
    RailsApp.new("Rails 3.2.x", 'rails_32'),
    RailsApp.new("Rails 4.0.x", 'rails_40', runner: :bin),
    RailsApp.new("Rails 4.0.x (without asset pipeline)", 'rails_40_no_pipeline', runner: :bin),
    RailsApp.new("Rails 4.0.x (precompiled)", 'rails_40_precompiled', runner: :bin),
  ].each do |app|
    describe "with #{app}" do
      before { app.reset }

      it "inlines styles for multipart emails" do
        email = app.read_email(:normal_email)

        email.to.should == ['example@example.org']
        email.from.should == ['john@example.com']
        email.should have(2).parts

        email.text_part.body.decoded.should_not match(/<.*>/)

        html = email.html_part.body.decoded
        html.should include '<!DOCTYPE'
        html.should include '<head'

        document = parse_html_in_email(email)
        document.should have_selector('body h1')
        document.should have_styling('background' => 'url(https://example.app.org/images/rails.png)').at_selector('.image')

        # If we deliver mails we can catch weird problems with headers being invalid
        email.delivery_method :test
        email.deliver
      end

      it "does not add headers for the roadie options and keeps custom headers in place" do
        email = app.read_email(:extra_email)
        header_names = email.header.fields.map(&:name)
        header_names.should_not include('css')
        header_names.should include('X-Spam')
      end

      it "only removes the css option when disabled" do
        app.before_mail %(
          Rails.application.config.roadie.enabled = false
        )

        email = app.read_email(:normal_email)

        email.header.fields.map(&:name).should_not include('css')

        email.to.should == ['example@example.org']
        email.from.should == ['john@example.com']
        email.should have(2).parts

        document = parse_html_in_email(email)
        document.should have_selector('body h1')
        document.should_not have_styling('background' => 'url(https://example.app.org/images/rails.png)').at_selector('.image')
      end
    end
  end

  describe "with precompiled assets" do
    let(:app) {
      RailsApp.new("Rails 4.0.x (precompiled)", 'rails_40_precompiled', runner: :bin)
    }

    let(:document) do
      parse_html_in_email app.read_email(:normal_email)
    end

    it "inlines the precompiled stylesheet" do
      pending
      # Precompiled version has green color; the file in app/assets have red
      document.should have_styling('background-color' => 'green').at_selector('body')
    end

    it "inlines images with digests" do
      pending
      image_url = "https://example.app.org/images/rails-231a680f23887d9dd70710ea5efd3c62.png"
      document.should have_styling('background' => "url(#{image_url})").at_selector('.image')
    end
  end
end
