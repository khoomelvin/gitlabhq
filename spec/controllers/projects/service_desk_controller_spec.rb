require 'spec_helper'

describe Projects::ServiceDeskController do
  let(:project) { create(:project_empty_repo, :private) }
  let(:user)    { create(:user) }

  before do
    project.add_master(user)
    sign_in(user)
    allow_any_instance_of(License).to receive(:add_on?).and_call_original
    allow_any_instance_of(License).to receive(:add_on?).with('GitLab_ServiceDesk') { true }
  end

  describe 'GET service desk properties' do
    it 'returns service_desk JSON data' do
      project.update(service_desk_enabled: true)

      get :show, namespace_id: project.namespace.to_param, project_id: project, format: :json

      body = JSON.parse(response.body)
      expect(body["service_desk_address"]).to match(/\A[^@]+@[^@]+\z/)
      expect(body["service_desk_enabled"]).to be_truthy
      expect(response.status).to eq(200)
    end
  end

  describe 'PUT service desk properties' do
    it 'toggles services desk incoming email' do
      project.update(service_desk_enabled: true)
      old_address = project.service_desk_address
      project.update(service_desk_enabled: false)

      put :update, namespace_id: project.namespace.to_param, project_id: project, service_desk_enabled: true, format: :json

      body = JSON.parse(response.body)
      expect(body["service_desk_address"]).to be_present
      expect(body["service_desk_address"]).not_to eq(old_address)
      expect(body["service_desk_enabled"]).to be_truthy
      expect(response.status).to eq(200)
    end
  end
end
