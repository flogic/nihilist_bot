require 'net/http'

# An Autumn Leaf used for an in-channel scorekeeping system. This is an open
# scorekeeping system: New members are added once they receive points for the
# first time, and anyone can add or remove points from anyone except themselves.
# There is no administrative functionality.
#
# *Usage*
#
# !points [name]:: Get a person's score
# !points [name] [+|-][number]:: Change a person's score (you must have a "+" or
#                                a "-")
class Scorekeeper < AutumnLeaf
  # Message displayed for !about command.
  ABOUT_MESSAGE = "Scorekeeper version 1.0.1 (9-19-07) by Tim Morgan: An Autumn Leaf."
  # Messages displayed on startup.
  STARTUP_MESSAGE = {
    :fresh => %{Scorekeeper started without previous points information; everyone's points reset to zero. Command is "!points".},
    :reload => %{Scorekeeper started; points loaded from file. Command is "!points".}
  }
  # Message displayed when a user uses incorrect !points syntax.
  USAGE = "Example: \"!points Sancho +5\" to add 5 points to Sancho's score."

  # Displays the greeting and current scores.
  def did_start_up
    message STARTUP_MESSAGE[@status]
    message totals
  end

  # Displays the current point totals, or modifies someone's score, depending on
  # the message provided with the command.
  def points_command(sender, channel, msg)
    if msg.nil? or msg.empty? then
      message totals, channel
    elsif msg =~ /^(.+\s+[\+\-]\d+)/ then
      result = point_change_message sender, $1
      if result then message result, channel end
    else
      message USAGE, channel
    end
  end

  # Displays the about message.
  def about_command(sender, channel, msg)
    message ABOUT_MESSAGE, channel
  end

  private

  def announce_change(sender, victim, amount)
    points = if amount == 1 or amount == -1 then 'point' else 'points' end
    if amount > 0 then
      message "#{sender} gave #{victim} #{amount} #{points}."
    else
      message "#{sender} docked #{victim} #{-amount} #{points}."
    end
  end

  def totals
    if data.size > 0 then
      data.sort { |a,b| b[1] <=> a[1] }.collect { |n,p| "#{n}: #{p}" }.join(', ')
    else
      "No one has any points yet."
    end
  end

  def change_points(victim, amount)
    data[victim] = 0 unless data[victim]
    record(victim => data[victim] + amount)
  end

  def authorized?(sender, victim)
    if victim == sender.downcase.capitalize then
      return "You can't change your own points."
    end
    return true
  end

  def point_change_message(sender, msg)
    return USAGE unless msg
    words = msg.split /\s+/
    if words.length == 2 then
      victim = words[0].downcase.capitalize
      begin
        amount = Integer(words[1])
      rescue
        return USAGE
      end
      message = authorized? sender.downcase.capitalize, victim
      if message == true then
        change_points victim, amount
        announce_change sender, victim, amount
      else
        return message
      end
    else
      return USAGE
    end
    return nil
  end
end
