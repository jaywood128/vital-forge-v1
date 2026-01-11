class WorkoutMailer < ApplicationMailer
  default from: "noreply@vitalforge.com"

  def weekly_progress(user, stats)
    @user = user
    @stats = stats
    # binding.pry
    mail(
      to: @user.email,
      subject: "VitalForge: Your Weekly Fitness Progress - #{Date.current.strftime('%b %d, %Y')}"
    )
  end
end
