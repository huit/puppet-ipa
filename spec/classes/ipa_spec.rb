require 'spec_helper'

describe 'ipa', :type => :class do

  context 'with master => true' do
    describe "ipa::init" do
      let(:params) { { :master => true  } }
      it { should create_class('ipa::master')}
    end
  end
end
