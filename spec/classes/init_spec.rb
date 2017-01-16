require 'spec_helper'
describe 'nubis_grafana' do
  context 'with default values for all parameters' do
    it { should contain_class('nubis_grafana') }
  end
end
