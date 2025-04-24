# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe "Work package comments with restricted visibility",
               :js,
               :with_cuprite,
               with_flag: { comments_with_restricted_visibility: true } do
  let(:project) { create(:project) }
  let(:admin) { create(:admin) }
  let(:viewer) { create_user_with_restricted_comments_view_permissions }
  let(:viewer_with_commenting_permission) { create_user_with_restricted_comments_view_and_write_permissions }
  let(:project_admin) { create_user_as_project_admin }

  let(:work_package) { create(:work_package, project:, author: admin) }
  let(:first_comment) do
    create(:work_package_journal, user: admin, notes: "A (restricted) comment by admin",
                                  journable: work_package, version: 2, restricted: true)
  end

  let(:wp_page) { Pages::FullWorkPackage.new(work_package, project) }
  let(:activity_tab) { Components::WorkPackages::Activities.new(work_package) }

  context "with an admin user" do
    current_user { admin }

    before do
      wp_page.visit!
      wp_page.wait_for_activity_tab
    end

    it "allows adding a comment with restricted visibility" do
      activity_tab.expect_input_field

      activity_tab.add_comment(text: "First (restricted) comment by admin", restricted: true)

      activity_tab.expect_journal_notes(text: "First (restricted) comment by admin")
    end
  end

  context "with a user that is only allowed to view comments with restricted visibility" do
    current_user { viewer }

    before do
      first_comment

      wp_page.visit!
      wp_page.wait_for_activity_tab
    end

    it "does show restricted comments but does NOT enable editing or quoting comments" do
      activity_tab.expect_journal_notes(text: "A (restricted) comment by admin")

      activity_tab.within_journal_entry(first_comment) do
        page.find_test_selector("op-wp-journal-#{first_comment.id}-action-menu").click

        expect(page).not_to have_test_selector("op-wp-journal-#{first_comment.id}-edit")
        expect(page).not_to have_test_selector("op-wp-journal-#{first_comment.id}-quote")
      end
    end
  end

  context "with a user that is allowed to view, create and edit own comments" do
    current_user { viewer_with_commenting_permission }

    before do
      first_comment

      wp_page.visit!
      wp_page.wait_for_activity_tab
    end

    it "allows adding a comment with restricted visibility" do
      activity_tab.expect_input_field

      activity_tab.add_comment(text: "First (restricted) comment by member", restricted: true)

      activity_tab.expect_journal_notes(text: "First (restricted) comment by member")

      created_comment = work_package.journals.reload.last

      activity_tab.within_journal_entry(created_comment) do
        page.find_test_selector("op-wp-journal-#{created_comment.id}-action-menu").click
        page.find_test_selector("op-wp-journal-#{created_comment.id}-edit").click

        page.within_test_selector("op-work-package-journal-form-element") do
          expect(page).not_to have_test_selector("op-work-package-journal-restricted-comment-checkbox")
          activity_tab.get_editor_form_field_element.set_value("Edited comment by member")
          page.find_test_selector("op-submit-work-package-journal-form").click
        end

        wait_for { page }.to have_test_selector("op-journal-notes-body", text: "Edited comment by member")
      end
    end

    it "does show restricted comments but does NOT enable editing other users comments" do
      activity_tab.expect_journal_notes(text: "A (restricted) comment by admin")

      activity_tab.within_journal_entry(first_comment) do
        page.find_test_selector("op-wp-journal-#{first_comment.id}-action-menu").click

        # not allowed to edit other user's restricted comments
        expect(page).not_to have_test_selector("op-wp-journal-#{first_comment.id}-edit")
        # allowed to quote other user's comments
        expect(page).to have_test_selector("op-wp-journal-#{first_comment.id}-quote")
      end
    end
  end

  context "with a user that is allowed to view, create and edit all comments" do
    current_user { project_admin }

    let(:unrestricted_comment) do
      create(:work_package_journal,
             user: project_admin, notes: "An unrestricted comment by member",
             journable: work_package, version: (work_package.journals.reload.last.version + 1), restricted: false)
    end

    before do
      first_comment
      unrestricted_comment

      wp_page.visit!
      wp_page.wait_for_activity_tab
    end

    it "allows editing and quoting restricted comments" do
      activity_tab.expect_journal_notes(text: "A (restricted) comment by admin")

      activity_tab.edit_comment(first_comment, text: "A (restricted) comment by admin - EDITED")

      activity_tab.within_journal_entry(first_comment) do
        activity_tab.expect_journal_notes(text: "A (restricted) comment by admin - EDITED")
      end

      activity_tab.quote_comment(first_comment)
      page.within_test_selector("op-work-package-journal-form-element") do
        expect(page).to have_checked_field("Restrict visibility")
      end

      activity_tab.quote_comment(unrestricted_comment)
      page.within_test_selector("op-work-package-journal-form-element") do
        expect(page).to have_checked_field("Restrict visibility")
      end
    end
  end

  def create_user_as_project_admin
    member_role = create(:project_role,
                         permissions: %i[view_work_packages add_work_package_notes
                                         edit_own_work_package_notes
                                         view_comments_with_restricted_visibility
                                         add_comments_with_restricted_visibility
                                         edit_own_comments_with_restricted_visibility
                                         edit_others_comments_with_restricted_visibility])
    create(:user, firstname: "Project", lastname: "Admin",
                  member_with_roles: { project => member_role })
  end

  def create_user_with_restricted_comments_view_permissions
    viewer_role = create(:project_role, permissions: %i[view_work_packages view_comments_with_restricted_visibility])
    create(:user,
           firstname: "A",
           lastname: "Viewer",
           member_with_roles: { project => viewer_role })
  end

  def create_user_with_restricted_comments_view_and_write_permissions
    viewer_role_with_commenting_permission = create(:project_role,
                                                    permissions: %i[view_work_packages add_work_package_notes
                                                                    edit_own_work_package_notes
                                                                    view_comments_with_restricted_visibility
                                                                    add_comments_with_restricted_visibility
                                                                    edit_own_comments_with_restricted_visibility])
    create(:user,
           firstname: "A",
           lastname: "Viewer",
           member_with_roles: { project => viewer_role_with_commenting_permission })
  end
end
