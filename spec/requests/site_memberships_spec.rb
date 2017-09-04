describe SiteMembershipsController do
  let!(:user) { create :user }
  let!(:invitee) { create :user }
  let!(:site) { create :site, user: user }

  context 'when unauthenticated' do
    describe 'GET #index' do
      it 'responds with a redirect to the login page' do
        post site_site_memberships_path(site)

        expect(response).to redirect_to new_user_session_path
      end
    end
  end

  context 'when authenticated' do
    before do
      login_as user, scope: :user, run_callbacks: false
    end

    describe 'POST #create' do
      let(:params) do
        {
          role: 'admin',
          user_id: invitee.id,
          site_id: site.id
        }
      end

      it 'responds with json' do
        post site_site_memberships_path(site), site_membership: params
        expect(json).not_to be_empty
      end

      it 'sends email' do
        expect(TeamMailer)
          .to receive(:invite)
          .with(an_instance_of(SiteMembership))
          .and_return double(deliver_later: true)

        post site_site_memberships_path(site), site_membership: params
      end

      context 'with invalid params' do
        it 'responds with status: :unprocessable_entity' do
          post site_site_memberships_path(site), site_membership: params.update(role: nil)
          expect(response).not_to be_success
          expect(response.status).to eql 422
        end
      end
    end

    describe 'PUT #update' do
      let(:params) do
        {
          role: 'admin',
          user_id: invitee.id,
          site_id: site.id
        }
      end
      let(:site_membership) { create :site_membership, site: site }

      it 'responds with json' do
        put site_site_membership_path(site, site_membership), site_membership: params
        expect(json).not_to be_empty
      end

      context 'with invalid params' do
        it 'responds with status: :unprocessable_entity' do
          put site_site_membership_path(site, site_membership), site_membership: params.update(role: nil)
          expect(response).not_to be_success
          expect(response.status).to eql 422
        end
      end
    end

    describe 'DELETE #destroy' do
      let!(:site_membership) { create :site_membership, site: site, role: 'admin' }

      it 'responds with json' do
        delete site_site_membership_path(site, site_membership)
        expect(json).not_to be_empty
      end

      it 'destroys membership' do
        expect { delete site_site_membership_path(site, site_membership) }
          .to change { SiteMembership.count }.by(-1)
      end

      context 'when membership of current user' do
        it 'responds with status: :unprocessable_entity' do
          delete site_site_membership_path(site, user.site_memberships.first)

          expect(response).not_to be_success
          expect(response.status).to eql 422

          expect(json[:site_memberships])
            .to match_array ['Can\'t remove permissions from yourself.']
        end
      end

      context 'when cannot be destroyed' do
        let!(:site_membership) { create :site_membership, role: 'owner' }

        before do
          create :site_membership, user: user, site: site_membership.site, role: 'admin'
        end

        it 'responds with status: :unprocessable_entity' do
          delete site_site_membership_path(site_membership.site, site_membership)

          expect(response).not_to be_success
          expect(response.status).to eql 422

          expect(json[:site_memberships])
            .to match_array ['Site must have at least one owner']
        end
      end
    end

    describe 'PUT #invite' do
      let(:email) { 'email@example.com' }

      it 'redirects to site_team_path' do
        post invite_site_site_memberships_path(site), email: email

        expect(response).to redirect_to site_team_path(site)
      end

      context 'when user already has a membership to the site' do
        before { create :user, email: email, site: site }

        it 'redirects to site_team_path with a notice' do
          post invite_site_site_memberships_path(site), email: email

          expect(response).not_to be_success
          expect(response.status).to eql 302
          expect(flash[:notice])
            .to eql "User already has a membership to #{ site.url }"
        end
      end

      context 'with invalid params' do
        it 'redirects to site_team_path with a notice' do
          post invite_site_site_memberships_path(site), email: ''

          expect(response).not_to be_success
          expect(response.status).to eql 302
          expect(flash[:notice]).not_to be_blank
        end
      end
    end
  end
end
