/*
 * -- copyright
 * OpenProject is an open source project management software.
 * Copyright (C) 2023 the OpenProject GmbH
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License version 3.
 *
 * OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
 * Copyright (C) 2006-2013 Jean-Philippe Lang
 * Copyright (C) 2010-2013 the ChiliProject Team
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 *
 * See COPYRIGHT and LICENSE files for more details.
 * ++
 */

import { Controller } from '@hotwired/stimulus';
import type IndexController from './index.controller';

export default class RestrictedCommentController extends Controller {
  static targets = ['restrictedCheckbox', 'formContainer', 'learnMoreLink'];
  static outlets = ['work-packages--activities-tab--index'];
  static classes = ['highlight', 'hidden'];

  declare readonly restrictedCheckboxTarget:HTMLInputElement;
  declare readonly formContainerTarget:HTMLElement;
  declare readonly learnMoreLinkTarget:HTMLAnchorElement;
  declare readonly workPackagesActivitiesTabIndexOutlet:IndexController;

  declare readonly highlightClass:string;
  declare readonly hiddenClass:string;

  onSubmitEnd(_event:CustomEvent):void {
    this.toggleBackgroundColor();
  }

  toggleBackgroundColor():void {
    const isChecked = this.restrictedCheckboxTarget.checked;

    this.formContainerTarget.classList.toggle(this.highlightClass, isChecked);
    this.toggleLearnMoreLink(isChecked);
  }

  private toggleLearnMoreLink(isChecked:boolean):void {
    if (this.workPackagesActivitiesTabIndexOutlet.isMobile()) return; // hidden on mobile

    this.learnMoreLinkTarget.classList.toggle(this.hiddenClass, !isChecked);
  }
}
