class RelaxService
  def self.handle(event)
    case event.type
    when 'team_joined'
      bi = find_bot_instance_from(event)
      return if bi.blank?
      ImportUsersForBotInstanceJob.perform_async(bi.id)
      bi.events.create!(event_type: 'user_added', provider: bi.provider)
    when 'disable_bot'
      bi = find_bot_instance_from(event)
      return if bi.blank?

      if bi.state == 'enabled'
        bi.update_attribute(:state, 'disabled')
        bi.events.create!(event_type: 'bot_disabled', provider: bi.provider)
      end
    when 'message_new'
      bi = find_bot_instance_from(event)
      return if bi.blank?

      user = bi.users.find_by(uid: event.user_uid)
      # if user is blank, then import users and try again before bailing
      if user.blank?
        bi.import_users!
        user = bi.users.find_by(uid: event.user_uid)
        return if user.blank?
      end

      bi.events.create!(
        user: user,
        event_attributes: {
          channel: event.channel_uid,
          timestamp: event.timestamp
        },
        is_for_bot: is_for_bot?(event),
        is_im: event.im,
        provider: bi.provider,
        event_type: 'message'
      )
    end
  end

  private
  def self.is_for_bot?(event)
    event.im || event.text.match(/<?@#{event.relax_bot_uid}[^>]?>?/).present?
  end

  def self.find_bot_instance_from(event)
    BotInstance.where("instance_attributes->>'team_id' = ? AND uid = ?", event.team_uid, event.namespace).first
  end
end