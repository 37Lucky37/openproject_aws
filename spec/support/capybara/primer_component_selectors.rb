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

Capybara.add_selector :primer_label, locator_type: [String, Symbol] do
  label "Primer Label"

  css do |*|
    ".Label"
  end

  locator_filter skip_if: nil do |node, locator, exact:, **|
    text = if node[:"aria-labelledby"]
             CapybaraAccessibleSelectors::Helpers.element_labelledby(node)
           elsif node[:"aria-label"]
             node[:"aria-label"]
           else
             node.text
           end
    text.public_send(exact ? :eql? : :include?, locator.to_s)
  end

  expression_filter :scheme do |expr, scheme|
    builder(expr).add_attribute_conditions(class: "Label--#{scheme.downcase}")
  end

  describe_expression_filters do |scheme: nil, **|
    " with scheme #{scheme.inspect}" if scheme
  end
end

module Capybara
  module RSpecMatchers
    def have_primer_label(locator = nil, **, &)
      Matchers::HaveSelector.new(:primer_label, locator, **, &)
    end

    def have_no_primer_label(...)
      Matchers::NegatedMatcher.new(have_primer_label(...))
    end
  end
end
