require 'spec_helper'

describe 'ipa', :type => :class do

  context 'with master => true' do
    describe "ipa::init" do
      let(:params) { { :master => true, :cleanup => false  } }
      it { should create_class('ipa::master') }
      it { should contain_package('ipa') }
    end
  end
end
