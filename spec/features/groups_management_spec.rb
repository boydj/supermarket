require 'spec_feature_helper'

feature 'groups management' do
  let(:user) { create(:user) }

  before do
    sign_in(user)
  end

  describe 'user visits their profile page' do
    it 'shows the Groups link' do
      visit user_path(user)
      expect(page).to have_link('Groups')
    end
  end

  describe 'user clicks the Groups link' do
    before do
      visit user_path(user)
      click_link('Groups')
    end

    it 'shows the Your Groups header' do
      expect(page).to have_content("#{user.name}'s Groups")
    end

    it 'shows the Create Group link' do
      expect(page).to have_link('Create Group')
    end

    describe 'user clicks the Create Group link' do
      before do
        click_link('Create Group')
      end

      it 'shows the new group form' do
        expect(page).to have_field('Group Name')
      end

      it 'shows a Create Group link' do
        expect(page).to have_button('Create Group')
      end

      context 'when the create is not successful' do
        it 'shows an error message'

        it 'shows the new group form'
      end

      context 'when the create is successful' do
        before do
          fill_in('Group Name', with: 'My Group')
          click_button('Create Group')
        end

        it 'shows a success message' do
          expect(page).to have_content('Group successfully created!')
        end

        it 'shows the group' do
          expect(page).to have_content('My Group')
        end
      end
    end
  end
end
