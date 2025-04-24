# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2010-2024 the OpenProject GmbH
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
# ++

module Projects
  module Settings
    module LifeCycleSteps
      class StepComponent < ApplicationComponent
        include ApplicationHelper
        include OpPrimer::ComponentHelpers
        include OpTurbo::Streamable

        options :definition,
                :active?

        # TODO: Remove these helper methods once the Projects::LifeCycleComponent
        # has been refactored.
        def icon
          :"op-phase"
        end

        def icon_color_class
          helpers.hl_inline_class("project_phase_definition", definition)
        end

        def gate_info
          if definition.start_gate? && definition.finish_gate?
            I18n.t("settings.project_phase_definitions.both_gate")
          elsif definition.start_gate?
            I18n.t("settings.project_phase_definitions.start_gate")
          elsif definition.finish_gate?
            I18n.t("settings.project_phase_definitions.finish_gate")
          else
            I18n.t("settings.project_phase_definitions.no_gate")
          end
        end

        def gate_text_options
          { color: :muted, font_size: :small }.merge(options)
        end

        def toggle_aria_label
          I18n.t("projects.settings.life_cycle.step.use_in_project", step: definition.name)
        end
      end
    end
  end
end
