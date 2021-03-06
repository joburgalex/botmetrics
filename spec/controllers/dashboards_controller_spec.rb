require 'rails_helper'

RSpec.describe DashboardsController do
  let!(:user) { create :user }
  let!(:bot)  { create :bot }
  let!(:bc1)  { create :bot_collaborator, bot: bot, user: user }
  let!(:bi)   { create :bot_instance, uid: 'UNESTOR1', instance_attributes: { team_id: 'TDEADBEEF', team_name: 'My Team', team_url: 'https://my-team.slack.com/' }, state: 'enabled', bot: bot }

  describe 'POST create' do
    def do_request(params = {})
      post :create, bot_id: bot.uid, dashboard: params
    end

    before do
      sign_in user
    end

    it 'should create a new dashboard' do
      expect {
        do_request(name: 'My Custom Dashboard', regex: 'abc')
        bot.reload
      }.to change(bot.dashboards, :count).by(1)

      dashboard = bot.dashboards.last
      expect(dashboard.name).to eql 'My Custom Dashboard'
      expect(dashboard.regex).to eql 'abc'
      expect(dashboard.dashboard_type).to eql 'custom'
      expect(dashboard.enabled).to be true
      expect(dashboard.user).to eql user
    end

    it 'should redirect to bot_dashboards_path' do
      do_request(name: 'My Custom Dashboard', regex: 'abc')
      expect(response).to redirect_to bot_dashboards_path
    end
  end

  describe 'GET index' do
    def do_request
      get :index, bot_id: bot.uid
    end

    before do
      sign_in user
    end

    it 'should render template index' do
      do_request
      expect(response).to render_template :index
    end
  end

  describe 'GET show' do
    let!(:dashboard) { create :dashboard, bot: bot }

    def do_request
      get :show, bot_id: bot.uid, id: dashboard.uid
    end

    before do
      sign_in user
    end

    it 'should render template show' do
      do_request
      expect(response).to render_template :show
    end
  end
end
