require 'spec_helper'

describe GroupMembersController do
  describe 'GET #new' do
    let(:group) { create(:group) }

    it 'finds the correct group' do
      get :new, group: group

      expect(assigns(:group)).to eq(group)
    end

    it 'makes a new record' do
      get :new, group: group

      expect(assigns(:group_member)).to be_new_record
    end

    it 'includes the group as an attribute of the new record' do
      get :new, group: group
      expect(assigns(:group_member).group).to eq(group)
    end

    it 'renders the new template' do
      get :new, group: group

      expect(response).to render_template('new')
    end
  end

  describe 'POST #make_group_admin' do
    let(:group_member) { create(:group_member) }
    let(:group) { group_member.group }
    let(:group_members) { group_member.group.group_members }
    let(:group_members_query_result) { group_member.group.group_members.where(user_id: user.id, admin: true) }

    let(:user) { create(:user) }

    before do
      allow(controller).to receive(:current_user).and_return(user)

      allow(GroupMember).to receive(:find).and_return(group_member)
      allow(group_member).to receive(:group).and_return(group)
      allow(group).to receive(:group_members).and_return(group_members)
    end

    it 'checks whether the current user is an admin member of the group' do
      allow(group_members).to receive(:where).with(user_id: user.id, admin: true).and_return(group_members_query_result)

      expect(group_members_query_result).to receive(:present?)
      post :make_admin, id: group_member
    end

    context 'when the current user is an admin member of the group' do
      before do
        allow(controller).to receive(:current_user_admin?).and_return(true)
      end

      it 'finds the correct group member' do
        post :make_admin, id: group_member
        expect(assigns(:group_member)).to eq(group_member)
      end

      it 'makes the group member an admin' do
        expect(group_member.admin?).to eq(false)

        post :make_admin, id: group_member

        group_member.reload
        expect(group_member.admin?).to eq(true)
      end

      it 'shows a success message' do
        post :make_admin, id: group_member

        expect(flash[:notice]).to include('Member has successfully been made an admin!')
      end
    end

    context 'when the current user is not an admin member of the group' do
      before do
        allow(controller).to receive(:current_user_admin?).and_return(false)
      end

      it 'does not make the group member an admin' do
        expect(group_member.admin?).to eq(false)

        post :make_admin, id: group_member

        group_member.reload
        expect(group_member.admin?).to eq(false)
      end

      it 'shows an error message' do
        post :make_admin, id: group_member

        expect(flash[:error]).to include('You must be an admin member of the group to do that.')
      end
    end

    it 'redirects to the group#show page' do
      post :make_admin, id: group_member
      expect(response).to redirect_to(group_path(group_member.group))
    end
  end

  describe 'POST #create' do
    let(:group) { create(:group) }
    let(:user) { create(:user) }

    context 'with valid input' do
      let(:input) do
        { group_id: group.id, user_id: user.id }
      end

      it 'saves the new group member to the database' do
        expect { post :create, group_member: input }.to change(GroupMember, :count).by(1)
      end

      context 'after the save' do
        let(:group_member) do
          create(:group_member, user: user, group: group)
        end

        before do
          allow(GroupMember).to receive(:new).and_return(group_member)
          allow(group_member).to receive(:save).and_return(true)
        end

        it 'shows a success message' do
          post :create, group_member: input
          expect(flash[:notice]).to include('Member successfully added!')
        end

        it 'redirects to the group show template' do
          post :create, group_member: input
          expect(response).to redirect_to(group_path(group))
        end
      end
    end

    context 'with invalid input' do
      let(:invalid_input) do
        { group_id: group.id, user_id: nil }
      end

      it 'does not save the group to the database' do
        expect { post :create, group_member: invalid_input }.to change(GroupMember, :count).by(0)
      end

      context 'after the save' do
        let(:group_member) do
          build(:group_member, user: user, group: group)
        end

        before do
          allow(GroupMember).to receive(:new).and_return(group_member)
          allow(group_member).to receive(:save).and_return(false)
        end

        it 'shows an error' do
          post :create, group_member: invalid_input
          expect(flash[:warning]).to include('An error has occurred')
        end

        it 'redirects to the new member template' do
          post :create, group_member: invalid_input
          expect(response).to redirect_to(new_group_member_path)
        end
      end
    end
  end

  describe 'DELETE #destroy' do
    let(:group) { create(:group) }
    let(:user) { create(:user) }

    let!(:group_member) do
      create(:group_member, user: user, group: group)
    end

    it 'finds the correct group member' do
      delete :destroy, id: group_member.id
      expect(assigns(:group_member)).to eq(group_member)
    end

    context 'when the destroy is successful' do
      let(:other_user) { create(:user) }

      let!(:other_group_member) do
        create(:group_member, user: other_user, group:group)
      end

      before do
        expect(group.group_members).to include(other_group_member)
      end

      it 'removes the member from the GroupMember' do
        expect { delete :destroy, id: group_member.id }.to change(GroupMember, :count).by(-1)
      end

      it 'shows a success message' do
        delete :destroy, id: group_member.id
        expect(flash[:notice]).to include('Member successfully removed')
      end

      it 'redirects to the group index page' do
        delete :destroy, id: group_member.id
        expect(response).to redirect_to(group_path(group.id))
      end

      it 'does not remove other members' do
        delete :destroy, id: group_member.id
        expect(group.group_members).to include(other_group_member)
      end
    end

    context 'when the destroy is not successful' do
      before do
        allow(GroupMember).to receive(:find).and_return(group_member)
        allow(group_member).to receive(:destroy).and_return(false)
      end

      it 'shows a warning message' do
        delete :destroy, id: group_member.id
        expect(flash[:warning]).to include('An error has occurred')
      end

      it 'redirects to the group index page' do
        delete :destroy, id: group_member.id
        expect(response).to redirect_to(group_path(group.id))
      end
    end
  end
end