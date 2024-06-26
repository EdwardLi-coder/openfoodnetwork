# frozen_string_literal: true

require 'spec_helper'
require 'rake'

RSpec.describe 'enterprises.rake' do
  before(:all) do
    Rake.application.rake_require("tasks/enterprises")
    Rake::Task.define_task(:environment)
  end

  describe ':remove_enterprise' do
    context 'when the enterprises exists' do
      it 'removes the enterprise' do
        enterprise = create(:enterprise)

        expect {
          Rake.application.invoke_task "ofn:remove_enterprise[#{enterprise.id}]"
        }.to change { Enterprise.count }.by(-1)
      end
    end
  end
end
