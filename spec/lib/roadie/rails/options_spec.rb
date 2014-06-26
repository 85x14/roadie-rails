# encoding: UTF-8
require 'spec_helper'

module Roadie
  module Rails
    describe Options do
      it "raises errors when constructed with unknown options" do
        expect {
          Options.new(unknown_option: "maybe a misspelling?")
        }.to raise_error(ArgumentError, /unknown_option/)
      end

      shared_examples_for "attribute" do |name|
        describe name do
          it "defaults to nil" do
            expect(Options.new.send(name)).to be_nil
          end

          it "can be set in the constructor" do
            expect(Options.new(name => valid_value).send(name)).to eq(valid_value)
          end

          it "can be changed using setter" do
            options = Options.new
            options.send :"#{name}=", valid_value
            expect(options.send(name)).to eq(valid_value)
          end

          it "can be applied to documents" do
            fake_document = OpenStruct.new
            options = Options.new(name => valid_value)
            options.apply_to(fake_document)
            expect(fake_document.send(name)).to eq(valid_value)
          end

          describe "merging" do
            it "replaces values" do
              options = Options.new(name => valid_value)
              expect(options.merge(name => other_valid_value).send(name)).to eq(other_valid_value)
            end

            it "does not mutate instance" do
              options = Options.new(name => valid_value)
              options.merge(name => other_valid_value)
              expect(options.send(name)).to eq(valid_value)
            end
          end

          describe "destructive merging" do
            it "replaces values" do
              options = Options.new(name => valid_value)
              expect(options.merge(name => other_valid_value).send(name)).to eq(other_valid_value)
            end
          end

          describe "combining" do
            it "combines the old and the new value" do
              options = Options.new(name => valid_value)
              combined = options.combine(name => other_valid_value)
              expect_combinated_value combined.send(name)
            end

            it "does not mutate instance" do
              options = Options.new(name => valid_value)
              options.combine(name => other_valid_value)
              expect(options.send(name)).to eq(valid_value)
            end
          end

          describe "destructive combining" do
            it "combines the old and the new value in the instance" do
              options = Options.new(name => valid_value)
              options.combine!(name => other_valid_value)
              expect_combinated_value options.send(name)
            end
          end
        end
      end

      it_behaves_like "attribute", :url_options do
        let(:valid_value) { {host: "foo.com", port: 3000} }
        let(:other_valid_value) { {host: "bar.com", scheme: "https"} }

        def expect_combinated_value(value)
          expect(value).to eq({host: "bar.com", port: 3000, scheme: "https"})
        end
      end

      it_behaves_like "attribute", :before_transformation do
        let(:valid_value) { Proc.new { } }
        let(:other_valid_value) { Proc.new { } }

        def expect_combinated_value(value)
          expect(valid_value).to receive(:call).ordered.and_return 1
          expect(other_valid_value).to receive(:call).ordered.and_return 2

          expect(value.call).to eq(2)
        end
      end

      it_behaves_like "attribute", :after_transformation do
        let(:valid_value) { Proc.new { } }
        let(:other_valid_value) { Proc.new { } }

        def expect_combinated_value(value)
          expect(valid_value).to receive(:call).ordered.and_return 1
          expect(other_valid_value).to receive(:call).ordered.and_return 2
          expect(value.call).to eq(2)
        end
      end

      it_behaves_like "attribute", :asset_providers do
        let(:provider1) { double "Asset provider 1" }
        let(:provider2) { double "Asset provider 2" }

        let(:valid_value) { ProviderList.new([provider1]) }
        let(:other_valid_value) { ProviderList.new([provider2]) }

        def expect_combinated_value(value)
          expect(value).to be_instance_of(ProviderList)
          expect(value.to_a).to eq([provider1, provider2])
        end
      end

      describe "asset_providers" do
        it "automatically wraps values in a ProviderList" do
          provider = double "Asset provider"
          options = Options.new(asset_providers: [provider])
          expect(options.asset_providers).to be_instance_of(ProviderList)
          expect(options.asset_providers.to_a).to eq([provider])
        end
      end
    end
  end
end
