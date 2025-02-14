# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

class Mutations::DiscussionBase < Mutations::BaseMutation
  argument :allow_rating, Boolean, required: false
  argument :delayed_post_at, Types::DateTimeType, required: false
  argument :lock_at, Types::DateTimeType, required: false
  argument :locked, Boolean, required: false
  argument :message, String, required: false
  argument :only_graders_can_rate, Boolean, required: false
  argument :published, Boolean, required: false
  argument :require_initial_post, Boolean, required: false
  argument :title, String, required: false
  argument :todo_date, Types::DateTimeType, required: false
  argument :podcast_enabled, Boolean, required: false
  argument :podcast_has_student_posts, Boolean, required: false

  field :discussion_topic, Types::DiscussionType, null: true

  def process_common_inputs(input, is_announcement, discussion_topic)
    discussion_topic.user = current_user
    discussion_topic.title = input[:title]
    discussion_topic.message = input[:message]
    discussion_topic.workflow_state = (input[:published] || is_announcement) ? "active" : "unpublished"
    discussion_topic.require_initial_post = input[:require_initial_post] || false

    discussion_topic.allow_rating = input[:allow_rating] || false
    discussion_topic.only_graders_can_rate = input[:only_graders_can_rate] || false

    unless is_announcement
      discussion_topic.todo_date = input[:todo_date]
    end

    discussion_topic.podcast_enabled = input[:podcast_enabled] || false
    discussion_topic.podcast_has_student_posts = input[:podcast_has_student_posts] || false
  end

  def process_future_date_inputs(delayed_post_at, lock_at, discussion_topic)
    discussion_topic.delayed_post_at = delayed_post_at if delayed_post_at
    discussion_topic.lock_at = lock_at if lock_at

    if discussion_topic.delayed_post_at_changed? || discussion_topic.lock_at_changed?
      discussion_topic.workflow_state = discussion_topic.should_not_post_yet ? "post_delayed" : discussion_topic.workflow_state
      if discussion_topic.should_lock_yet
        discussion_topic.lock(without_save: true)
      else
        discussion_topic.unlock(without_save: true)
      end
    end
  end

  def process_locked_parameter(locked, discussion_topic)
    return unless locked != discussion_topic.locked? && !discussion_topic.lock_at_changed?

    # TODO: Remove this comment when reused for Create/Update...
    # This makes no sense now but will help in the future when we
    # want to update the locked state of a discussion topic
    if locked
      discussion_topic.lock(without_save: true)
    else
      discussion_topic.lock_at = nil
      discussion_topic.unlock(without_save: true)
    end
  end
end
