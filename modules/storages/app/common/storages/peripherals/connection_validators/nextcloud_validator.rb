# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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

module Storages
  module Peripherals
    module ConnectionValidators
      class NextcloudValidator
        # Class Level interface will be moved to a superclass/mixin once we do the OneDrive port
        class << self
          def validation_groups
            @validation_groups ||= {}
          end

          def register_group(group_name, klass, when: ->(*) { true })
            validation_groups[group_name] = { klass:, when: }
          end
        end

        register_group :base_configuration, Nextcloud::StorageConfigurationValidator
        register_group :authentication, Nextcloud::AuthenticationValidator,
                       when: ->(_, result) { result.group(:base_configuration).non_failure? }
        register_group :ampf_configuration, Nextcloud::AmpfConfigurationValidator,
                       when: ->(storage, result) {
                         result.group(:base_configuration).non_failure? && storage.automatic_management_enabled?
                       }

        def initialize(storage:)
          @storage = storage
        end

        def validate
          validation_groups.each_with_object(ValidatorResult.new) do |(key, group_metadata), result|
            if group_metadata[:when].call(@storage, result)
              result.add_group_result(key, group_metadata[:klass].new(@storage).call)
            end
          end
        end

        private

        def validation_groups = self.class.validation_groups
      end
    end
  end
end
