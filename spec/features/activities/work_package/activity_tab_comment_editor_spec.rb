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

RSpec.describe "Work package activity tab comment editor",
               :js,
               :with_cuprite,
               with_flag: { comments_with_restricted_visibility: true } do
  let(:project) { create(:project) }
  let(:admin) { create(:admin) }
  let(:work_package) { create(:work_package, project:, author: admin) }

  let(:wp_page) { Pages::FullWorkPackage.new(work_package, project) }
  let(:activity_tab) { Components::WorkPackages::Activities.new(work_package) }

  describe "Dismiss strategy" do
    current_user { admin }

    before do
      wp_page.visit!
      wp_page.wait_for_activity_tab
    end

    context "when editor content is empty" do
      it "is dismissable via keyboard Esc" do
        expect_editor_to_be_dismissed do
          activity_tab.dismiss_comment_editor_with_esc
        end
      end

      it "is dismissable via Cancel button" do
        expect_editor_to_be_dismissed do
          activity_tab.dismiss_comment_editor_with_cancel_button
        end
      end

      def expect_editor_to_be_dismissed
        activity_tab.add_comment(text: "Sample text", save: false)
        activity_tab.clear_comment

        activity_tab.expect_focus_on_editor
        yield

        expect(page).not_to have_test_selector("op-work-package-journal-form-element")
      end
    end

    context "when editor has content" do
      context "and the user confirms the dismissal" do
        it "requires confirmation to dismiss via keyboard Esc" do
          expect_editor_to_be_dismissed_with_confirmation do
            activity_tab.dismiss_comment_editor_with_esc
          end
        end

        it "requires confirmation to dismiss via Cancel button" do
          expect_editor_to_be_dismissed_with_confirmation do
            activity_tab.dismiss_comment_editor_with_cancel_button
          end
        end

        def expect_editor_to_be_dismissed_with_confirmation(&)
          activity_tab.add_comment(text: "Sample text", save: false)

          activity_tab.expect_focus_on_editor

          accept_alert(&)

          expect(page).not_to have_test_selector("op-work-package-journal-form-element")
        end
      end

      context "and the user cancels the dismissal" do
        it "does not dismiss the editor" do
          activity_tab.add_comment(text: "Sample text", save: false)

          activity_tab.expect_focus_on_editor

          dismiss_confirm do
            activity_tab.dismiss_comment_editor_with_esc
          end

          activity_tab.expect_focus_on_editor

          page.within_test_selector("op-work-package-journal-form-element") do
            editor = activity_tab.get_editor_form_field_element
            expect(editor.input_element.text).to eq("Sample text")
          end
        end
      end
    end
  end
end
