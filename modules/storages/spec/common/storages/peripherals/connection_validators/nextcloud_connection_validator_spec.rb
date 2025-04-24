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

require "spec_helper"
require_module_spec_helper

module Storages
  module Peripherals
    module ConnectionValidators
      RSpec.describe NextcloudValidator, :webmock do
        it "does not run the AMPF tests if the storage is not automatically managed",
           vcr: "nextcloud/capabilities_success" do
          results = described_class.new(storage: create(:nextcloud_storage_with_local_connection)).validate

          expect { results.group(:ampf_configuration) }.to raise_error(KeyError)
        end

        it "aggregates all the results from the tests", vcr: "nextcloud/capabilities_success" do
          results = described_class.new(storage: create(:nextcloud_storage_with_local_connection)).validate

          expect(results).to be_warning
          expect(results.group(:base_configuration)).to be_success
          expect(results.group(:authentication)).to be_warning
        end

        it "does not run any further tests if base configuration failed", vcr: "nextcloud/capabilities_invalid_data" do
          results = described_class.new(storage: create(:nextcloud_storage_with_local_connection)).validate

          expect { results.group(:authentication) }.to raise_error(KeyError)
          expect { results.group(:ampf_configuration) }.to raise_error(KeyError)
        end
      end
    end
  end
end
